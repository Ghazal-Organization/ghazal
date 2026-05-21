-- =============================================================================
-- Ghazal — Cloud DB Schema (Neon PostgreSQL 16)
-- Conventions: see docs/db/README.md
-- =============================================================================

-- Extensions ------------------------------------------------------------------
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "citext";     -- case-insensitive text (email)
create extension if not exists "pg_trgm";    -- fuzzy search on menu names

-- Enums -----------------------------------------------------------------------
create type order_channel       as enum ('takeaway', 'delivery');
create type order_status        as enum (
    'draft', 'pending', 'placed', 'accepted', 'rejected',
    'preparing', 'ready', 'out_for_delivery',
    'completed', 'cancelled_by_customer', 'cancelled_by_branch',
    'expired', 'failed'
);
create type payment_method      as enum ('card', 'wallet', 'cod');
create type payment_status      as enum (
    'none', 'authorizing', 'authorized', 'captured',
    'failed', 'refund_pending', 'partially_refunded', 'refunded',
    'cod_pending', 'cod_collected', 'cod_failed'
);
create type actor_type          as enum ('customer', 'staff', 'system', 'agent', 'gateway');
create type staff_role          as enum ('owner', 'manager', 'cashier', 'kitchen');
create type sync_outbox_status  as enum ('pending', 'sent', 'acked', 'failed');
create type sync_inbox_status   as enum ('pending', 'processing', 'processed', 'failed');
create type notification_channel as enum ('sms', 'whatsapp', 'email', 'push');
create type notification_status as enum ('queued', 'sending', 'sent', 'delivered', 'failed');

-- =============================================================================
-- 1. CORE
-- =============================================================================

create table branches (
    id              uuid primary key default gen_random_uuid(),
    code            text not null unique,                  -- e.g. 'BR01'
    name_ar         text not null,
    name_en         text not null,
    address_line    text not null,
    city            text not null,
    phone           text not null,                          -- branch contact phone
    timezone        text not null default 'Africa/Cairo',
    is_active       boolean not null default true,
    opens_at        time not null default '10:00',
    closes_at       time not null default '02:00',          -- next day if < opens_at
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

create table branch_settings (
    branch_id                       uuid primary key references branches(id) on delete cascade,
    online_ordering_enabled         boolean not null default true,
    auto_accept_timeout_seconds     int     not null default 300,    -- ADR-019
    pending_payment_timeout_seconds int     not null default 600,
    pickup_ready_expiry_seconds     int     not null default 3600,
    default_prep_time_minutes       int     not null default 25,
    default_delivery_fee            numeric(12,2) not null default 0,
    service_charge_percent          numeric(5,2)  not null default 0,
    vat_percent                     numeric(5,2)  not null default 14,
    track_out_for_delivery          boolean not null default true,   -- ADR-032: optional OUT_FOR_DELIVERY status
    updated_at                      timestamptz not null default now()
);

-- Staff (admin, manager, cashier, kitchen)
create table staff_users (
    id              uuid primary key default gen_random_uuid(),
    email           citext not null unique,
    password_hash   text not null,
    full_name       text not null,
    phone           text,
    is_active       boolean not null default true,
    last_login_at   timestamptz,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

create table staff_branch_roles (
    staff_user_id   uuid not null references staff_users(id) on delete cascade,
    branch_id       uuid not null references branches(id) on delete cascade,
    role            staff_role not null,
    created_at      timestamptz not null default now(),
    primary key (staff_user_id, branch_id, role)
);

-- Customers (ordering app users)
create table customers (
    id              uuid primary key default gen_random_uuid(),
    phone           text not null unique,                     -- E.164
    name            text,
    email           citext,
    preferred_lang  text not null default 'ar' check (preferred_lang in ('ar','en')),
    is_blocked      boolean not null default false,
    blocked_reason  text,
    first_seen_at   timestamptz not null default now(),
    last_order_at   timestamptz,
    total_orders    int not null default 0,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

create table addresses (
    id              uuid primary key default gen_random_uuid(),
    customer_id     uuid not null references customers(id) on delete cascade,
    label           text,                                     -- 'Home', 'Work'
    line1           text not null,
    line2           text,
    city            text not null,
    governorate     text,
    landmark        text,
    lat             numeric(9,6),
    lng             numeric(9,6),
    is_default      boolean not null default false,
    notes           text,
    created_at      timestamptz not null default now(),
    deleted_at      timestamptz
);
create index ix_addresses_customer on addresses(customer_id) where deleted_at is null;

-- =============================================================================
-- 2. AUTH
-- =============================================================================

create table otp_codes (
    id              uuid primary key default gen_random_uuid(),
    phone           text not null,
    code_hash       text not null,                            -- never store plain
    purpose         text not null,                            -- 'login', 'verify_phone'
    expires_at      timestamptz not null,
    consumed_at     timestamptz,
    attempts        int not null default 0,
    requested_ip    inet,
    created_at      timestamptz not null default now()
);
create index ix_otp_codes_phone_active on otp_codes(phone) where consumed_at is null;

create table refresh_tokens (
    id              uuid primary key default gen_random_uuid(),
    subject_type    text not null check (subject_type in ('customer','staff','rider')),
    subject_id      uuid not null,
    token_hash      text not null unique,
    user_agent      text,
    ip              inet,
    issued_at       timestamptz not null default now(),
    expires_at      timestamptz not null,
    revoked_at      timestamptz,
    replaced_by     uuid references refresh_tokens(id)
);
create index ix_refresh_tokens_subject on refresh_tokens(subject_type, subject_id) where revoked_at is null;

-- =============================================================================
-- 3. MENU  (POS = source of truth for items/prices; cloud owns presentation)
-- =============================================================================

create table categories (
    id              uuid primary key default gen_random_uuid(),
    branch_id       uuid not null references branches(id) on delete cascade,
    pos_external_id text,                                     -- nullable: cloud-only categories ok
    name_ar         text not null,
    name_en         text not null,
    sort_order      int not null default 0,
    is_active       boolean not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz,
    unique (branch_id, pos_external_id)
);

create table menu_items (
    id                  uuid primary key default gen_random_uuid(),
    branch_id           uuid not null references branches(id) on delete cascade,
    category_id         uuid references categories(id) on delete set null,
    pos_external_id     text not null,                        -- SKU from POS
    name_ar             text not null,
    name_en             text not null,
    base_price          numeric(12,2) not null check (base_price >= 0),
    tax_percent         numeric(5,2)  not null default 14,
    is_available        boolean not null default true,        -- 86 flag from POS
    is_active           boolean not null default true,
    version             int not null default 0,               -- optimistic lock
    last_synced_at      timestamptz not null default now(),
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    deleted_at          timestamptz,
    unique (branch_id, pos_external_id)
);
create index ix_menu_items_branch_available
    on menu_items(branch_id) where is_available and is_active and deleted_at is null;
create index ix_menu_items_name_trgm
    on menu_items using gin (name_ar gin_trgm_ops, name_en gin_trgm_ops);

-- Cloud-only enrichment for menu items (ADR-005)
create table online_item_attributes (
    menu_item_id        uuid primary key references menu_items(id) on delete cascade,
    description_ar      text,
    description_en      text,
    tags                text[] not null default '{}',         -- 'spicy','vegetarian','chef_pick'
    allergens           text[] not null default '{}',
    calories            int,
    is_online_visible   boolean not null default true,
    is_featured         boolean not null default false,
    online_sort_order   int not null default 0,
    online_prep_minutes int,                                  -- overrides branch default
    min_per_order       int,
    max_per_order       int,
    updated_at          timestamptz not null default now(),
    updated_by          uuid references staff_users(id)
);

create table menu_item_media (
    id              uuid primary key default gen_random_uuid(),
    menu_item_id    uuid not null references menu_items(id) on delete cascade,
    url             text not null,                            -- Cloudflare R2 / CDN
    alt_ar          text,
    alt_en          text,
    width           int,
    height          int,
    blurhash        text,
    sort_order      int not null default 0,
    is_primary      boolean not null default false,
    created_at      timestamptz not null default now()
);
create index ix_media_item on menu_item_media(menu_item_id);

create table modifier_groups (
    id              uuid primary key default gen_random_uuid(),
    branch_id       uuid not null references branches(id) on delete cascade,
    pos_external_id text,
    name_ar         text not null,
    name_en         text not null,
    min_select      int not null default 0,
    max_select      int not null default 1,
    sort_order      int not null default 0,
    is_active       boolean not null default true,
    deleted_at      timestamptz,
    unique (branch_id, pos_external_id)
);

create table modifiers (
    id              uuid primary key default gen_random_uuid(),
    group_id        uuid not null references modifier_groups(id) on delete cascade,
    pos_external_id text,
    name_ar         text not null,
    name_en         text not null,
    price_delta     numeric(12,2) not null default 0,
    is_available    boolean not null default true,
    sort_order      int not null default 0,
    deleted_at      timestamptz,
    unique (group_id, pos_external_id)
);

create table item_modifier_groups (
    menu_item_id    uuid not null references menu_items(id) on delete cascade,
    group_id        uuid not null references modifier_groups(id) on delete cascade,
    sort_order      int not null default 0,
    primary key (menu_item_id, group_id)
);

-- =============================================================================
-- 4. ORDERS  (cloud-originating; mirrored to POS via Sync Agent)
-- =============================================================================

create table orders (
    id                  uuid primary key default gen_random_uuid(),
    branch_id           uuid not null references branches(id),
    customer_id         uuid not null references customers(id),
    address_id          uuid references addresses(id),        -- null for takeaway
    short_code          text not null unique,                 -- human-friendly: 'B01-1234'
    channel             order_channel not null,
    status              order_status not null default 'draft',
    version             int not null default 0,               -- optimistic lock
    -- monetary breakdown snapshot (frozen at submission)
    subtotal            numeric(12,2) not null default 0,
    discount_amount     numeric(12,2) not null default 0,     -- reserved for future
    delivery_fee        numeric(12,2) not null default 0,
    service_charge      numeric(12,2) not null default 0,
    tax_amount          numeric(12,2) not null default 0,
    total_amount        numeric(12,2) not null default 0,
    -- delivery / pickup details
    requested_for       timestamptz,                          -- null = ASAP
    estimated_ready_at  timestamptz,
    notes               text,
    -- POS linkage
    pos_order_id        text,                                 -- assigned by agent after POS write
    pos_ticket_number   text,                                 -- printed kitchen ticket no.
    -- timestamps
    placed_at           timestamptz,
    accepted_at         timestamptz,
    ready_at            timestamptz,
    completed_at        timestamptz,
    cancelled_at        timestamptz,
    cancel_reason       text,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);
create index ix_orders_branch_status   on orders(branch_id, status) where status not in ('completed','cancelled_by_customer','cancelled_by_branch','expired','failed');
create index ix_orders_customer        on orders(customer_id, created_at desc);
create index ix_orders_branch_date     on orders(branch_id, created_at desc);
create index ix_orders_pos_order       on orders(branch_id, pos_order_id) where pos_order_id is not null;

create table order_lines (
    id              uuid primary key default gen_random_uuid(),
    order_id        uuid not null references orders(id) on delete cascade,
    menu_item_id    uuid not null references menu_items(id),
    -- snapshot at order time (POS price re-fetched at checkout per ADR-006)
    name_ar         text not null,
    name_en         text not null,
    unit_price      numeric(12,2) not null check (unit_price >= 0),
    quantity        int not null check (quantity > 0),
    line_subtotal   numeric(12,2) not null,                   -- (unit_price + modifiers) * qty
    notes           text,
    sort_order      int not null default 0
);
create index ix_lines_order on order_lines(order_id);

create table order_line_modifiers (
    id              uuid primary key default gen_random_uuid(),
    order_line_id   uuid not null references order_lines(id) on delete cascade,
    modifier_id     uuid not null references modifiers(id),
    name_ar         text not null,
    name_en         text not null,
    price_delta     numeric(12,2) not null default 0,
    quantity        int not null default 1
);
create index ix_line_mods_line on order_line_modifiers(order_line_id);

-- Append-only event log (ADR-016)
create table order_events (
    id                  uuid primary key default gen_random_uuid(),
    order_id            uuid not null references orders(id) on delete cascade,
    from_status         order_status,
    to_status           order_status not null,
    actor_type          actor_type not null,
    actor_id            uuid,
    reason              text,
    idempotency_key     text,                                 -- (order_id, key) unique
    metadata            jsonb not null default '{}'::jsonb,
    occurred_at         timestamptz not null default now()
);
create index ix_events_order on order_events(order_id, occurred_at);
create unique index ux_events_idem on order_events(order_id, idempotency_key)
    where idempotency_key is not null;

-- =============================================================================
-- 5. PAYMENTS
-- =============================================================================

create table payments (
    id                  uuid primary key default gen_random_uuid(),
    order_id            uuid not null references orders(id) on delete cascade,
    method              payment_method not null,
    status              payment_status not null default 'none',
    amount              numeric(12,2) not null check (amount >= 0),
    currency            text not null default 'EGP',
    provider            text,                                 -- 'kashier' | 'cod' | ...
    provider_payment_id text,                                 -- Kashier transaction id
    provider_session_id text,                                 -- Kashier session id (HPP)
    idempotency_key     text not null,                        -- our key sent to provider
    authorized_at       timestamptz,
    captured_at         timestamptz,
    failed_at           timestamptz,
    failure_code        text,
    failure_message     text,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    unique (order_id, idempotency_key)
);
create index ix_payments_order on payments(order_id);
create index ix_payments_provider on payments(provider, provider_payment_id);

create table payment_events (
    id              uuid primary key default gen_random_uuid(),
    payment_id      uuid not null references payments(id) on delete cascade,
    from_status     payment_status,
    to_status       payment_status not null,
    source          text not null,                            -- 'webhook','manual','timer'
    raw_payload     jsonb,                                    -- full provider payload for audit
    occurred_at     timestamptz not null default now()
);
create index ix_payment_events_payment on payment_events(payment_id, occurred_at);

create table refunds (
    id                  uuid primary key default gen_random_uuid(),
    payment_id          uuid not null references payments(id),
    order_id            uuid not null references orders(id),
    amount              numeric(12,2) not null check (amount > 0),
    reason              text,
    requested_by        uuid references staff_users(id),
    provider_refund_id  text,
    status              text not null default 'pending'
                        check (status in ('pending','succeeded','failed')),
    created_at          timestamptz not null default now(),
    completed_at        timestamptz
);
create index ix_refunds_payment on refunds(payment_id);

-- Webhook replay protection (ADR-009)
create table processed_webhooks (
    provider        text not null,
    external_id     text not null,                            -- Kashier event id
    received_at     timestamptz not null default now(),
    primary key (provider, external_id)
);

-- =============================================================================
-- 6. DELIVERY  (ADR-032 — restaurant owns rider operations end-to-end;
--    cloud only stores delivery zones for fee + address validation)
-- =============================================================================

create table delivery_zones (
    id              uuid primary key default gen_random_uuid(),
    branch_id       uuid not null references branches(id) on delete cascade,
    name            text not null,
    polygon         jsonb not null,                           -- GeoJSON polygon
    base_fee        numeric(12,2) not null default 0,
    min_order_total numeric(12,2) not null default 0,
    is_active       boolean not null default true,
    sort_order      int not null default 0,
    created_at      timestamptz not null default now()
);

-- =============================================================================
-- 7. SYNC  (cloud ↔ Sync Agent on POS PC)
-- =============================================================================

-- Cloud → Agent (orders to insert into POS, menu changes to pull, status to push)
create table sync_outbox (
    id              uuid primary key default gen_random_uuid(),
    branch_id       uuid not null references branches(id),
    aggregate_type  text not null,                            -- 'order','menu_item','status'
    aggregate_id    uuid not null,
    event_type      text not null,                            -- 'order.created', etc.
    payload         jsonb not null,
    status          sync_outbox_status not null default 'pending',
    attempts        int not null default 0,
    last_attempt_at timestamptz,
    last_error      text,
    created_at      timestamptz not null default now(),
    sent_at         timestamptz,
    acked_at        timestamptz
);
create index ix_outbox_pending on sync_outbox(branch_id, created_at)
    where status in ('pending','failed');

-- Agent → Cloud (status updates from POS, menu deltas, COD collections)
create table sync_inbox (
    id              uuid primary key default gen_random_uuid(),
    branch_id       uuid not null references branches(id),
    agent_version   text,
    event_type      text not null,                            -- 'pos.status_changed', etc.
    payload         jsonb not null,
    idempotency_key text not null,
    status          sync_inbox_status not null default 'pending',
    received_at     timestamptz not null default now(),
    processed_at    timestamptz,
    last_error      text,
    unique (branch_id, idempotency_key)
);
create index ix_inbox_pending on sync_inbox(branch_id, received_at)
    where status in ('pending','failed');

create table agent_heartbeats (
    branch_id       uuid primary key references branches(id) on delete cascade,
    last_seen_at    timestamptz not null,
    agent_version   text,
    pos_db_path     text,
    metrics         jsonb not null default '{}'::jsonb        -- queue depths, last sync etc.
);

-- =============================================================================
-- 8. NOTIFICATIONS
-- =============================================================================

create table notification_templates (
    id              uuid primary key default gen_random_uuid(),
    code            text not null unique,                     -- 'order_placed','out_for_delivery'
    channel         notification_channel not null,
    body_ar         text not null,                            -- with {{tokens}}
    body_en         text not null,
    is_active       boolean not null default true,
    updated_at      timestamptz not null default now()
);

create table notification_log (
    id              uuid primary key default gen_random_uuid(),
    channel         notification_channel not null,
    template_code   text references notification_templates(code),
    recipient       text not null,                            -- phone / email
    subject_type    text,                                     -- 'order','staff'
    subject_id      uuid,
    body            text not null,
    status          notification_status not null default 'queued',
    provider        text,                                     -- 'msegat', 'victorylink' ...
    provider_id     text,
    error           text,
    queued_at       timestamptz not null default now(),
    sent_at         timestamptz,
    delivered_at    timestamptz
);
create index ix_notif_subject on notification_log(subject_type, subject_id);
create index ix_notif_pending on notification_log(status, queued_at)
    where status in ('queued','sending');

-- =============================================================================
-- 9. SYSTEM
-- =============================================================================

create table audit_log (
    id              uuid primary key default gen_random_uuid(),
    actor_type      actor_type not null,
    actor_id        uuid,
    branch_id       uuid references branches(id),
    action          text not null,                            -- 'menu.price_change','order.refund'
    entity_type     text not null,
    entity_id       uuid,
    before          jsonb,
    after           jsonb,
    ip              inet,
    occurred_at     timestamptz not null default now()
);
create index ix_audit_branch_date on audit_log(branch_id, occurred_at desc);
create index ix_audit_entity on audit_log(entity_type, entity_id);

-- =============================================================================
-- Triggers — updated_at maintenance
-- =============================================================================

create or replace function set_updated_at() returns trigger as $$
begin
    new.updated_at := now();
    return new;
end;
$$ language plpgsql;

do $$
declare t text;
begin
    for t in
        select unnest(array[
            'branches','staff_users','customers',
            'menu_items','orders','payments'
        ])
    loop
        execute format(
            'create trigger trg_%I_updated before update on %I
             for each row execute function set_updated_at();', t, t);
    end loop;
end$$;

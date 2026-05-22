# Ghazal — Cloud DB Schema (Neon Postgres)

Source of truth: this file. SQL DDL: [schema.sql](./schema.sql).

Owned by the cloud (Neon). The POS SQLite database is the source of truth for **menu items, prices, tax, modifiers, availability** (ADR-005). Cloud mirrors them via the Sync Agent, linked by `pos_external_id`.

## Conventions

| Concern | Choice |
|---|---|
| Primary keys | `uuid` (v7 preferred, generated client-side or via `gen_random_uuid()`) |
| Timestamps | `timestamptz` always; default `now()`; UTC stored |
| Money | `numeric(12, 2)` EGP — readable; precision sufficient for restaurant scale |
| Strings | `text` (no varchar length games) |
| Email | `citext` (case-insensitive) |
| Phone | `text` in E.164 (`+20…`) — validated at app layer |
| Bilingual fields | two columns: `name_ar`, `name_en`; never JSON for required text |
| JSON | `jsonb` only for genuinely free-form metadata (events, sync payloads) |
| Soft delete | `deleted_at timestamptz null` on long-lived entities; default queries filter it |
| Audit | `created_at`, `updated_at`, `created_by`, `updated_by` on mutable entities |
| Optimistic locking | `version int not null default 0` on `orders`, `menu_items`, `riders` |
| Multi-branch | every transactional table carries `branch_id`; menu items are per-branch |
| Naming | snake_case; plural tables; FK columns end in `_id` |
| Enums | Postgres `enum` types for closed lists (status, channel, role) |
| Indexes | always index FKs; partial indexes for `where deleted_at is null` |
| Constraints | enforce status enums + transitions in code; keep DB constraints for invariants only |

## Modules

1. **Core** — `branches`, `staff_users`, `roles`, `staff_branch_roles`, `customers`, `addresses`.
2. **Auth** — `otp_codes`, `refresh_tokens`, `customer_sessions`.
3. **Menu** — `categories`, `menu_items`, `menu_item_media`, `modifier_groups`, `modifiers`, `item_modifier_groups`, `online_item_attributes`.
4. **Orders** — `orders`, `order_lines`, `order_line_modifiers`, `order_events`.
5. **Payments** — `payments`, `payment_events`, `refunds`, `processed_webhooks`.
6. **Delivery (lightweight)** — `delivery_zones` only. Restaurant owns rider operations end-to-end (ADR-032).
7. **Sync** — `sync_outbox` (cloud→agent), `sync_inbox` (agent→cloud), `agent_heartbeats`.
8. **Notifications** — `notification_templates`, `notification_log`.
9. **System** — `branch_settings`, `audit_log`.

## ERD (logical)

```
                                 ┌──────────┐
                                 │ branches │
                                 └────┬─────┘
        ┌───────────────────┬────────┼────────┬──────────────────┐
        │                   │        │        │                  │
   ┌────▼─────┐      ┌──────▼────┐ ┌─▼────────────┐ ┌─▼─────────────┐
   │categories│      │menu_items │ │delivery_zones│ │branch_settings│
   └──────────┘      └─────┬─────┘ └──────────────┘ └───────────────┘
                           │
              ┌────────────┼─────────────────────┐
              │            │                     │
       ┌──────▼─────┐ ┌────▼────────┐  ┌────────▼───────────┐
       │menu_item_  │ │item_modifier│  │online_item_        │
       │media       │ │_groups      │  │attributes          │
       └────────────┘ └──────┬──────┘  │(images, desc, tags)│
                             │         └────────────────────┘
                       ┌─────▼──────┐
                       │ modifiers  │
                       └────────────┘

  customers ──< addresses
  customers ──< orders
  orders ──< order_lines ──< order_line_modifiers
  orders ──< order_events            (event log)
  orders ──< payments ──< payment_events
  orders ──< refunds
  orders ──< sync_outbox             (pushes to branch agent)
                                     sync_inbox ── (statuses from agent)

  staff_users ──< staff_branch_roles >── branches
```

## Key design decisions

- **`menu_items` is per-branch**, not global. Two branches may have different prices/availability for the same dish. They share the same `pos_external_id` only by convention; if branches use different POS instances, IDs differ — that's fine.
- **`online_item_attributes`** is the cloud-only enrichment (images, long descriptions, AR/EN names if richer than POS, tags, `is_online_visible`, online prep time, min/max per order). Linked 1:1 to `menu_items`.
- **`order_events`** is append-only; the order's current status is denormalised onto `orders.status` for fast reads, but every transition is recorded with actor + reason + idempotency key (ADR-016, ADR-018).
- **`processed_webhooks`** stores Kashier webhook IDs we've already handled — idempotent replay (ADR-009).
- **`sync_outbox` / `sync_inbox`** implement the outbox pattern on both sides (ADR-025). `sync_outbox` rows are deleted after the agent acks; `sync_inbox` rows transition to `processed`/`failed`.
- **`delivery_zones`** carries GeoJSON polygons used only for **address validation** and **fee calculation** at checkout. Rider dispatch is out of scope — the restaurant runs that themselves (ADR-032).
- **`audit_log`** for sensitive admin actions only (price changes, refunds, cancellations by staff). Don't log every CRUD — `order_events` covers orders, and App Insights covers infra.
## What the schema deliberately omits (out of MVP)

- Loyalty points, coupons, promotions, gift cards (ADR-031).
- Multi-tenancy beyond multi-branch (single restaurant brand).
- Inventory tracking beyond POS-driven 86 flag.
- Reviews / ratings.
- Marketing campaigns.

Add via migrations later — schema is designed to extend without breaking changes.

## Migrations

- Use **EF Core migrations** (since API is .NET 10). Folder: `src/Ghazal.Api/Migrations/`.
- Naming: `YYYYMMDD_HHmm_short_description.cs`.
- One Neon **branch per environment**: `main` (prod), `staging`, `dev-<developer>`. Use Neon's free branching.
- Apply migrations from CI on deploy; never `dotnet ef database update` against prod from a laptop.

## Indexes — initial set

Listed in [schema.sql](./schema.sql). Review with `EXPLAIN` after first month of real traffic and adjust.

## Backups

- Neon Free includes 7 days PITR — sufficient for MVP.
- Weekly `pg_dump` to Cloudflare R2 as off-site cold backup; retain 4 weeks.

## Migration path

- 0.5 GB Neon Free → **Neon Launch ($19/mo)** at ~80% storage or when connection limits bite.
- Then → **Azure DB for PostgreSQL Flexible** if we consolidate fully on Azure.

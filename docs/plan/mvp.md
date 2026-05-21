# Ghazal — MVP Scope & Phased Delivery Plan

**Status**: Draft for client review

## 1. Goals

- Let customers order food online for **takeaway** or **delivery**, pay by **card / wallet / COD**, and get **live status updates by SMS**.
- Give restaurant staff a simple **admin dashboard** to manage live orders, hide unavailable items, change prices/prep times, and refund.
- Mirror online orders into the **existing POS** so the kitchen workflow does not change.
- Run on **near-zero monthly infrastructure cost** during the pilot.
- Deliver to **one pilot branch** first, then scale to additional branches with no rewrite.

## 2. Non-goals (v1)

- Rider dispatch, GPS tracking, COD reconciliation in cloud — restaurant owns delivery operations (ADR-032).
- Loyalty, coupons, promotions, gift cards (ADR-031).
- Marketing campaigns / push notifications / email receipts.
- Reviews and ratings.
- Multi-restaurant SaaS — single restaurant, possibly multi-branch.
- iOS/Android native apps — PWA is enough.

## 3. Personas

| Persona | Channel | Primary jobs |
|---|---|---|
| **Customer** | Customer PWA on mobile | Browse menu, build cart, choose takeaway/delivery, pay, track status |
| **Owner** | Admin PWA | Configure branch, see daily sales, view orders, do refunds beyond limits |
| **Manager** | Admin PWA | Accept/reject orders, 86 items, change prep time, refund within limit, pause online ordering |
| **Cashier / Kitchen** | Existing POS app | Unchanged workflow — online orders just appear in their POS like any other order |
| **Dev team** | GitHub + Azure | Build, deploy, monitor |

## 4. MVP feature list

### Customer PWA — `apps/customer-web`
- AR/EN with RTL.
- Menu browse: categories, items with photos/descriptions/tags, "currently unavailable" badges.
- Search (typo-tolerant via `pg_trgm`).
- Cart with modifier selection, qty, notes.
- Channel toggle: **Takeaway** (pickup at branch) / **Delivery** (address + zone fee).
- Address book: at least one address per customer, GeoJSON polygon check against `delivery_zones`.
- Phone-OTP login (no email required).
- Checkout:
  - Re-fetch live prices from POS snapshot at submit (ADR-006).
  - Payment options: card / wallet via Kashier HPP, or COD.
  - Branch open hours and pause state respected.
- Live order tracking page: status timeline + estimated ready time.
- Order history per customer.
- PWA install prompt, offline menu cache for repeat visitors.

### Admin PWA — `apps/admin-web`
- Staff login (email + password + role).
- **Live Orders board**: new / accepted / preparing / ready / out-for-delivery / completed, filterable by channel + branch.
- One-tap **Accept / Reject** with reason; rejection triggers refund flow.
- Mark **Ready** / **Out for Delivery** / **Completed** (matches simplified state machine).
- **Menu Health**: items missing images, items hidden online, recent price changes, 86'd items.
- Edit per-item online attributes (image, description, tags, `is_online_visible`, online prep time).
- Toggle **Pause online ordering** for the branch (e.g., kitchen overload).
- **Refunds** within manager limit; manager+ for partial; owner-only for completed orders.
- **Reports**: daily orders, revenue, payment-method split, top items, cancellation reasons.
- Branch settings: hours, default prep time, delivery fee, VAT, service charge, `track_out_for_delivery` toggle, configurable timeouts.
- View Sync Agent health (last heartbeat, sync lag, queue depth).

### Sync Agent — `agents/sync-agent`
- Windows Service, .NET 8 Worker.
- Loads YAML mapping config per POS vendor (table/column mapping) — discovery deferred (see Phase 3).
- **Cloud → Agent**: pulls new online orders, inserts into a dedicated `online_orders_inbox` table inside the POS SQLite DB.
- **Agent → Cloud**: detects POS status changes (signal-based per ADR-017), pushes back to cloud with idempotency keys.
- Menu/stock pull (text fields only — images live in the cloud per ADR-005).
- Local SQLite outbox for retries (ADR-025).
- Heartbeat + metrics to cloud every 30s.
- Outbound HTTPS only; signed JWT per branch (ADR-003).
- Auto-updater from signed manifest.

### Cloud API — `services/api` (Azure Functions, .NET 8 isolated)
- Modules: `auth`, `menu`, `orders`, `payments`, `notifications`, `sync`, `admin`, `webhooks`.
- Kashier HPP + webhook handler with HMAC verification (ADR-009).
- SMS provider adapter (ADR-010 — provider TBD by cost in phase 0).
- Notification sender for: OTP, order_placed, accepted, ready/out-for-delivery, completed, cancelled.
- Idempotency keys on order creation, payments, webhooks, agent push.
- Cold-start warm-up timer trigger during branch hours (ADR-030).

### Infrastructure
- Azure SWA (Free, two apps: customer-web, admin-web).
- Azure Functions Consumption (.NET 8 isolated).
- Neon Postgres Free tier, EU region, branched per env.
- Cloudflare R2 for menu images + receipts.
- Cloudflare DNS + Free WAF.
- Application Insights (Free 5 GB/mo).
- GitHub Actions CI/CD; budget alerts on Azure subscription.

## 5. Out of MVP (deferred backlog)

| Item | Reason deferred |
|---|---|
| WhatsApp Cloud API notifications | Template approval delays; SMS covers MVP |
| Email receipts | Not critical for EG ordering; SMS+web is enough |
| Push notifications (FCM) | Adds PWA permission friction; SMS works without app install |
| Loyalty points, coupons, referrals | ADR-031 |
| Multi-language beyond AR/EN | Out of need |
| Live rider tracking / dispatch | ADR-032 |
| Marketing campaigns / abandoned cart | Post-MVP retention work |
| Reviews / ratings | Requires moderation; not MVP-critical |
| Native iOS/Android apps | PWA is sufficient at this scale |
| Multi-restaurant SaaS-ification | Out of need |
| Catering / scheduled orders weeks ahead | Edge case; ASAP + same-day suffices |

## 6. Phased delivery

Phases are ordered, not date-boxed. Each phase has a clear **exit criterion** so we know when we can move on. **Every feature inside a phase is built test-first** — see TDD discipline below.

### TDD discipline (applies to every phase)

**Red → Green → Refactor**, per story:
1. **Red** — write a failing test that expresses the next behaviour. Commit so the failing test is visible in history.
2. **Green** — write the minimum code to make it pass. No gold-plating.
3. **Refactor** — improve names, remove duplication, tighten boundaries. Tests stay green.

**Test pyramid**:

| Layer | Tool | What it covers | Where it lives |
|---|---|---|---|
| **Unit** | xUnit + FluentAssertions + NSubstitute | Pure logic: state machine transitions, price math, HMAC signing, mappers | `tests/<module>.UnitTests` |
| **Integration** | xUnit + Testcontainers (Postgres) + WebApplicationFactory | Real DB + EF + Functions host; verify SQL, transactions, outbox writes | `tests/<module>.IntegrationTests` |
| **Contract** | xUnit + WireMock.Net | Kashier webhook signature + payload shapes; SMS provider stub | `tests/Contracts.Tests` |
| **E2E** | Playwright (TS) | Critical journeys end-to-end through SWA + Functions + Neon test branch | `tests/e2e/playwright` |
| **Sync Agent** | xUnit + temp SQLite file | Mappers, outbox replay, idempotency, schema-fingerprint guard | `tests/SyncAgent.UnitTests` |
| **Mutation (hardening)** | Stryker.NET on `Orders` + `Payments` modules | Catches assert-light tests | Phase 4, not per-PR |

**Critical paths covered by E2E (must exist before launch)**:
- Customer places card-paid order → webhook → `PLACED` → admin marks `READY` → `COMPLETED` → status SMS sent.
- Customer places COD order → admin accepts → `COMPLETED`.
- Same Kashier webhook delivered twice → exactly one state change.
- Admin issues refund → Kashier refund webhook → `REFUNDED`.
- Delivery-zone validation rejects out-of-area address at checkout.

**What we do NOT test**:
- Generated EF migrations or framework wiring.
- Third-party SDK internals — only our adapter around them.
- Trivial DTOs / getters — the compiler already typed them.
- Static config files.

**Definition of Done** (every PR):
- New behaviour has at least one failing test that turned green inside this PR (visible in commit history).
- All test layers green in CI on the PR branch.
- No new App Insights `Error`-level warnings.
- ADR added or updated if a design decision changed.

**CI test gates** (GitHub Actions):
- PR cannot merge if unit + integration tests fail.
- Nightly job runs Playwright E2E against staging.
- Weekly Stryker mutation report — informational until Phase 4, gating thereafter.
- Coverage delta posted as PR comment (informational only; don't chase the number).

### Phase 0 — Foundations
- GitHub org + monorepo skeleton (pnpm workspaces for frontends; `dotnet sln` for backend + agent).
- Branch protection + CI on `main`.
- **Testing toolchain set up and CI-gated**:
  - .NET test projects per module (`*.UnitTests`, `*.IntegrationTests`) with xUnit + FluentAssertions + NSubstitute.
  - **Testcontainers** Postgres image pinned to Neon's version; first integration test uses it.
  - **Playwright** workspace under `tests/e2e` with one smoke test that hits the deployed `/health`.
  - GitHub Actions `test` job blocks merge on failure; nightly `e2e` job against staging.
- Azure subscription, Neon project, Cloudflare account, R2 bucket, App Insights resource.
- Domain registered (e.g. `ghazal.example`); DNS on Cloudflare.
- Apply [schema.sql](../db/schema.sql) to Neon `staging` + `main` branches.
- Choose SMS provider, get sandbox credentials, start NTRA sender-ID approval (long lead).
- Kashier sandbox credentials in hand.
- **Exit**: empty API returns 200 on `/health` from a custom domain; both SWAs serve a "Hello" page; CI green; the smoke E2E test passes against the deployed stack.

### Phase 1 — Cloud backbone

**Test plan (red first)**:
- *Unit*: JWT issue/verify; OTP generation, expiry, single-use; password hash/verify; role-based authorize policy.
- *Integration*: register staff user; sign in; refresh-token rotation; create category + item; image upload to R2 (use MinIO Testcontainers stand-in).
- *E2E*: admin signs in → seeds a menu item with image → sees it listed via public API.

**Build**:
- Auth: staff email/password, customer phone-OTP, JWT + refresh, OTP rate-limit in memory.
- Menu CRUD admin (cloud-only data: categories/items shell, online_item_attributes, media upload to R2).
- Orders read-only API + DB scaffolding.
- App Insights wired across API + SWA.

**Exit**: admin can sign in, create a branch, seed a few menu items + images, list them via API. All test layers green; the auth + menu E2E passes on staging.

### Phase 2 — Customer ordering + payments

**Test plan (red first)**:
- *Unit*: `OrderStateMachine.Transition` — every valid + invalid transition; price math (subtotal, tax, fee, total) with bidi rounding; HMAC signing of Kashier requests; webhook signature verification (positive + negative + malformed); idempotency-key collision handling.
- *Integration*: place order writes lines + events + outbox in one transaction; webhook handler replayed twice produces exactly one state change; refund flow updates payment + creates refund row; delivery-zone polygon validation accepts/rejects correctly.
- *Contract*: Kashier webhook payloads (success / failure / refund) via WireMock fixtures; SMS provider success + retry-on-503.
- *E2E*: full card payment flow; full COD flow; failed payment flow; refund initiated by manager; address-out-of-zone rejection.

**Build**:
- Customer PWA: menu browse, search, cart, checkout, OTP login, order detail.
- Address book + delivery-zone validation.
- Kashier HPP integration + webhook + idempotency.
- COD path.
- Order state machine (cloud-only, no POS yet).
- SMS provider adapter: OTP, order_placed, completed.
- Refunds via Kashier API + admin UI.

**Exit**: real customer places an order paid by Kashier sandbox or COD; manager accepts/refunds it from the admin. POS is *not* in the loop yet. All four E2E flows pass on staging.

### Phase 3 — POS integration (on-site work)

**Test plan (red first)**:
- *Unit*: YAML mapping loader (valid, missing field, wrong type); field mappers (POS row → cloud DTO and back, both directions); status-signal detector (POS column → cloud status); schema-fingerprint computer.
- *Integration* with **fixture SQLite file** crafted to mimic the discovered POS schema: order-push idempotency on retry; menu-pull diff detection; status-push outbox replay; agent refuses to start when schema fingerprint mismatches mapping config.
- *E2E* (manual on-site once; then scripted using the fixture DB in CI): place online order → row in fixture POS DB → status flips back → SMS fires.

**Build**:
- **On-site discovery** (POS SQLite checklist — a separate doc to be produced before the visit):
  - Locate DB file; back it up.
  - Dump schema; identify items/prices/orders/modifiers tables.
  - Confirm WAL mode behaviour and that the cashier app tolerates an `online_orders_inbox` table.
- Sync Agent v1:
  - YAML mapping config tailored to this POS.
  - Menu/stock pull → cloud.
  - Order push: cloud → `online_orders_inbox` → import script/trigger or manager "Accept" action.
  - Status push: agent → cloud, mapped via ADR-017 signals.
  - Heartbeat + metrics.
- Wire status transitions to SMS notifications.

**Exit**: an online order placed by a customer appears on the POS within 60s; the kitchen prints a ticket; status updates flow back; customer's SMS notifications fire end-to-end. Mapping + outbox integration tests green against the fixture DB; on-site E2E observed live.

### Phase 4 — Hardening & pilot
- Load test the order path (synthetic peak ~5× expected/hour).
- Cold-start warm-up timer trigger live during branch hours.
- Backups: nightly `pg_dump` to R2; tested restore.
- Alerts wired in App Insights: payment failure rate, agent offline, error spike.
- Runbooks for: payment dispute, refund stuck, agent disconnected, POS schema change.
- **Mutation testing pass** with Stryker.NET on `Orders` + `Payments` modules; target ≥ 80% mutation score on the state machine and HMAC code. From this phase onward, Stryker is a gating CI job, not informational.
- **Chaos tests**: scripted scenarios for Kashier webhook timeout, agent disconnect, Neon cold-start mid-checkout, SMS provider 5xx. Each scenario has an automated test asserting the system degrades gracefully (queue, retry, alert).
- Privacy policy + T&Cs (AR/EN), Kashier site review passed.
- Owner + manager training (1-hour walkthrough + screen recording).
- **Exit**: signed-off pilot launch — single branch, real customers, observed for ~2 weeks. Mutation score and chaos test results documented in `docs/quality/`.

### Phase 5 — Rollout & iteration
- Move pilot learnings into a v1.1 backlog. **Every bug fix lands paired with a regression test** that fails on `main` first.
- Onboard branch #2 (validate multi-branch assumption).
- Promote next-priority deferred item (likely WhatsApp templates or scheduled orders) — starts again at Phase 1 of red-green-refactor.
- Quarterly cost review: do we need Neon Launch ($19) or App Service B1 yet?

## 7. Pilot success metrics

| Metric | Target (v1) | How measured |
|---|---|---|
| Online-order **completion rate** | ≥ 90% of `PLACED` orders reach `COMPLETED` | `order_events` |
| Customer **checkout success rate** | ≥ 80% from cart → paid | App Insights funnel |
| **Time to first SMS** after order placement | ≤ 30s p95 | `notification_log` − `orders.placed_at` |
| **Sync lag** (cloud → POS) | ≤ 60s p95 | `sync_outbox.created_at` → `sync_outbox.acked_at` |
| **Agent uptime** during branch hours | ≥ 99% | heartbeat coverage |
| **Payment failure rate** | < 5% (excluding user-cancelled) | `payments` |
| **Refund cycle time** | < 1 business day median | refund created → `REFUNDED` event |
| **Online share of orders** at pilot branch | ≥ 10% by end of pilot | total orders vs POS daily |

Track these on a Workbook in App Insights, plus a Slack/Email digest each morning.

## 8. Pre-launch checklist

**Legal / commercial (client owns)**
- [ ] Restaurant CR active and matches Kashier docs + bank account
- [ ] Kashier production credentials issued; site review passed
- [ ] NTRA sender-ID approved for SMS provider
- [ ] T&Cs, Privacy, Refund/Cancellation, Delivery policy published in AR
- [ ] Operating license + tax card on file

**Technical**
- [ ] Production Neon branch with daily backup + tested restore
- [ ] R2 bucket with retention policy on receipts
- [ ] Custom domain on SWA + Functions with valid TLS
- [ ] Kashier webhook URL whitelisted in their dashboard; HMAC verified
- [ ] App Insights alerts firing into email + manager phone
- [ ] Sync Agent installed as Windows Service with auto-restart
- [ ] Agent has signed JWT; updater verified
- [ ] Budget alerts set ($5, $20)
- [ ] Runbooks committed to `docs/runbooks/`

**Training**
- [ ] Manager 1-hour walkthrough of admin
- [ ] Owner 30-minute walkthrough of reports + refunds
- [ ] One-page printable cheat-sheet for cashier (what to do when an online order appears)

## 9. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| POS schema changes after vendor update | Sync Agent breaks silently | YAML mapping config + agent self-tests against schema fingerprint at startup |
| Kashier outage | Card payments unavailable | COD remains; admin banner; queue retries |
| SMS provider outage / sender-ID rejection | OTP and notifications fail | Fallback OTP path (e.g. Firebase Phone Auth); secondary SMS provider in adapter |
| Free-tier limits hit (Neon storage, Functions GB-s) | App slows/breaks | Budget alerts + documented upgrade path (ADR-029) |
| Restaurant doesn't upload menu photos | Customer site looks unprofessional | "Menu Health" nag screen + branded category placeholders |
| Branch loses internet | New orders queue but POS doesn't see them | Agent retries; admin shows "branch offline" banner; cloud holds orders for replay |
| Disputes/chargebacks | Lost revenue | Full event log + signed Kashier responses kept 13 months |
| Bilingual / RTL bugs | Bad UX in AR | RTL design tokens from day one; native-Arabic-speaker QA pass before launch |
| Scope creep ("just add WhatsApp / loyalty…") | Pilot slips | Strict deferred list (section 5); written change-request flow |

## 10. Open items requiring client input

1. Pilot branch — which location?
2. Brand assets — logo, colours, hero photos, About text in AR/EN.
3. Domain name preference.
4. Refund policy thresholds (how big a refund can a manager do vs. owner-only?).
5. Branch hours and prep time defaults for pilot branch.
6. Delivery zones — polygons or rough boundary descriptions to digitise.
7. Phone numbers to receive critical alerts (owner + IT contact).

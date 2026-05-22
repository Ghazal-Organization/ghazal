# Ghazal — API Surface

**Audience**: backend devs, frontend devs, Sync Agent dev, QA.
**Source of truth**: [openapi.yaml](./openapi.yaml). This README is the narrative version.

## 1. Conventions

### Base URL & versioning
- Base: `https://api.ghazal.example`
- Versioning: **URI** — `/v1/...`. Additive changes within `/v1/`; breaking changes go to `/v2/`.
- Deprecation: `Sunset` + `Deprecation` headers per RFC 8594 when a `v1` endpoint is retired.

### Auth (three audiences — see ADR-011)
- `customer` — JWT issued via phone OTP. Short TTL (15 min) + refresh token (30 days).
- `staff` — JWT issued via email/password. Same TTL pattern. Carries `role` + `branch_id[]` claims.
- `agent` — JWT issued per branch at install time, long-lived (90 days, rotated), `aud=agent`, `branch_id` claim.
- All endpoints under `/v1/admin/**` require `staff` JWT.
- All endpoints under `/v1/sync/**` require `agent` JWT.
- All endpoints under `/v1/me/**` and `POST /v1/orders` require `customer` JWT.
- Public read endpoints (`/v1/branches`, `/v1/branches/{id}/menu`) are unauthenticated.

Header: `Authorization: Bearer <jwt>`.

### Errors
Format: **RFC 7807 Problem Details** (`application/problem+json`).

```json
{
  "type": "https://api.ghazal.example/errors/invalid-transition",
  "title": "Invalid status transition",
  "status": 409,
  "detail": "Cannot move order from PLACED to COMPLETED.",
  "instance": "/v1/admin/orders/8f2…/mark-completed",
  "errors": {                              // optional per-field validation
    "items[0].quantity": ["must be > 0"]
  },
  "traceId": "00-9d…-01"
}
```

Standard `type` URIs (kept under `/errors/`):
- `invalid-transition`, `out-of-zone`, `branch-closed`, `online-ordering-paused`,
- `payment-failed`, `webhook-signature-invalid`, `duplicate-request`,
- `not-found`, `forbidden`, `unauthorized`, `rate-limited`, `validation-failed`,
- `internal-error`.

### Idempotency
- Header: `Idempotency-Key: <client-generated-uuid>`.
- Required on: `POST /v1/orders`, `POST /v1/orders/{id}/payment`, `POST /v1/admin/orders/{id}/refund`, `POST /v1/sync/inbox`.
- Replays return the **original response** (200 if it succeeded, the same problem+json if it didn't).
- Keys are scoped per (subject, endpoint) and kept 24h.

### Pagination
- **Cursor** (default for time-ordered lists like orders, events):
  - `?limit=50&cursor=eyJjcmVhdGVkX2F0IjoiMjAyNi0wNS0yMlQxMDowMDowMFoiLCJpZCI6IjhmMi4uIn0`
  - Response includes `nextCursor` (null when done).
- **Offset** allowed where lists are small and stable (menu, branches): `?limit=100&offset=0`. Max `limit = 200`.

### Money & currency
- All amounts: `numeric(12,2)` in **EGP** (matches DB).
- Field naming: `subtotal`, `tax_amount`, `delivery_fee`, `service_charge`, `discount_amount`, `total_amount`.
- Snapshotted into the order at submit time (ADR-006).

### Time
- All timestamps **ISO 8601 UTC**: `2026-05-22T13:45:00Z`.
- Branch open/close times rendered with the branch `timezone` (default `Africa/Cairo`).

### Localisation
- `Accept-Language: ar` or `en` (default `ar`). Affects `Problem.detail`, `Problem.title`, and SMS body templates picked.
- Menu items carry both `name_ar` and `name_en` in the response — the client picks. No server-side language switching for menu content.

### Rate limiting
- Per-IP and per-token. Defaults: 60 req/min unauth, 300 req/min customer, 600 req/min staff, 1200 req/min agent.
- Hit → `429` with `Retry-After` header and `type=rate-limited` problem.
- OTP request: **3 per phone per hour, 10 per IP per hour** (tighter; abuse-sensitive).

### Tracing & correlation
- Inbound `traceparent` header honoured (W3C Trace Context).
- Every response carries `traceId` in body + `x-trace-id` header.
- The same `traceId` flows: customer browser → API → Functions → Paymob webhook handler → Sync Agent.

### Content type
- `application/json` for requests and responses; `application/problem+json` for errors.
- File uploads: `multipart/form-data` (menu media only).

### Health
- `GET /healthz` — liveness, returns `{"status":"ok"}` and the App Insights link in the trace.
- `GET /readyz` — checks Neon + R2 + Paymob reachability.

---

## 2. Endpoint catalogue (grouped by module)

Status codes shown are the **happy path**; error responses always use Problem Details.

### Auth (`/v1/auth`)
| Method | Path | Purpose | Auth | Returns |
|---|---|---|---|---|
| POST | `/auth/otp/request` | Send OTP SMS to phone | none | 202 |
| POST | `/auth/otp/verify` | Verify OTP, issue tokens | none | 200 `{accessToken, refreshToken, customer}` |
| POST | `/auth/refresh` | Rotate refresh token | refresh in body | 200 `{accessToken, refreshToken}` |
| POST | `/auth/logout` | Revoke refresh token | customer | 204 |
| POST | `/admin/auth/login` | Staff email + password → tokens | none | 200 `{accessToken, refreshToken, user, branches}` |
| POST | `/admin/auth/refresh` | Staff refresh | refresh in body | 200 |
| POST | `/admin/auth/logout` | Staff logout | staff | 204 |

### Customer profile (`/v1/me`)
| Method | Path | Purpose | Auth |
|---|---|---|---|
| GET | `/me` | Current customer profile | customer |
| PATCH | `/me` | Update name, preferred_lang | customer |
| GET | `/me/addresses` | List | customer |
| POST | `/me/addresses` | Create (validates against `delivery_zones` if `lat,lng` given) | customer |
| PATCH | `/me/addresses/{id}` | Update | customer |
| DELETE | `/me/addresses/{id}` | Soft-delete | customer |
| GET | `/me/orders` | Customer's order history (cursor paged) | customer |

### Public menu (`/v1/branches`)
| Method | Path | Purpose | Auth |
|---|---|---|---|
| GET | `/branches` | Active branches with hours, online flag | none |
| GET | `/branches/{branchId}` | Single branch details | none |
| GET | `/branches/{branchId}/menu` | Categories + items + modifiers + media + online attributes | none |
| GET | `/branches/{branchId}/menu/items/{itemId}` | One item, full detail | none |
| POST | `/branches/{branchId}/delivery-quote` | Validate address vs zones → returns matching zone + fee or 422 `out-of-zone` | none |

### Orders & payments (`/v1/orders`, `/v1/me/orders`)
| Method | Path | Purpose | Auth |
|---|---|---|---|
| POST | `/orders` | Create order from cart (Idempotency-Key required). Returns order + payment intent if not COD. | customer |
| GET | `/orders/{id}` | Get order (customer can only see own; staff via admin route) | customer |
| POST | `/orders/{id}/cancel` | Customer-initiated cancel (only allowed before `ACCEPTED`) | customer |
| POST | `/orders/{id}/payment` | Initiate / re-initiate Paymob session for the order; returns HPP URL | customer |
| GET | `/orders/{id}/payment/status` | Latest payment status (poll fallback for SignalR) | customer |

### Webhooks (`/v1/webhooks`)
| Method | Path | Purpose | Auth |
|---|---|---|---|
| POST | `/webhooks/paymob` | Paymob payment events (HMAC verified, replay-safe) | signature |
| POST | `/webhooks/sms` | Optional delivery receipts from SMS provider | signature/IP |

### Admin (`/v1/admin`)
| Method | Path | Purpose | Auth (role) |
|---|---|---|---|
| GET | `/admin/branches/{branchId}/orders` | Live orders board, filterable by status & channel | staff (any branch role) |
| GET | `/admin/orders/{id}` | Order detail incl. events + payments | staff |
| POST | `/admin/orders/{id}/accept` | `PLACED → ACCEPTED` | manager/cashier |
| POST | `/admin/orders/{id}/reject` | `PLACED → REJECTED` (+ auto refund) | manager |
| POST | `/admin/orders/{id}/start-preparing` | `ACCEPTED → PREPARING` | kitchen/cashier/manager |
| POST | `/admin/orders/{id}/mark-ready` | `PREPARING → READY` | kitchen/cashier/manager |
| POST | `/admin/orders/{id}/mark-out-for-delivery` | `READY → OUT_FOR_DELIVERY` (delivery only) | manager/cashier |
| POST | `/admin/orders/{id}/mark-completed` | `READY|OUT_FOR_DELIVERY → COMPLETED` | manager/cashier |
| POST | `/admin/orders/{id}/cancel` | Branch-initiated cancel | manager |
| POST | `/admin/orders/{id}/refund` | Full or partial via Paymob | manager (≤ threshold), owner (any) |
| GET | `/admin/branches/{branchId}/menu/items` | Items + online attrs + media (admin view) | manager/owner |
| PATCH | `/admin/menu/items/{id}/online-attributes` | Update description, tags, `is_online_visible`, prep time, min/max | manager/owner |
| POST | `/admin/menu/items/{id}/media` | Upload image (multipart) — server transcodes to R2 | manager/owner |
| DELETE | `/admin/menu/media/{mediaId}` | Remove image | manager/owner |
| PATCH | `/admin/branches/{branchId}/settings` | `branch_settings` mutations | owner (most), manager (subset) |
| POST | `/admin/branches/{branchId}/online-ordering` | `{enabled:bool, reason?:string}` | manager/owner |
| GET | `/admin/branches/{branchId}/agent` | Sync Agent health (last heartbeat, queue depths) | manager/owner |
| GET | `/admin/branches/{branchId}/reports/daily` | Daily summary `?date=YYYY-MM-DD` | manager/owner |

### Sync (`/v1/sync`) — agent only
| Method | Path | Purpose | Auth |
|---|---|---|---|
| POST | `/sync/heartbeat` | `{agent_version, pos_db_path, metrics}` | agent |
| GET | `/sync/outbox?since=<cursor>` | Long-poll pull of pending cloud→agent events (orders, menu updates, status pushes) | agent |
| POST | `/sync/outbox/{eventId}/ack` | Agent acknowledges processed event | agent |
| POST | `/sync/inbox` | Agent posts events to cloud (POS status changes, menu deltas, COD collected). Idempotency-Key required. | agent |

---

## 3. Critical-path sequences

### A. Customer places card-paid order

```
Client POST /v1/orders                                       Idempotency-Key
   └─► API: validate branch open + items available + price match
       └─► insert order(status=PENDING) + lines + events(transition→PENDING)
       └─► insert sync_outbox(event=order.created)            [agent will pull]
       └─► create payment(status=AUTHORIZING)
   ◄── 201 { orderId, paymentSessionUrl }   (or 202 if COD)

Client redirects to Paymob HPP
   ... user pays ...

Paymob ─► POST /v1/webhooks/paymob                         HMAC
   └─► verify signature
   └─► dedupe via processed_webhooks PK
   └─► if CAPTURED: payment→CAPTURED, order PENDING→PLACED
   └─► append order_events; enqueue notification(order_placed)
   ◄── 200

Branch agent GET /v1/sync/outbox  ──► [{event=order.created,…}]
Agent inserts into POS DB; POSTs /sync/outbox/{id}/ack

Cashier marks order in POS  →  Agent POST /v1/sync/inbox {event=pos.status_changed,status=PREPARING}
   └─► API: maps to ORDER state transition, fires SMS
```

### B. Refund

```
Manager POST /v1/admin/orders/{id}/refund {amount, reason}    Idempotency-Key
   └─► validate state allows refund + role limit
   └─► call Paymob refund API
   └─► insert refund(status=pending) + payment_events
   ◄── 202 { refundId, status=pending }

Paymob ─► POST /v1/webhooks/paymob   (refund event)
   └─► refund.status=succeeded, payment→REFUNDED, order cancel/completed accordingly
   └─► SMS customer (refund issued)
```

### C. Branch agent reconnects after downtime

```
Agent POST /v1/sync/heartbeat
   ◄── 200

Agent GET /v1/sync/outbox?since=<last_acked_cursor>
   ◄── 200 [<events queued during downtime>, …]

Agent processes each, acks, then catches up status push via /sync/inbox.
```

---

## 4. Versioning & deprecation policy

- Add fields freely (clients must ignore unknown fields).
- Never change a field's type or semantics inside a version.
- Mark old endpoints deprecated with `Deprecation: true` + `Sunset: <date>` headers for at least one month before removal.
- `/v2/` only when a genuinely breaking change is unavoidable.

## 5. What to read next

- The machine-readable contract: [openapi.yaml](./openapi.yaml).
- Order/payment transition rules: [ADR-014](../ADR/014-Order_state_machine.md).
- Webhook idempotency: [ADR-009](../ADR/009-Webhook_is_the_source_of_truth_for_payment_status.md).
- Sync outbox/inbox semantics: [ADR-025](../ADR/025-Reliability_outbox_pattern_on_both_sides.md).

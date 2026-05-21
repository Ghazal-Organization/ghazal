# ADR-032: Delivery operations owned by the restaurant (out of cloud scope)

**Status**: Accepted (2026-05-21)
**Supersedes**: the original ADR-030 "Delivery model = own riders" (now obsolete — the rider/dispatch system has been removed from the cloud scope).

## Context

The restaurant already runs its own delivery operation (initially 4 in-house riders, occasionally augmented by a third-party delivery company on peak nights). They manage rider scheduling, dispatch, GPS tracking (informally), and COD reconciliation through their existing tools — typically the POS app, WhatsApp groups, and paper logs.

We are building **an online ordering system**, not a delivery management system. Bringing rider apps, GPS, dispatch, partner integrations, and COD reconciliation into the cloud expands the scope by months without clear product value to a single restaurant with 100–300 orders/day.

## Decision

The cloud system **does not** manage:
- Riders or rider authentication.
- Rider mobile apps (no Rider PWA).
- Order-to-rider assignment.
- Real-time GPS tracking of riders.
- Third-party delivery partner integrations (Talabat, Mrsool, Voo, etc.).
- Rider shifts and COD cash reconciliation.

The cloud system **does** handle:
- **Delivery channel** flag on orders (`order_channel = 'delivery' | 'takeaway'`).
- **Customer addresses** + lat/lng.
- **Delivery zones** (GeoJSON polygons) for **fee calculation** and **deliverable-area validation** at checkout.
- **Per-order delivery fee** captured at submission.
- An optional **`OUT_FOR_DELIVERY`** order status, marked by the cashier (or POS-via-Sync-Agent) when the order leaves the kitchen, controlled per branch by `branch_settings.track_out_for_delivery`.
- Customer notifications driven by these status transitions (e.g. "On the way" SMS).

## Rationale

- **Scope discipline.** Rider apps + GPS + dispatcher tooling + 3PL adapters easily double the MVP effort and ongoing maintenance.
- **The restaurant already solves it.** Their existing workflow works; replacing it with our system without clear improvement adds risk for no gain.
- **Privacy / labour considerations.** Tracking riders' GPS in our cloud raises consent and compliance concerns we don't need to inherit.
- **Reversible.** All schema artefacts removed today can be re-added in a single migration if scope expands later.

## Alternatives considered

| Option | Rejected because |
|---|---|
| Own-riders + 3PL overflow in cloud (original ADR-030) | Big scope; restaurant already runs this themselves |
| Cloud-managed riders only | Same scope problem; restaurant uses 4 different overflow paths |
| Third-party delivery integration (Talabat/Mrsool/Voo) | Adds external vendor, API costs, and operational coupling for ~30% of orders |

## Removed from the design (vs. prior drafts)

- Tables: `riders`, `rider_shifts`, `order_assignments`, `rider_locations`, `delivery_partners`.
- Enums: `rider_status`, `rider_kind`.
- Enum value `rider` from `actor_type`.
- Enum value `dispatcher` from `staff_role`.
- Order state `ASSIGNED_TO_RIDER`.
- `apps/rider-web` PWA (ADR-031 now lists two PWAs only).

## Kept in the design

- Table: `delivery_zones`.
- Order status `OUT_FOR_DELIVERY` (now **optional**, gated by `branch_settings.track_out_for_delivery`).
- `addresses` and `orders.address_id` for delivery destination.
- `orders.delivery_fee` for monetary breakdown.

## Consequences

- **No live rider tracking** for customers. Customer sees ETA + "On the way" only.
- **No COD reconciliation** report in the admin dashboard. Restaurant continues to reconcile cash via POS or manually.
- **No SLA breakdown** for prep vs. transit time. We can still compute total time (`placed_at` → `completed_at`); we cannot attribute the variance.
- **Two PWAs instead of three** — saves significant build, design, and ops effort.
- **Simpler order state machine** — see ADR-014.

## Re-entry conditions (when to revisit)

Consider taking ownership of rider operations later if **any** of these become true:
- Restaurant explicitly asks for a rider app, GPS tracking, or live customer maps.
- Multi-branch operations need centralised dispatch.
- COD discrepancies become a recurring finance problem.
- We start offering this product to other restaurants (then the rider feature becomes a differentiator).

At that point: a new ADR re-introduces the rider tables and one new PWA. None of today's choices block that path.

# ADR-014: Order state machine — explicit, event-sourced, simplified

**Decision**: Two state machines: **Order lifecycle** and **Payment lifecycle**, with explicit allowed transitions enforced in code. Every transition appends to `order_events` (event log). Order delivery is operated by the restaurant (see ADR-032), so the state machine carries one optional delivery-aware status only.

## Order states (simplified)

```
DRAFT → PENDING → PLACED → ACCEPTED → PREPARING → READY
                                                       │
                       takeaway ┌──────────────────┐
                                │                    │  delivery + branch tracks handoff
                                ▼                    ▼
                          COMPLETED            OUT_FOR_DELIVERY — (optional)
                            (pickup)                  │
                                                      ▼
                                                COMPLETED (delivered)

At any time before READY:
  - customer cancels  → CANCELLED_BY_CUSTOMER  → refund
  - branch cancels    → CANCELLED_BY_BRANCH    → refund
  - no-show / expired → EXPIRED                → refund
  - payment failure   → FAILED                 → (no refund needed)
```

`OUT_FOR_DELIVERY` is **optional**, set by the cashier (or the POS via Sync Agent) when the order leaves the kitchen with a rider. The branch toggles its use via `branch_settings.track_out_for_delivery`. The cloud never knows or cares which rider takes the order — that's the restaurant's POS / WhatsApp / paper process.

## Allowed transitions

```
DRAFT             → PENDING
PENDING           → PLACED | FAILED | EXPIRED
PLACED            → ACCEPTED | REJECTED | CANCELLED_BY_CUSTOMER | CANCELLED_BY_BRANCH
ACCEPTED          → PREPARING | CANCELLED_BY_BRANCH | CANCELLED_BY_CUSTOMER*
PREPARING         → READY | CANCELLED_BY_BRANCH
READY (pickup)    → COMPLETED | EXPIRED
READY (delivery) → OUT_FOR_DELIVERY | COMPLETED | CANCELLED_BY_BRANCH
OUT_FOR_DELIVERY → COMPLETED | CANCELLED_BY_BRANCH
```

`*` Customer cancel after `ACCEPTED` requires manager approval (food may already be costed).

## Payment lifecycle (unchanged)

`NONE → AUTHORIZING → AUTHORIZED → CAPTURED → REFUND_PENDING → REFUNDED | PARTIALLY_REFUNDED`
COD path: `COD_PENDING → COD_COLLECTED | COD_FAILED`.
Order moves to `PLACED` only when payment is `CAPTURED` or `COD_PENDING` is created.

## Customer-visible projection

Collapse internal states for the customer:
- *Confirming payment* → *Order placed* → *Accepted* → *Being prepared* → *Ready / On the way* → *Completed*
- Terminal: *Cancelled* / *Failed*

## Enforcement

- All transitions go through `OrderStateMachine.Transition(order, next, actor, reason)`; never `order.Status = …` directly.
- DB-level `CHECK` constraint + partial unique index on `(order_id, idempotency_key)` for replay safety.
- Optimistic locking via `orders.version`.

**Rationale**: Auditability, replay, dispute evidence, debuggability. Eliminating the rider-specific states (`ASSIGNED_TO_RIDER`) and tables keeps the cloud out of operational concerns the restaurant already handles.

**Consequences**: Branches with no need to expose "On the way" to customers can flip `track_out_for_delivery = false`; order goes `READY → COMPLETED` directly.
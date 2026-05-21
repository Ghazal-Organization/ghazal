# ADR-016: Optimistic concurrency + idempotency keys

**Decision**: orders.version for optimistic locking on transitions. Idempotency keys on order creation, payment webhooks, and agent push.

**Rationale**: Prevents double-acceptance by staff, duplicate webhooks, and retry storms.
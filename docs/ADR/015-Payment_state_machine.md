# ADR-015: Payment state machine separate from order state

**Decision**: Payment has its own states (AUTHORIZING → AUTHORIZED → CAPTURED → REFUNDED, plus COD path). Order moves to PLACED only when payment is CAPTURED or COD_PENDING created.

**Rationale**: Allows partial refunds, COD path, and gateway retries without contorting the order machine.
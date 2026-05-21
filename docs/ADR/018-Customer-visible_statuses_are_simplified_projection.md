# ADR-018: Customer-visible statuses are a simplified projection

**Decision**: Internal 13-state machine is collapsed for customer view: Confirming payment → Placed → Accepted → Preparing → Ready / On the way → Completed (+ Cancelled / Failed).

**Rationale**: Reduces cognitive load; matches industry norm.
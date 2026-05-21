# ADR-017: POS-to-Cloud status mapping is signal-based

**Decision**: Sync Agent infers cloud statuses from POS columns/events (order saved → ACCEPTED, kitchen ticket printed → PREPARING, marked served → READY, closed → COMPLETED, voided → CANCELLED_BY_BRANCH).

**Rationale**: POS has no concept of online statuses; mapping is one-way and convention-based.

**Consequences**: Mapping needs validation per POS vendor; document it in the agent config.
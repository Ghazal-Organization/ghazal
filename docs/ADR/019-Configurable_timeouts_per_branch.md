# ADR-019: Configurable timeouts per branch

**Decision**: PENDING → FAILED after 10 min; PLACED → auto-cancel if not accepted in 5 min (+alert); pickup READY → EXPIRED after 60 min; delivery alert at 2× quoted ETA.

**Rationale**: Branches vary in capacity and SLA.

**Consequences**: Need per-branch configuration UI.
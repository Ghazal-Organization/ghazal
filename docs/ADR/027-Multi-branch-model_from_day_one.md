# ADR-027: Multi-branch model from day one

**Decision**: Schema includes `branch_id` on all relevant tables. One cloud, many agents, per-branch menu overrides, delivery zones, perp times, and reports.

**Rationale**: Avoid painful retrofit if/when restaurant adds branches.

**Consequences**: Slightly more complex menu model (item base + per-branch overrides).

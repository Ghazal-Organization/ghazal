# ADR-013: Backend — ASP.NET Core modular monolith

**Decision**: Start as a modular monolith (Auth, Menu, Orders, Payments, Notifications) with clear module boundaries. Split into services only if scaling demands it.

**Rationale**: Faster to ship; simpler ops; easy to split later if module boundaries are respected.

**Consequences**: Discipline required around module dependencies.
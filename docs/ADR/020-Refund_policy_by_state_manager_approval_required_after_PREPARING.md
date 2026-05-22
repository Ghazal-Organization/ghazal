# ADR-020: Refund policy by state, manager approval required after PREPARING

**Decision**: Auto-refund 100% if cancelled at PLACED or ACCEPTED. After PREPARING, manager approval required (default 100% if branch fault, 50% if customer fault). Refunds go via Paymob API; confirmed via webhook.

**Rationale**: Fair to both customer and restaurant; clear automation boundary.
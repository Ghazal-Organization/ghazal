# ADR-006: Price re-refresh from POS at checkout

**Decision**: Online price at order submission must equal the current POS price. Re-fetch (or validate against last sync within N seconds) before payment authorisation.

**Rationale**: Customers paying online != counter price → chargebacks and refunds. Eliminates the worst failure mode of split menus.

**Consequence**: Slight checkout latency; need a refreshness threshold and a fallback if POS is unreachable.
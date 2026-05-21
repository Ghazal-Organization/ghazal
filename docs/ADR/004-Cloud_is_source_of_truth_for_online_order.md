# ADR-004: Cloud is source of truth for online orders; POS is source of truth for menu & in-store sales.

**Decision**: Online orders originates in the cloud and mirrored into POS. Menu items/prices originate in POS and are mirrored into the cloud.

**Rationale**: Single ownership per data domain prevents drift.

**Consequence**: Need two independent sync directions in the agent; clear rules per table.

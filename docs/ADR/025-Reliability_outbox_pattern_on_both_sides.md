# ADR-025: Reliability — outbox pattern on both sides

**Decision**: Cloud uses an `outbox` table for events to be pushed to the agent. Agent uses local SQLite outbox for events to be pushed to cloud. Both retry with exponential backoff.

**Rationale**: Survives network/cloud/POS outages without losing data.
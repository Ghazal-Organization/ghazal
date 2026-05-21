# ADR-012: Database — Neon Postgres in cloud; SQLite for agent outbox

**Decision**:
- **Cloud DB**: managed **PostgreSQL on Neon (Free tier)** — 0.5 GB storage, scale-to-zero compute, instant cold start, branching for dev/staging.
- **Sync Agent**: maintains its own **SQLite outbox** file locally (separate from the POS DB) for retries and crash recovery.

**Rationale**:
- PostgreSQL gives relational integrity, joins, transactions, and JSONB — needed for orders, lines, modifiers, events, payments.
- Neon Free is the best managed-Postgres free tier: no surprise pauses (unlike Supabase free after 7 days idle), instant wake from scale-to-zero, free PITR backups (7 days), and branching is ideal for cheap dev/staging copies.
- Self-hosting Postgres is rejected for MVP because we run the API on Azure Functions (no persistent host).
- SQLite agent outbox avoids any transactional coupling between cloud writes and the POS DB.

**Alternatives considered**:
- **Supabase Free** — rejected: pauses after 7 days inactive; surprise outages during pre-launch quiet periods.
- **Azure DB for PostgreSQL Flexible B1ms** — $12–15/mo; reserve for post-MVP when we outgrow Neon Free.
- **Cosmos DB Free Tier** — rejected: NoSQL is a poor fit for relational order data.
- **SQLite on Functions** — not viable: Functions Consumption has ephemeral storage.

**Consequences**:
- Need to handle Neon scale-to-zero cold-start (~300 ms) in connection pooling — use `Npgsql` with pooler endpoint.
- 0.5 GB cap = many years of headroom at 100–300 orders/day; monitor and migrate to Neon Launch ($19/mo) or Azure DB for PostgreSQL before hitting it.
- Two storage technologies (Neon Postgres + agent-local SQLite), both well-understood.
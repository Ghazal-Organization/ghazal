# ADR-029: Hosting — Azure SWA + Azure Functions + Neon + Cloudflare R2

**Decision**: Run the whole platform on a free-tier-first Azure stack with two non-Azure pieces where they clearly win.

| Layer | Service | Tier | Cost |
|---|---|---|---|
| Customer + Admin PWAs (React + Vite) | **Azure Static Web Apps** (Free) | Free | $0 |
| API (.NET 10) | **Azure Functions Consumption** (isolated worker) | Free 1M req + 400k GB-s/mo | $0 |
| Database | **Neon Free Postgres** (EU region) | 0.5 GB, branching, scale-to-zero | $0 |
| Object storage (menu images, receipts) | **Cloudflare R2** | 10 GB free + zero egress | $0 |
| Secrets | **Azure Key Vault** | ~free at low volume | ~$0 |
| Monitoring | **Application Insights** (see ADR-022) | 5 GB free / mo | $0 |
| DNS + WAF + CDN in front of API | **Cloudflare** Free | Free | $0 |
| **Fixed infra total (MVP)** | | | **~$0 / mo** |

## Rationale

- **Static Web Apps (Free)** chosen over Cloudflare Pages because:
  - Native auto-routing to **linked Azure Functions** API.
  - Built-in PR preview environments.
  - First-class **Application Insights** wiring.
  - Commercial use allowed on Free tier (unlike Vercel Hobby).
  - 100 GB / month bandwidth is more than enough for ~100–300 orders/day plus menu browsing.
- **Azure Functions Consumption** chosen over App Service F1 because:
  - F1 has no custom-domain SSL — disqualifying for Paymob and customer trust.
  - F1 has a 60 CPU-min/day hard cap that this workload would exceed.
  - F1 has a 165 MB/day outbound bandwidth cap.
  - Functions Consumption supports custom domain + free SSL, no daily caps, and the cold-start cost (2–5 s) is acceptable for an ordering site at this scale.
- **Neon Free Postgres** chosen over Supabase free or self-host:
  - Instant cold-start, branching for dev/staging, no surprise pauses.
  - Real relational DB (we need joins, transactions, aggregations — see ADR-012).
- **Cloudflare R2** chosen for object storage:
  - 10 GB free, **zero egress fees** (the killer feature vs S3/Azure Blob/Cloudinary).
- Commercial-friendly platforms throughout; no surprise ToS issues (Vercel Hobby ruled out).

## Alternatives considered

- **Hetzner VPS (~$5/mo)** running everything in Docker — best $/perf, no cold starts, but requires ops (patches, backups, monitoring). Use later if cold starts or limits become a problem.
- **Vercel Hobby** — rejected: forbids commercial use.
- **App Service F1** — rejected: no custom-domain SSL + CPU/day cap + bandwidth cap.
- **Cosmos DB Free Tier** — rejected: NoSQL is a poor fit for relational order data.
- **Cloudflare Pages** — strong alternative; would be picked if the API were on Workers, not Functions.

## Consequences

- Cold-start latency on the API (2–5 s after idle). Mitigation: an off-peak warm-up timer trigger keeps a worker warm during business hours.
- Free tiers can change — set a budget alert and review quarterly.
- One Azure region only (UAE North preferred; West Europe fallback). For HA, upgrade later.
- Migration path when traffic grows:
  1. SWA Free → SWA Standard ($9/mo).
  2. Functions Consumption → Functions Premium (no cold starts).
  3. Neon Free → Neon Launch ($19/mo) or Azure DB for PostgreSQL.
  4. Or move the API to a VPS / App Service B1 if cold starts become a UX issue.

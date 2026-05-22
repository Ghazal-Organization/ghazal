# ADR-030: Backend API platform — Azure Functions Consumption (not App Service F1)

**Decision**: Host the API as **Azure Functions Consumption** (.NET 10 isolated worker), with custom domain + free SSL, integrated as the **linked API** of the Static Web App (see ADR-031).

## Why not App Service F1

| Constraint | F1 | Functions Consumption |
|---|---|---|
| Custom-domain SSL | ❌ Not supported (only `*.azurewebsites.net`) | ✅ Free managed cert |
| CPU / day cap | 60 CPU-min / day hard cap | None |
| Outbound bandwidth | 165 MB / day | No daily cap |
| Sleep behaviour | Idle after 20 min — keep-alive ping works for sleep but doesn't unlock CPU/bandwidth caps | Cold-start 2–5 s after idle |
| Memory | 1 GB | 1.5 GB |
| Free tier req allowance | n/a (always-on while quota lasts) | 1M requests + 400k GB-s / month |

F1's lack of custom-domain SSL alone disqualifies it: Kashier callbacks and customer trust require `api.ghazal.example` on HTTPS.

## Why Functions Consumption fits

- Custom domain + free SSL.
- No daily CPU or bandwidth caps.
- 1M req/mo is ~10× our projected MVP traffic.
- Tight wiring to **Azure Static Web Apps** (no CORS, single auth/route layer via `staticwebapp.config.json`).
- Native **Application Insights** integration.
- Scales to zero — cost stays $0 on quiet days.

## Cold-start mitigation

- 2–5 s cold-start on first request after idle is acceptable for an ordering site (rare event).
- For staff dashboard responsiveness during business hours, deploy a small **timer-triggered warm-up function** that pings the orders endpoint every 4 min between 10:00 and 02:00 (branch hours). Stays inside free tier.

## Programming model

- ASP.NET Core flavoured **.NET 10 isolated worker** for Functions.
- Use **HTTP-triggered functions** for REST endpoints; **timer-triggered** for scheduled jobs (reconciliation, warm-up); **queue-triggered** (Azure Storage Queue, free tier) for background work (notifications, image processing).
- Keep modular monolith structure inside the Functions project (Auth / Menu / Orders / Payments / Notifications modules — see ADR-013).

## Alternatives considered

- **App Service B1** (~$13/mo) — best DX (regular ASP.NET Core, no cold starts) but breaks the $0 MVP budget.
- **Hetzner / Contabo VPS** (~$5/mo) — even cheaper than B1, fully owned, but adds ops burden; keep as the documented migration target if Functions limits or cold starts become painful.
- **Cloudflare Workers** — fast and free but not .NET; would require rewriting in TypeScript.

## Consequences

- Architecture must be cold-start aware: keep startup light (no heavy DI, no eager EF migrations on startup).
- Use **`Npgsql` connection pooler** to Neon to avoid connection-storm on warm-up.
- Budget alert at $5/mo on the Functions app.
- Migration path: Consumption → **Functions Premium** (no cold starts, ~$160/mo) only when cold starts become a measured UX issue.

# ADR-031: Frontend hosting — Azure Static Web Apps (not Cloudflare Pages, not Vercel)

**Decision**: Host the two React + Vite PWAs (customer ordering, admin dashboard) on **Azure Static Web Apps (Free)**, linked to the Azure Functions API (see ADR-030).

## Comparison

| Feature | Azure Static Web Apps (Free) | Cloudflare Pages (Free) | Vercel Hobby |
|---|---|---|---|
| Commercial use | ✅ Allowed | ✅ Allowed | ❌ Personal/non-commercial only |
| Cost | $0 | $0 | $0 (but ToS-blocked here) |
| Custom domain + free SSL | ✅ (2 domains) | ✅ Unlimited | ✅ |
| Bandwidth | 100 GB / mo | Unlimited | 100 GB / mo |
| PR preview environments | ✅ (3 envs) | ✅ Unlimited | ✅ |
| Native API binding | ✅ **Linked Azure Functions** (no CORS, single domain via `staticwebapp.config.json`) | Workers (different runtime, not .NET) | Serverless Functions (Node only) |
| Built-in auth providers | ✅ (Microsoft, GitHub, custom OIDC) | DIY | DIY |
| Monitoring integration | ✅ **Application Insights** out-of-the-box | Cloudflare Web Analytics (separate) | Vercel Analytics (paid for full data) |
| Global CDN | Azure CDN (fewer PoPs) | Cloudflare (~300 PoPs incl. Cairo) | Vercel Edge Network |
| Latency to Egypt | ~30–60 ms | ~5–15 ms | ~30–60 ms |
| Build runtime | 100 GB-s build budget | 500 builds / mo | 6,000 build-min / mo |
| Lock-in | Higher (Azure ecosystem) | Low | Medium |

## Why Azure SWA wins for Ghazal

Given the rest of the stack is **Azure Functions + Application Insights**:

1. **Linked API integration** — `/api/*` routes proxy directly to the linked Functions app on the same domain, eliminating CORS and simplifying auth cookies.
2. **One App Insights resource** captures frontend + API + traces with correlated end-to-end transactions.
3. **PR preview environments** spin up a temporary SWA + Functions pair for every pull request — great for review and QA.
4. **Built-in auth slots** (configurable in `staticwebapp.config.json`) save us building OIDC plumbing for the admin dashboard.
5. **Commercial use allowed** on the Free tier (Vercel Hobby forbids it).
6. 100 GB / month bandwidth is well above our projected ~10–20 GB / month.

## Why not Cloudflare Pages

- Cloudflare Pages would be the right pick if the API ran on Cloudflare Workers. It doesn't.
- Pages + Azure Functions loses the linked-API magic (manual CORS, two domains, separate monitoring stacks).
- We'd give up SWA's built-in PR previews and auth providers.
- Cloudflare's PoP advantage matters less when the API itself sits in Azure UAE North.

## Why not Vercel

- **Vercel Hobby is non-commercial per ToS** — using it for a paying restaurant business is a license violation.
- Vercel Pro is $20/user/month — breaks the $0 MVP budget.

## Repository / build model

- **Single monorepo** (pnpm workspaces) with two apps:
  - `apps/customer-web` — public ordering PWA
  - `apps/admin-web` — staff dashboard (manager + cashier views)
- Two separate SWA resources, one per app, each linked to the same Functions backend.
- CI: GitHub Actions runs `pnpm build --filter <app>` and deploys to the matching SWA via the official `Azure/static-web-apps-deploy@v1` action.

## Consequences

- Frontend builds happen in GitHub Actions (free for public repos; 2,000 min/mo for private). SWA Free has no inbound CI/CD restrictions either way.
- One Azure subscription holds two SWA resources + one Functions app — easy to tag and bill together.
- Migration path: SWA Free → **SWA Standard** ($9/app/mo) when we need more than 2 custom domains, larger app size, or dedicated SLA. Or move to Cloudflare Pages if the API moves off Azure.
- A rider PWA is **out of scope** (ADR-032 — restaurant owns delivery operations); add later only if we take ownership of rider dispatch.

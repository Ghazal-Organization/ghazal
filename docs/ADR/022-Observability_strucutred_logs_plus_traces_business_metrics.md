# ADR-022: Observability — Application Insights

**Decision**: Use **Azure Application Insights** (Free tier, 5 GB/month ingestion) for logs, traces, metrics, and alerts across the whole platform.

- **API (Azure Functions)**: native App Insights integration via the Functions host — auto-collects requests, dependencies, exceptions, traces, performance counters.
- **Frontends (Azure Static Web Apps)**: App Insights JavaScript SDK for page views, route changes, JS exceptions, and custom events (add-to-cart, checkout-started, payment-completed).
- **Sync Agent (.NET Worker on POS PC)**: App Insights .NET SDK over HTTPS to the same instance, tagged with `branchId` and `agentVersion`.
- **Correlation**: one **trace ID per order** propagated across customer browser → API → Functions → Paymob webhook → Sync Agent → POS. Use W3C Trace Context headers (`traceparent`).

**Business metrics to track**:
- Orders / hour, orders / day per branch and per channel (takeaway, delivery).
- Payment success / failure / refund rates (per Paymob method, COD vs cards).
- Sync Agent heartbeat (alert if no heartbeat for > 2 min during business hours).
- Sync lag (cloud → POS write latency, POS → cloud status push latency).
- Customer journey funnel: menu view → cart → checkout → payment → placed.

**Alerts (start small, tune later)**:
- API error rate > 2% over 5 min.
- Payment webhook failures > 3 in 10 min.
- Sync Agent offline > 5 min during open hours.
- Failed deliveries (`OUT_FOR_DELIVERY` > 2× quoted ETA).

**Rationale**:
- App Insights Free tier (5 GB/mo) is more than enough for ~100–300 orders/day.
- Tight integration with Azure Functions and SWA (one-click wiring, no extra cost).
- KQL queries in Log Analytics are powerful for ad-hoc business questions.
- Cross-system debugging is impossible without correlation IDs — App Insights' end-to-end transaction view gives this for free.

**Alternatives considered**:
- **Sentry + Logtail + Grafana stack** — would be picked on a non-Azure stack (VPS); rejected here because App Insights is free, native, and zero-config inside the chosen Azure platform.
- **Self-hosted Netdata / Prometheus** — overkill for MVP scale; consider only after migrating off Functions.

**Consequences**:
- Sampling rules required to stay under 5 GB/mo when traffic grows (sample successful health checks aggressively; keep all errors).
- Cost alert at $5/mo on the App Insights resource — overage is paid (~$2.30/GB after free tier).
- Set 30–90 day retention; export older data to Blob storage for long-term.
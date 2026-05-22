# ADR-009: Webhook is the source of truth for payment status; redirect is never trusted alone.

**Decision**: Verify the HMAC-signed Paymob transaction webhook on a server endpoint. The redirect URL only triggers UI; order state changes occur **only** on webhook confirmation (with idempotency).

**Rationale**: Redirects can be tampered with, missed, or duplicated. Webhooks are signed by Paymob (HMAC) and replayed on failure, so they are the reliable source of truth.

**Consequence**: Webhook endpoint must be public HTTPS, idempotent, with replay protection (`processed_webhooks` table keyed on Paymob's transaction id), and signature verification on every request.
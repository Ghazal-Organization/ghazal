# ADR-009: Webhook is the source of truth for payment status; redirect is never trusted alone.

**Decision**: Verify HMAC-signed Kashier webhook on a server endpoint. The redict URL only triggers UI; order state changes only on webhook confirmation (with idempotency).

**Raltionale**: Redirects can be tampered with, missed, or duplicated. Webhooks are signed and reliable.

**Consequence**: Webhook endpoint must be public HTTPS, idempotent, with replay protection (`processed_webhook_ids`).
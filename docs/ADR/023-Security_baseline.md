# ADR-023: Security baseline

**Decision**:
- HTTPS everywhere, TLS 1.2+.
- JWT short TTL + refresh token rotation.
- HMAC signature verification on Paymob webhooks.
- Per-branch signed JWT for Sync Agent → cloud.
- Secrets in Azure Key Vault / AWS Secrets Manager — never in .env in git.
- Least-privilege DB users (agent reads with restricted account).
- No PAN stored anywhere; rely on Paymob tokenisation.
- Mask sensitive fields in logs.

**Rationale**: OWASP baseline + PCI SAQ-A scope.
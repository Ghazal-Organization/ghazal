# ADR-007: Payment gateway — Paymob + Cash on Delivery (COD)

**Status**: Accepted. Supersedes the earlier choice of Kashier.

**Decision**: Primary online gateway is **Paymob** (cards, Meeza, mobile wallets, Apple Pay / Google Pay). **COD** is a first-class payment method alongside it.

**Rationale**:
- Paymob is the most widely used Egyptian gateway, with the broadest method coverage out of the box (cards, Meeza, Vodafone Cash and other wallets, Apple Pay, Google Pay) under a single merchant account.
- Mature hosted-checkout flow (Unified Checkout / iframe) — see [ADR-008](008-Hosted_Payment_Page_(HPP)_integration_mode_for_Paymob.md).
- HMAC-signed transaction callbacks (the "HMAC" / `processed` webhook) give us a reliable source of truth — see [ADR-009](009-Webhook_is_the_source_of_truth_for_payment_status.md).
- A **test-mode merchant account** is already provisioned and credentials are in hand, so we can integrate immediately without onboarding delay.
- COD remains a first-class method because it is still ~50%+ of EG online orders.

**Alternatives considered**:
- **Kashier** — clean API and modern HPP, but narrower default method coverage in EG and onboarding paperwork would block integration. Dropped in favour of Paymob.
- **Stripe / international gateways** — poor local-method coverage (no Meeza, no Vodafone Cash). Not viable for the EG SMB market.

**Consequence**:
- Need a `PaymentProvider` abstraction so the order flow does not depend on Paymob specifics, leaving the door open to a second provider later without refactoring orders.
- Webhook handler is built around Paymob's HMAC scheme; any future provider must plug into the same signature-verification + idempotency contract.
- Paymob credentials (HMAC secret, API key, integration IDs) live in the secret store — never in source — and have separate values per environment (`test`, `live`).
 
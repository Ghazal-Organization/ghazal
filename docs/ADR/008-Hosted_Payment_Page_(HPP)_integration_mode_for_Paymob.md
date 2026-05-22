# ADR-008: Hosted Payment Page (HPP) integration mode for Paymob

**Status**: Accepted. Aligned with [ADR-007](007-Payment_Gateway_Paymob_and_COD.md).

**Decision**: Use Paymob's **hosted payment page** (Unified Checkout redirect, or the iframe variant where UX requires it). Do **not** capture card data directly via the API.

**Rationale**:
- Keeps our PCI scope at **SAQ-A** (the lowest). Cardholder data never touches our servers, our SWAs, or our logs.
- Paymob handles the full card-entry UI, 3-D Secure challenge, and Apple Pay / Google Pay sheets.
- Same hosted flow covers cards, Meeza, and the supported wallets — one integration, multiple methods.

**Alternatives considered**:
- **Direct API card capture** — would put us in SAQ-D scope (full PCI DSS). Rejected: cost, audit burden, and risk far exceed the marginal UX gain.
- **Tokenised "headless" checkout via Paymob.js** — keeps SAQ-A but adds front-end complexity for no MVP benefit. Revisit post-pilot if conversion data justifies it.

**Consequences**:
- Slight UX cost: customer is redirected (or sees an iframe) instead of a fully native form. Acceptable trade-off for MVP.
- Front-end never holds PAN, CVV, or expiry. Saved cards are not in scope for MVP (see [docs/customer/wireframes.md](../customer/wireframes.md) — "Saved payment methods" is out of scope).
- Server flow: create order → request Paymob payment key → redirect customer to HPP → wait for **webhook** (not the redirect) to confirm — see [ADR-009](009-Webhook_is_the_source_of_truth_for_payment_status.md).
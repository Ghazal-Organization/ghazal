# ADR-007: Payment gateway — Kashier + Cash on Delivery (COD)

**Decision**: Primary gateway is Kashier (cards, Meeza, wallets). COD is a first-class payment method.

**Rationale**: Kashier has clean API, modern hosted checkout, competitive Egyptian SMB pricing. COD is still ~50%+ of EG orders.

**Alternatives**: Paymob (broader plugin ecosystem, but heavier).

**Consequence**: Need `PaymentProvider` abstraction to allow future providers without refactoring orders.
 
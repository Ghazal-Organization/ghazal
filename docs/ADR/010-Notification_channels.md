# ADR-010: Notification channels — SMS only (MVP)

**Decision**: For MVP, send all customer-facing notifications via **SMS only**, through the cheapest Egyptian bulk provider (MSEGAT / Victory Link / Yamamah / SMSMisr — pick by EGP per message, must support Arabic Unicode and NTRA-approved sender ID). All channels live behind a single `NotificationService` abstraction with provider adapters so we can add more later.

- **In MVP**: SMS (OTP + order status: placed, accepted, ready / out-for-delivery, completed, cancelled).
- **Deferred (phase 2)**: WhatsApp (Meta Cloud API), Email (SendGrid free tier), Push (FCM).

**Rationale**: SMS has the widest reach in Egypt, works on every phone, and avoids the long Meta template approval cycle. WhatsApp/email/push add complexity without clear MVP value for a single-restaurant pilot.

**Consequences**:
- Start NTRA sender-ID approval immediately (2–6 weeks lead time).
- Build `SmsProvider` adapter first; keep `WhatsAppProvider`, `EmailProvider`, `PushProvider` interfaces stubbed for later.
- Consider Firebase Phone Auth (free quota) as Plan B for OTP while bulk SMS sender ID is pending.
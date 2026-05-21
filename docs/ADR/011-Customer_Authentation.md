# ADR-011: Customer Authentication via phone OTP

Shortlist (price per SMS varies, negotiate by volume): MSEGAT, Victory Link, Yamamah, SMSMisr, GSMA / 4Jawaly.

**Decision rule**: pick the lowest EGP/SMS that supports Arabic Unicode and has a documented HTTP/REST API + NTRA-approved sender ID path.
Start NTRA sender-ID approval immediately (2–6 weeks).
Keep one provider as primary, build the SmsProvider adapter so we can swap.
For OTP only, Firebase Phone Auth is free up to a quota and bypasses sender-ID hassle — consider it as a Plan B for OTP while bulk transactional SMS goes through the EG provider.
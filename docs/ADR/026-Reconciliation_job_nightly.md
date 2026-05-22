# ADR-026: Reconcilition job nightly

**Decision**: Nightly batch compares cloud orders ↔ POS records ↔ Paymob settlement report. Mismatches emailed to manager.

**Rationale**: Catches silent integration failures and finance discrepancies early.
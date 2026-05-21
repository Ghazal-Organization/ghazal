ADR-008: Hosted Payment Page (HPP) integration mode for Kashier
Decision: Use Kashier's Hosted Payment Page (redirect or iframe), not direct API card capture.

Rationale: Keeps PCI scope at SAQ-A (lowest). Never touch PAN data.

Consequences: Slight UX cost (redirect/iframe vs native form). Acceptable trade-off.
# ADR-005: Menu split — POS owns "what exists & price", "Cloud owns "how it's presented"

**Decision**:
- POS owns: SKU, name, price, tax, modifiers, availability/86 flag.
- Cloud owns: images, long descriptions (AR/EN), tags, allergens, "featured", online prep time, `is_online_visible`, online-only combos, banners.
- Linked by `pos_external_id` (SKU).

**Rationale**: Avoid double data entry, price drift, and stock mismatches while letting marketing manage presentation independently.
Rejected: fully separated menus (operational nightmare); cloud-as-source pushing to POS (most POS systems lack write APIs)

**Consequence**: Need "Menu Health" admin screen; placeholder strategy for items without images.

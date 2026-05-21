# ADR-033: Admin & customer design system — shadcn/ui + Radix + Tailwind

**Status**: Accepted (2026-05-22)

## Decision

Adopt **shadcn/ui** (components copied into the repo) on top of **Radix UI primitives** and **Tailwind CSS** as the single design system shared between the customer PWA and the admin PWA. Componentry under `packages/ui/`; theming via CSS variables; two presets:

- `brand-warm` — customer-facing (saffron/flame, restaurant warmth).
- `brand-neutral` — admin-facing (dense, neutral surfaces, brand accents only on status pills and primary actions).

Supporting libraries:

- **TanStack Table** — headless data tables (orders, items, reports).
- **Recharts** — charts (daily reports).
- **React Hook Form + Zod** — forms + validation.
- **react-day-picker** — date pickers (matches shadcn).
- **`tailwindcss-rtl` plugin** — automatic logical RTL flipping for AR locale.
- **`@tabler/icons-react`** or **`lucide-react`** — icons (lucide ships with shadcn).

## Rationale

- Matches existing Tailwind decision (ADR-014). One styling engine, no Emotion/Griffel parasites.
- Components are copied into the repo — we own them. Easy to fix RTL quirks, add Arabic typography rules, and avoid breaking-version-upgrade pain.
- Radix primitives are accessible by default (focus traps, ARIA, keyboard) and expose `data-state` attributes — Playwright + Testing Library tests get stable selectors for free.
- shadcn theme tokens (CSS variables) drive both apps from one source. Customer warm, admin neutral, same primitives underneath.
- Headless tables + custom Tailwind density utility let the admin be Notion/Vercel-dense without losing accessibility.

## Rejected alternatives

- **Material 3 / MUI**, **IBM Carbon**, **Microsoft Fluent UI v9** — heavy CSS-in-JS engines that fight Tailwind; off-brand for a warm restaurant.
- **Ant Design** — best data tables in the industry but very loud visual style, hard to tone down.
- **Mantine** — clean DX, but introduces a parallel CSS-in-JS layer next to Tailwind.
- **Tailwind UI / Catalyst** — beautiful but ~$299 licence; not necessary when shadcn covers 90%.

## Brand tokens (derived from the Ghazal logo)

The logo (flame, gazelle calligraphy, red ground, green leaf accent) maps to:

```css
/* packages/ui/src/styles/tokens.css */
:root {
  /* Brand */
  --brand-flame:   24  92% 50%;  /* hsl — orange flame */
  --brand-red:     0   72% 42%;  /* deep restaurant red */
  --brand-leaf:    140 55% 38%;  /* green accent */
  --brand-charcoal:0   0%  10%;  /* near-black */
  --brand-cream:   36  35% 96%;  /* warm off-white */

  /* shadcn semantic tokens — admin (brand-neutral preset) */
  --background:    0   0%  100%;
  --foreground:    var(--brand-charcoal);
  --muted:         0   0%  96%;
  --muted-fg:      0   0%  40%;
  --card:          0   0%  100%;
  --card-fg:       var(--brand-charcoal);
  --border:        0   0%  90%;
  --input:         var(--border);
  --ring:          var(--brand-flame);

  --primary:       var(--brand-flame);   /* primary CTAs */
  --primary-fg:    0   0%  100%;
  --destructive:   0   72% 42%;          /* brand red doubles as danger */
  --destructive-fg:0   0%  100%;
  --success:       var(--brand-leaf);
  --warning:       38  92% 50%;

  /* Density (admin) */
  --space-unit:    4px;     /* base */
  --row-height:    32px;    /* compact rows */
  --control-h-sm:  28px;
  --control-h-md:  32px;
  --control-h-lg:  40px;
  --radius:        6px;     /* slightly tighter than shadcn default */
  --font-mono:     "JetBrains Mono", ui-monospace;
  --font-sans:     "Inter", "IBM Plex Sans Arabic", system-ui;
}

[dir="rtl"] {
  --font-sans: "IBM Plex Sans Arabic", "Inter", system-ui;
}

.theme-brand-warm {
  /* Customer-facing overrides: more contrast, larger radii, warm bg */
  --background: var(--brand-cream);
  --radius: 12px;
  --primary: var(--brand-flame);
}
```

## Density rules (admin)

- Default row height **32 px**; toggle to 40 px ("comfortable") in settings.
- Default form control height **32 px**.
- Sidebar **56 px collapsed / 240 px expanded**.
- Page padding `12px 16px`, card padding `12px 16px`.
- Tables: zebra off; 1 px hairline borders; sticky header.
- Type scale (admin): 12 / 13 / 14 / 16 / 20. Numbers use `font-mono` in tables and totals.

## Accessibility & RTL

- All interactive elements: keyboard navigable, visible `:focus-visible` ring (uses `--ring` token).
- Colour contrast ≥ WCAG AA. Status pills must not rely on colour alone — every pill carries an icon + text.
- AR layout: set `dir="rtl"` on `<html>`; Tailwind `rtl:` variants for any directional utility; logical properties (`ms-*` / `me-*`) over `ml-*` / `mr-*`.
- Numbers stay LTR in AR ("12:30", "150.00 ج.م.").
- Dates: format with the user's locale (`Intl.DateTimeFormat`).

## Consequences

- One CSS pipeline, easy to test, easy to brand.
- Some primitives we'll build ourselves (kanban column, status pill, money cell) — small one-time cost.
- Component snapshot tests are cheap and stable thanks to Radix `data-state` attributes.

## Migration path

When the customer brand evolves, only `tokens.css` changes — components don't. If we ever need to add a third app (rider PWA later, or a public marketing site), it picks the `brand-warm` preset and inherits everything.

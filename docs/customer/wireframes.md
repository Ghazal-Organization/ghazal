# Ghazal — Customer PWA Wireframes (v1)

**Last updated**: 2026-05-22
**Design system**: shadcn/ui + Radix + Tailwind ([ADR-033](../ADR/033-Design_system_shadcn.md))
**Theme preset**: `brand-warm` — cream background, flame orange primary, leaf success, deep red for warnings
**Density**: comfortable (44px touch targets, 12 px radii, larger type)
**Direction**: **AR (RTL) default**, EN toggle
**Form factor**: **mobile-first** (~375 px), responsive up to desktop

Mobile-first because that's how 95%+ of EG customers will order. Desktop variants are noted per screen but secondary.

Legend (same as admin):
- `[Button]` = primary  · `‹Button›` = secondary  · `▢` = checkbox  · `○ ●` = radio
- `▼` = select  · `🔍` = search  · `🛒` = cart  · `📍` = location
- `▒▒▒` = image placeholder · `─` = divider

These wireframes are drawn **LTR** for legibility. Real layout mirrors for AR. Numerals stay LTR (`12:30`, `285.00 ج.م`).

---

## 0. Information architecture

```
Public (no auth required to browse or build cart)
├─ Landing                      (branch list or auto-pick if one)
├─ Branch home / menu           (categories + items)
├─ Item detail
├─ Search (overlay)
└─ Cart

Auth-gated (only at checkout / history)
├─ OTP login (phone)
├─ Checkout
│  ├─ Channel + address
│  ├─ Payment
│  └─ Confirmation
├─ Order tracking (live)
├─ Order history
└─ Profile
   ├─ Addresses
   └─ Language
```

Auth model: customer **does not** need to log in to browse or build a cart. OTP appears at checkout submit only. Lowers friction.

---

## 1. App shell — mobile

```
┌──────────────────────────────┐
│   ▒▒▒ Ghazal logo ▒▒▒   AR ▾ │  ← sticky header (50 px)
├──────────────────────────────┤
│                              │
│      <screen content>        │
│                              │
│                              │
│                              │
│                              │
├──────────────────────────────┤
│  🏠     🍽     🛒(3)    👤   │  ← bottom nav (60 px)
│ Home   Menu   Cart    Me     │
└──────────────────────────────┘
```

- Header: brand mark on the leading edge, language toggle on the trailing edge. Becomes a back button on subpages.
- Bottom nav: 4 tabs. Cart badge appears when cart > 0.
- Floating "View cart · 3 items · 245 ج" bar slides up above the nav when cart > 0 and not on the cart screen.

Desktop ≥ 768 px: nav becomes a left rail; menu uses a 2-column grid; cart sits as a right-side panel.

---

## 2. Landing — branch picker

If there's only **one** active branch, skip this entirely; auto-route to its menu.

```
┌──────────────────────────────┐
│   ▒▒▒ Ghazal logo ▒▒▒   AR ▾ │
├──────────────────────────────┤
│                              │
│ اطلب من أقرب فرع              │
│ Order from your nearest      │
│ branch                       │
│                              │
│ ┌──────────────────────────┐ │
│ │ 📍 المحلة الكبرى          │ │
│ │ شارع شكري القوتلي         │ │
│ │ 🟢 مفتوح · 25 دقيقة تحضير │ │
│ │                          │ │
│ │      [ تصفح القائمة ]    │ │
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ 📍 طنطا (قريباً)          │ │
│ │ 🔴 مغلق                  │ │
│ └──────────────────────────┘ │
│                              │
└──────────────────────────────┘
```

Each branch card shows: name, address, open/closed badge, default prep time, big CTA. Closed branches are disabled with a clear reason.

---

## 3. Menu — branch home

```
┌──────────────────────────────┐
│  ← المحلة الكبرى    AR ▾ 🔍   │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │  ▒▒▒  Hero / promo  ▒▒▒  │ │  ← optional, can be empty
│ │  Free home delivery      │ │
│ └──────────────────────────┘ │
│                              │
│ [بيتزا][كريب][فطائر][مشروبات]│  ← category chips, sticky on scroll
│  ───                         │     (active chip underlined)
│                              │
│ بيتزا · Pizza                 │
│ ┌────────────────────────┐   │
│ │ ▒▒▒  Margherita 85 ج.م │   │
│ │ ▒▒▒  ──────────        │   │
│ │ ▒▒▒  Tomato, mozzarella│   │
│ │       basil            │   │
│ │       [ + Add ]        │   │
│ └────────────────────────┘   │
│                              │
│ ┌────────────────────────┐   │
│ │ ▒▒▒ Pepperoni  95 ج.م  │   │
│ │ ▒▒▒  ──────────        │   │
│ │ ▒▒▒  …                 │   │
│ └────────────────────────┘   │
│                              │
│ كريب · Crepe                  │
│ ...                          │
│                              │
├──────────────────────────────┤
│      🛒  3 · 245.00 ج         │  ← sticky cart bar (only when cart > 0)
├──────────────────────────────┤
│  🏠    🍽    🛒(3)    👤      │
└──────────────────────────────┘
```

Behaviour:
- Category chips scroll horizontally; tapping one smooth-scrolls to that section AND highlights the chip.
- Item cards: large photo on the leading edge (or a branded category placeholder if no image — per ADR-005), price on the trailing edge.
- **Out-of-stock / 86'd** items: greyed out, "غير متاح" label, `+ Add` button hidden.
- **Hidden online** items: not rendered (server filters).
- Each card tap → item detail screen. The `+ Add` shortcut adds with default modifiers when there are no required modifiers.
- Cart bar tap → cart screen.
- Pull-to-refresh on the menu re-fetches branch open status + availability (a single light endpoint).

PWA detail:
- Menu HTML + thumbnails cached in service worker; cold load < 1.5 s on 3G.
- Stock/availability is fetched fresh on focus so customers don't add 86'd items.

---

## 4. Search overlay

```
┌──────────────────────────────┐
│  ←  🔍 [ شاورما___________ ] ✕│
├──────────────────────────────┤
│ نتائج البحث                   │
│                              │
│ ┌────────────────────────┐   │
│ │ ▒▒▒  شاورما لحم  65 ج │   │
│ └────────────────────────┘   │
│ ┌────────────────────────┐   │
│ │ ▒▒▒  شاورما فراخ 55 ج │   │
│ └────────────────────────┘   │
│                              │
│ ─ لم تجد ما تريد؟             │
│ جرب: شوارمه، شاوارما           │
└──────────────────────────────┘
```

- Full-screen overlay on mobile, slide-down panel on desktop.
- Typo-tolerant via `pg_trgm` (ADR-007 schema).
- Empty-result state suggests close matches (server returns suggestions when score < threshold).

---

## 5. Item detail

```
┌──────────────────────────────┐
│  ←                       ❤   │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ ▒▒▒                      │ │
│ │ ▒▒▒    big photo         │ │   ← swipe for more photos
│ │ ▒▒▒    (or placeholder)  │ │   ← dots indicator
│ │ ▒▒▒                      │ │
│ └──────────────────────────┘ │
│ ● ○ ○                        │
├──────────────────────────────┤
│ Margherita Pizza         85 ج│
│ بيتزا مارجريتا                 │
│                              │
│ صلصة طماطم، جبنة موزاريلا،     │
│ ريحان طازج                    │
│                              │
│ 🌱 Vegetarian   ⏱ ~18 min    │
├──────────────────────────────┤
│ Choose size  (required)       │
│   ●  Medium               +0 │
│   ○  Large               +30 │
│                              │
│ Extras  (up to 3, optional)   │
│   ▢  Extra cheese        +15 │
│   ▢  Olives              +10 │
│   ▢  Mushrooms           +10 │
│                              │
│ Notes (optional)              │
│ [ مثلاً: قشطة زيادة، استواء…  ]│
├──────────────────────────────┤
│  – 1 +              Total 85 │
│      [  Add to cart  ]       │
└──────────────────────────────┘
```

- Sticky footer with qty stepper, live total, and primary CTA.
- Modifier groups respect `min_select` and `max_select`. Required groups marked.
- Allergen icons inline; full allergen list on tap of an info ⓘ.
- Bilingual: title shows EN over AR; description in user's preferred lang first.
- "Add to cart" pushes user back to menu with a brief toast and updates the cart bar.

---

## 6. Cart

```
┌──────────────────────────────┐
│  ← Your cart                  │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ ▒  1× Margherita    85 ج │ │
│ │    + Extra cheese    +15 │ │
│ │    [- 1 +]      🗑       │ │
│ ├──────────────────────────┤ │
│ │ ▒  2× Chicken Crepe 130 ج│ │
│ │    note: well done       │ │
│ │    [- 2 +]      🗑       │ │
│ ├──────────────────────────┤ │
│ │ ▒  1× Cola 330ml     15 ج│ │
│ │    [- 1 +]      🗑       │ │
│ └──────────────────────────┘ │
│                              │
│ Have a note for the kitchen? │
│ [                          ] │
│                              │
│ ──────────────────────────── │
│ Subtotal             245.00 ج│
│ Delivery fee         set at  │
│                      checkout│
│ ──────────────────────────── │
├──────────────────────────────┤
│  [    Proceed to checkout  ] │
└──────────────────────────────┘
```

- Empty state: warm illustration + "تصفح القائمة" CTA.
- Removing the last item collapses the cart to the empty state.
- "Proceed" → checkout step 1 (channel + address). Customer is NOT asked to log in yet — they pick channel first; OTP comes at payment.

---

## 7. Checkout — step 1 (channel + address)

```
┌──────────────────────────────┐
│  ←  Checkout 1/3              │
├──────────────────────────────┤
│ How do you want it?           │
│                              │
│  ┌──────────┐ ┌──────────┐   │
│  │ 🥡 Take  │ │ 🚚 Delivery   │  ← segmented buttons (large)
│  │ away     │ │              │   │
│  └──────────┘ └──────────┘   │
│  ── ‹selected›                │
│                              │
│ (if delivery)                 │
│ Deliver to                    │
│ ┌──────────────────────────┐ │
│ │ ● Home                   │ │
│ │   شارع شكري، الطابق 3     │ │
│ │   landmark: pharmacy     │ │
│ │   📍 verified in zone    │ │
│ ├──────────────────────────┤ │
│ │ ○ Work                   │ │
│ │   شركة المهدي…            │ │
│ │   ⚠ outside delivery area│ │
│ └──────────────────────────┘ │
│ [ + Add new address ]         │
│                              │
│ When?                         │
│   ●  As soon as possible     │
│   ○  Schedule for later (—)  │
│                              │
├──────────────────────────────┤
│           [  Continue  ]      │
└──────────────────────────────┘
```

- Takeaway hides the address picker; the pickup branch is shown instead.
- Each address is validated against `delivery_zones`; out-of-zone addresses are visibly flagged and not selectable.
- "Schedule for later" is **disabled** in v1 (ADR/MVP scope) — kept visible with a tooltip "coming soon" so the design seat is reserved without misleading.

### 7a. Add new address (drawer)

```
┌──────────────────────────────┐
│  Add address              ✕  │
├──────────────────────────────┤
│ Label   ▼ Home                │
│ Line 1  [ شارع شكري القوتلي  ]│
│ Line 2  [                   ] │
│ City    ▼ El-Mahalla El-Kubra │
│ Landmark [ مجاور صيدلية…   ]  │
│                              │
│ Find on map                   │
│ ┌──────────────────────────┐ │
│ │   📍 (map placeholder)   │ │
│ │       drag pin           │ │
│ └──────────────────────────┘ │
│                              │
│ 🟢 Inside delivery area       │
│    Zone: المهدي · 20.00 ج     │
│                              │
│           [ Save address ]    │
└──────────────────────────────┘
```

- Use the browser geolocation if permitted to pre-position the pin.
- The "inside zone" status updates live as the pin moves. If red, the Save button is enabled (the address still saves) but it will be unselectable for delivery orders until they edit.

---

## 8. Checkout — step 2 (payment)

```
┌──────────────────────────────┐
│  ←  Checkout 2/3              │
├──────────────────────────────┤
│ Pay how?                      │
│                              │
│ ┌──────────────────────────┐ │
│ │ ●  💳  Card / wallet     │ │
│ │    Visa, Mastercard,     │ │
│ │    Meeza, Vodafone Cash  │ │
│ │    Powered by Kashier    │ │
│ ├──────────────────────────┤ │
│ │ ○  💵  Cash on delivery  │ │
│ │    Pay when it arrives   │ │
│ └──────────────────────────┘ │
│                              │
│ ── Order summary ──           │
│ Subtotal             245.00 ج│
│ Delivery fee          20.00 ج│
│ VAT                   20.00 ج│
│ ──────────────────────────── │
│ Total                285.00 ج│
│                              │
│ By placing this order you    │
│ agree to the Terms & Refund   │
│ Policy.                       │
│                              │
├──────────────────────────────┤
│      [ Place order — 285 ج ]  │
└──────────────────────────────┘
```

- COD shows only for delivery channel.
- On press of "Place order":
  1. If not authenticated → OTP screen (next).
  2. Server **re-prices** against the POS snapshot (ADR-006). If anything changed (price up/down, item 86'd), show an inline diff and ask the user to confirm.
  3. For card/wallet → redirect to Kashier HPP in the same tab; on return → confirmation screen.
  4. For COD → straight to confirmation screen.

### 8a. Repriced confirmation

```
┌──────────────────────────────┐
│  ⚠ Prices changed             │
│                              │
│ Some items in your cart now   │
│ cost a different amount:      │
│  • Margherita: 85 → 90 ج     │
│  • Cola 330ml: 15 → out of   │
│    stock (removed)           │
│                              │
│ New total: 285 → 275 ج        │
│                              │
│  ‹Edit cart›   [ Continue ]   │
└──────────────────────────────┘
```

This is a critical UX surface — the system never silently swaps a price.

---

## 9. Auth — phone OTP

Shown only when needed (mostly at checkout). If the user reaches this from Profile, the post-action is "Go to profile".

### 9a. Phone input

```
┌──────────────────────────────┐
│  ←                            │
├──────────────────────────────┤
│ Confirm your phone            │
│                              │
│ We'll text you a 6-digit code │
│ to confirm the order.         │
│                              │
│ Phone                         │
│ [ 🇪🇬 +20  100 123 4567     ] │
│                              │
│ ▢ I agree to T&Cs and        │
│    Privacy Policy             │
│                              │
│       [ Send code ]           │
└──────────────────────────────┘
```

- Country code locked to EG; phone normalised to E.164.
- Honeypot field + rate limit at the API.
- If `429` from the API, friendly retry copy with countdown.

### 9b. OTP verify

```
┌──────────────────────────────┐
│  ←                            │
├──────────────────────────────┤
│ Enter the 6-digit code we     │
│ sent to +20 100 123 4567      │
│                              │
│   [ _ ][ _ ][ _ ][ _ ][ _ ][ _ ]
│                              │
│ Didn't get it?                │
│   Resend in 0:45              │
│   Wrong number? Change it     │
└──────────────────────────────┘
```

- Auto-advance per digit; auto-submit on the 6th digit.
- Honour SMS autofill where the OS supports it (`autocomplete="one-time-code"`).
- 3 wrong attempts → 5-minute cool-down with clear copy.

---

## 10. Order placed — confirmation

```
┌──────────────────────────────┐
│                              │
│         🎉                    │
│   Order placed!               │
│                              │
│   #B01-1287                   │
│   285.00 ج · Cash on delivery│
│                              │
│   We'll text you when:        │
│    ✓ Restaurant accepts       │
│    ✓ Food is ready            │
│    ✓ Out for delivery         │
│                              │
│   ETA: ~25 min                │
│                              │
│   [  Track this order  ]      │
│   ‹Back to menu›              │
└──────────────────────────────┘
```

- Confetti-light animation (one-shot, motion-reduce respected).
- Auto-redirects to tracking after 3 s.

---

## 11. Order tracking — live status

```
┌──────────────────────────────┐
│  ←  Order #B01-1287           │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │         🍳                │ │
│ │   Being prepared          │ │
│ │   Ready in ~12 min        │ │
│ └──────────────────────────┘ │
│                              │
│ Timeline                      │
│  ●  Placed         19:12     │
│  ●  Accepted       19:13     │
│  ●  Preparing      19:14     │
│  ○  Ready          —         │
│  ○  Out for delivery —       │
│  ○  Delivered      —         │
│                              │
│ ── Order ──                  │
│  1× Margherita        85.00 ج│
│  2× Chicken Crepe    130.00 ج│
│  1× Cola              15.00 ج│
│                              │
│  Subtotal            245.00 ج│
│  Delivery             20.00 ج│
│  VAT                  20.00 ج│
│  Total               285.00 ج│
│                              │
│ Pay: COD — not yet collected │
│                              │
│ Need help?                    │
│  📞 Call the branch           │
│  ❌ Cancel order (only before │
│     it's accepted)            │
└──────────────────────────────┘
```

- Top card swaps the icon + headline per status, reusing one component.
- Page polls `GET /v1/orders/{id}` every 10 s, with a "tab focus" listener that refetches immediately.
- Cancel is only shown when state allows; tapping opens a confirm sheet that calls `POST /orders/{id}/cancel`.
- Customer never sees "rider" or "kitchen" personas — keeps it simple.

---

## 12. Order history

```
┌──────────────────────────────┐
│  ←  My orders                 │
├──────────────────────────────┤
│ Active                        │
│ ┌──────────────────────────┐ │
│ │ #B01-1287   🍳 Preparing  │ │
│ │ 285 ج · 19:12  · 🚚        │ │
│ │ [ Track ]                 │ │
│ └──────────────────────────┘ │
│                              │
│ Past                          │
│ ┌──────────────────────────┐ │
│ │ #B01-1260   ✓ Delivered   │ │
│ │ 175 ج · yesterday · 🥡    │ │
│ │ [ Reorder ]               │ │
│ ├──────────────────────────┤ │
│ │ #B01-1245   ❌ Cancelled  │ │
│ │ Refunded 95 ج             │ │
│ ├──────────────────────────┤ │
│ │ ...                       │ │
│ └──────────────────────────┘ │
│ ‹Load more›                   │
└──────────────────────────────┘
```

- "Reorder" pre-fills the cart with the same items + modifiers; prices re-fetched (per ADR-006).
- Tap a row → order detail (read-only version of the tracking screen with a clearer "completed" header).

---

## 13. Profile

```
┌──────────────────────────────┐
│  ←  Me                        │
├──────────────────────────────┤
│ 👤 Mohamed Emad               │
│    +20 100 123 4567           │
│    [ Edit name ]              │
│                              │
│ My addresses                  │
│ ┌──────────────────────────┐ │
│ │ Home — شارع شكري…  ⭐    │ │
│ │ Work — شركة المهدي…       │ │
│ │ [ + Add ]                 │ │
│ └──────────────────────────┘ │
│                              │
│ My orders            >        │
│                              │
│ Language            ▼ AR     │
│ Help & contact      >        │
│ Privacy policy      >        │
│ Terms of service    >        │
│                              │
│        [ Sign out ]           │
│                              │
│ v1.0.0                        │
└──────────────────────────────┘
```

---

## 14. Empty / error / offline states

```
EMPTY CART                       OUT OF AREA (address)
─────────────────                ───────────────────────
   🛒                              ⚠
   Your cart is empty              We don't deliver to
   Tap an item to add it           this area yet.
   [ Browse menu ]                 Try takeaway or a
                                   different address.

BRANCH CLOSED                    NO INTERNET (PWA)
─────────────────                ───────────────────────
   🕒                              📶 You're offline
   We're closed right now          Showing the last menu
   Opens today at 10:00            we cached.
                                   Your cart is saved.
```

All four reuse the same `EmptyState` component pattern from the admin doc.

---

## 15. Notifications received by the customer

In-app: a small toast when the status changes (if app is open).
SMS (ADR-010, MVP channel):

| Event | Example AR | Example EN |
|---|---|---|
| order_placed | `طلبك #1287 وصلنا، هنبدأ تجهيزه قريب. تابع: <link>` | `Order #1287 received. We'll start preparing it. Track: <link>` |
| accepted | `طلب #1287 اتقبل، وقت التحضير ~18 دقيقة.` | `Order #1287 accepted. ETA ~18 min.` |
| ready (pickup) | `طلب #1287 جاهز للاستلام من الفرع.` | `Order #1287 is ready for pickup.` |
| out_for_delivery | `طلب #1287 في الطريق إليك.` | `Order #1287 is on its way.` |
| completed | `وصلك طلب #1287. بالهنا!` | `Order #1287 delivered. Enjoy!` |
| cancelled | `طلب #1287 اتلغى. <reason>` | `Order #1287 cancelled. <reason>` |
| refund | `استرديتلك <amount> ج لطلب #1287. ممكن ياخد 3-7 أيام يظهر.` | `Refunded <amount> ج for order #1287. 3–7 days to appear.` |

Each link goes to the tracking page — no app install required.

---

## 16. PWA niceties

- **Install prompt** appears after the user's first successful order (not before — premature prompts hurt conversion).
- **Offline menu**: service worker caches the last menu the user saw with a 24h TTL; cart state persisted in `localStorage`.
- **Hot-page route preload**: tracking page is preloaded after order submit to make redirect instant.
- **Add to home screen**: meta tags + 512 px PNG icon derived from the Ghazal flame; Arabic name on home screen.
- **Theme colour**: `--brand-flame` so the OS chrome (Chrome address bar, iOS status) tints to brand.

---

## 17. Performance budget (mobile, 3G)

| Metric | Target |
|---|---|
| First contentful paint (cold) | ≤ 1.5 s |
| Largest contentful paint | ≤ 2.5 s |
| Total blocking time | ≤ 200 ms |
| First menu interactive | ≤ 2.0 s |
| JS bundle (initial) | ≤ 180 KB gzipped |

Tactics:
- Code-split routes: landing, menu, item, cart, checkout, tracking, profile all lazy-loaded.
- Menu images served from Cloudflare R2 with `<img srcset>` + AVIF/WebP fallback + blurhash placeholder.
- Skeletons over spinners — fewer layout shifts.

---

## 18. Accessibility & internationalisation

- All text in AR/EN locale files; never hard-coded.
- `dir="rtl"` on `<html>` when AR. Tailwind logical utilities (`ms-*`, `me-*`).
- Numerals stay LTR even in AR contexts.
- Currency formatted via `Intl.NumberFormat('ar-EG', { style:'currency', currency:'EGP' })`.
- Min touch target 44×44 px.
- Form errors announced via `aria-live="polite"`.
- Colour-blind safe: status badges always include an icon and text.
- `prefers-reduced-motion`: disables the confetti and the slide-in toasts.

---

## 19. Component composition cheatsheet

| Screen | shadcn primitives | Custom |
|---|---|---|
| App shell | `Tabs`, `Toggle`, `Sonner` | `BottomNav`, `StickyCartBar` |
| Landing | `Card`, `Badge`, `Button` | `BranchCard` |
| Menu | `Card`, `Tabs` (chips), `Skeleton` | `MenuItemCard`, `CategoryChipsRail` |
| Search overlay | `CommandDialog`, `Input` | `SearchResultRow` |
| Item detail | `Carousel` (Radix), `RadioGroup`, `Checkbox`, `Textarea`, `Button` | `QtyStepper`, `StickyFooterCTA` |
| Cart | `Card`, `Button` | `CartLine`, `QtyStepper` |
| Checkout 1 | `RadioGroup`, `Card` | `ChannelToggle`, `AddressCard` |
| Add address | `Sheet`, `Input`, `Select`, map | `MapPin` |
| Checkout 2 | `RadioGroup`, `Card`, `Button` | `OrderSummaryBlock`, `ReprintConfirmDialog` |
| OTP | `InputOTP` (shadcn), `Button` | `Countdown` |
| Confirmation | (none) | `BigStatusCard` |
| Tracking | (none) | `BigStatusCard`, `StatusTimeline`, `OrderItemsBlock` |
| History | `Tabs`, `Card`, `Skeleton` | `OrderHistoryRow` |
| Profile | `Card`, `Select`, `Button` | `MenuListRow` |
| States | `Skeleton` | `EmptyState`, `ErrorState`, `OfflineBanner` |

---

## 20. What's intentionally NOT here (deferred to v1.1)

- Live map tracking on the tracking page (ADR-032 — restaurant owns delivery; no rider GPS).
- Promo codes / loyalty points (ADR-031).
- Saved payment methods (introduces PCI scope creep; one Kashier session per order in MVP).
- Scheduled orders for later in the week — only same-day ASAP in v1.
- Multi-restaurant ("Other restaurants near you") browsing — out of scope.
- Push notifications — SMS only in MVP (ADR-010 revised).

---

## 21. Next steps

1. Client review focused on:
   - **Menu card layout** (photo + price prominence)
   - **Checkout flow** (channel before payment; OTP only at submit)
   - **Repriced confirmation** copy
2. Designer renders pixel mock in Figma against the `brand-warm` tokens (cream `--brand-cream`, flame `--brand-flame`, deep red `--brand-red`).
3. Frontend builds the shared components into `packages/ui/` (TDD-first, mostly already designed in the admin doc).
4. Wire `apps/customer-web` pages to the API endpoints in [openapi.yaml](../api/openapi.yaml) — every screen above maps to a defined endpoint.

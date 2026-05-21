# Ghazal — Admin Dashboard Wireframes (v1)

**Last updated**: 2026-05-22
**Design system**: shadcn/ui + Radix + Tailwind ([ADR-033](../ADR/033-Design_system_shadcn.md))
**Density**: dense (32px rows, 12/16 padding)
**Brand**: warm — flame orange primary, deep red as destructive, leaf green as success
**Direction**: AR (RTL) default, EN (LTR) toggle

These are low-fidelity ASCII wireframes. Pixel design comes after client sign-off on layout and flow. The wireframes below assume **LTR** for legibility; mirror everything for RTL except numerals.

Legend:
- `[Button]` = primary action
- `‹Button›` = secondary
- `▢` = checkbox  · `○ ●` = radio
- `▼` = dropdown / select
- `🔔` `⚙️` `🍔` `▣` = icons (lucide)
- `#####` = numeric data
- `▒` = empty state

---

## 0. Information architecture

```
Sidebar
├─ Dashboard          (today at a glance)
├─ Orders             (live + history)
├─ Menu               (items, categories, modifiers, media)
├─ Customers          (search + history)
├─ Reports            (daily / range)
├─ Branches           (settings, hours, zones)
├─ Agent              (sync status per branch)
└─ Settings           (users + roles, providers, notifications)
```

Top-level role visibility:
- **Owner**: all
- **Manager**: all except Settings → Users
- **Cashier**: Orders, Menu (read), Dashboard
- **Kitchen**: Orders only, kitchen view variant

---

## 1. App shell

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ ▣ Ghazal Admin   ┌─────────────────────────┐                  AR | EN  🔔  ⚙️  👤   │
│ ─────────────────│ 🔍 Search orders / items │──────────────────────────────────────│
│                  └─────────────────────────┘                                        │
├─────────┬───────────────────────────────────────────────────────────────────────────┤
│ ▢ Dash  │                                                                           │
│ ▣ Orders│                          ▼  Branch: المحلة الكبرى                          │
│ ▢ Menu  │                                                                           │
│ ▢ Cust. │                                                                           │
│ ▢ Repts │                       <Main content area>                                 │
│ ▢ Branch│                                                                           │
│ ▢ Agent │                                                                           │
│ ▢ Setts │                                                                           │
│         │                                                                           │
│ ─────── │                                                                           │
│ Pilot ✓ │                                                                           │
│ v1.0.0  │                                                                           │
└─────────┴───────────────────────────────────────────────────────────────────────────┘
```

Shell composition (shadcn):
- `Sidebar` (custom, collapsible to 56 px) with `NavigationMenu` items.
- Top bar: `Input` (cmd-K search), `Select` for branch, `Toggle` for language, `Popover` for notifications, `DropdownMenu` for user.
- **Hot key**: `g o` → Orders, `g m` → Menu, `g d` → Dashboard (managers love this).
- **Online-ordering kill switch**: a banner at top with `[Pause online ordering]` button. When paused, banner turns red across the whole app.

---

## 2. Login

```
                            ┌───────────────────────────────┐
                            │       Ghazal Admin            │
                            │                               │
                            │   Email                       │
                            │   [_________________________] │
                            │                               │
                            │   Password                    │
                            │   [_________________________] │
                            │                               │
                            │   ▢ Remember this device      │
                            │                               │
                            │   [    Sign in           ]    │
                            │                               │
                            │   Forgot password?            │
                            └───────────────────────────────┘
```

- Single-column, centred. Submit on Enter.
- After login: if user has multiple branches, show **branch picker** (`Command` palette style); otherwise straight to the default branch.

---

## 3. Live Orders (kanban)

The hero page. Auto-refresh every 5s (poll API), with toast on new arrivals.

```
┌─ Orders ─────────────────────────────────────────────────────────────────────────────┐
│ Branch ▼  المحلة الكبرى    Channel ▼ All    Status: live      [ + Manual order ]    │
│                                                                                       │
│  NEW (3)         │ ACCEPTED (4)     │ PREPARING (5)   │ READY (2)       │ OUT (3)    │
│ ────────────────┼─────────────────┼────────────────┼────────────────┼──────────── │
│ ┌─ #B01-1287 ─┐ │ ┌─ #B01-1283 ─┐ │ ┌─ #B01-1278─┐ │ ┌─ #B01-1275─┐ │ ┌─#B01-1270 ┐│
│ │ 🚚 5 items   │ │ 🥡 3 items   │ │ 🚚 7 items  │ │ 🥡 4 items   │ │ 🚚 6 items  ││
│ │ 285.00 ج.م  │ │ 124.00 ج.م   │ │ 412.50 ج.م  │ │ 196.00 ج.م   │ │ 350.00 ج.م  ││
│ │ 19:12 · COD │ │ 19:05 · CARD │ │ 19:00 · CARD│ │ 18:55 · CASH │ │ 18:48 · CARD││
│ │ ⏱ 0:23 wait │ │ ⏱ 0:30 prep  │ │ ⏱ 0:18 prep │ │ ⏱ ready 4 min│ │ ⏱ out 6 min ││
│ │ [Accept] [✖]│ │ [Start prep] │ │ [Mark Ready]│ │ [Out for Δ]  │ │ [Delivered] ││
│ └─────────────┘ └──────────────┘ └─────────────┘ └──────────────┘ └─────────────┘│
│ ┌─ #B01-1286 ─┐ │ ┌─ #B01-1282 ─┐ │ ┌─ #B01-1277─┐ │ ┌─ #B01-1274─┐ │ ┌─#B01-1269 ┐│
│ │ ...          │ │ ...          │ │ ...          │ │ ...          │ │ ...         ││
│                                                                                       │
│ Auto-refresh: 5 s · Last update: 19:14:02 · 🟢 Agent online                          │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

Card details (top → bottom inside one card):
- **Order short code** (#B01-1287) — click to open detail drawer.
- **Channel icon** + item count.
- **Total** (mono, large).
- **Time placed** + **payment method tag**.
- **SLA timer** — green < target, amber > target, red overdue.
- **Primary action button** for the next transition.
- **Kebab menu** (top-right of card): `Cancel`, `Print ticket`, `Refund`.

Behaviour:
- Drag-and-drop disabled — actions only via buttons (avoids fat-finger transitions).
- New arrivals slide in with a soft chime; staff can mute per-session.
- A card in NEW past the **auto-accept timeout** flashes red and triggers a sound alert.

Components: `Card`, `Badge`, `Button`, `DropdownMenu` (kebab), `Tooltip` (timer hover), `useQuery` poll, `Sonner` for toasts.

### Empty / paused states

```
NEW (0)
┌────────────────────────────┐
│       ▒  All caught up      │
│   No new orders right now   │
└────────────────────────────┘

Pause banner (across the page top):
🛑  Online ordering is PAUSED. New orders are not coming in.
   Reason: Kitchen overload · [Resume]    set by Ahmed · 12 min ago
```

---

## 4. Order detail (right-side drawer)

Opens when a card is clicked. The orders board stays visible behind.

```
┌─────────────────────────────────────┐
│ #B01-1287  · 🚚 Delivery · 19:12   ✖│
├─────────────────────────────────────┤
│ Customer: محمد عماد                  │
│ Phone:    +20 100 123 4567  📞      │
│ Address:  3rd floor — shoukry st.   │
│           landmark: pharmacy        │
├─────────────────────────────────────┤
│ Items                                │
│ ┌─────────────────────────────────┐ │
│ │ 1×  Margherita Pizza   85.00    │ │
│ │     + Extra cheese     +15.00   │ │
│ │ 2×  Chicken Crepe      130.00   │ │
│ │     note: well done             │ │
│ │ 1×  Cola 330ml          15.00   │ │
│ │     ───────────────────         │ │
│ │ Subtotal              245.00    │ │
│ │ Delivery fee           20.00    │ │
│ │ VAT                    20.00    │ │
│ │ Total                 285.00    │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Payment: COD — not yet collected    │
│ Status timeline                      │
│  ● PLACED      19:12  by customer   │
│  ● ACCEPTED    19:13  by Ahmed      │
│  ○ PREPARING   —                    │
│  ○ READY       —                    │
│  ○ OUT FOR DEL —                    │
│  ○ COMPLETED   —                    │
├─────────────────────────────────────┤
│ [ Start preparing ]  [ Print ]      │
│ [ Cancel ]                          │
└─────────────────────────────────────┘
```

Components: `Sheet` (drawer), `Timeline` (custom — list with state dots), `Button`, money cell with `font-mono`.

Behaviour:
- Same order open in two tabs → optimistic concurrency: second tab sees the new state and replaces its action buttons.
- Timeline pulled from `order_events` API; shows actor name for every transition.
- `Cancel` opens a `Dialog` with required reason and refund preview.

---

## 5. Refund dialog

```
┌─────────────────────────────────────────────┐
│ Refund order #B01-1287                   ✖  │
├─────────────────────────────────────────────┤
│ Original total           285.00 ج.م          │
│ Already refunded            0.00 ج.م          │
│ Refundable                285.00 ج.م          │
│                                              │
│ Refund amount                                │
│ [  285.00  ]                                 │
│  ● Full refund   ○ Partial                   │
│                                              │
│ Reason  ▼  Customer request                  │
│ Notes  [ optional… ]                         │
│                                              │
│ Refunds via Kashier may take 3–7 business    │
│ days to appear on the customer's card.       │
│                                              │
│ ‹Cancel›                  [  Issue refund  ]│
└─────────────────────────────────────────────┘
```

Manager limit enforced server-side; UI hides the button or shows a "needs owner approval" message.

---

## 6. Dashboard (home)

```
┌── Today · المحلة الكبرى ─────────────────────────────────────────────────────────────┐
│                                                                                       │
│ ┌─ Orders ─┐ ┌─ Revenue ─┐ ┌─ Avg ticket ┐ ┌─ Online share ┐ ┌─ Agent ──────────┐ │
│ │   142    │ │ 18,420 ج │ │  129.7 ج     │ │  12.3 %        │ │ 🟢 online · 12 s │ │
│ │ ▲ +8     │ │ ▲ +3.2%  │ │ ▼ -1.1%      │ │ ▲ +2.1pp       │ │ outbox: 0        │ │
│ └──────────┘ └──────────┘ └─────────────┘ └────────────────┘ └──────────────────┘ │
│                                                                                       │
│ Live orders by status (last 6 h)                                                      │
│ ┌──────────────────────────────────────────────────────────┐                          │
│ │ 18    ──┐                                                 │                          │
│ │ 12      └──┐    ┌──┐                                      │                          │
│ │  6         └────┘  └──┐    ┌────                          │                          │
│ │  0──────────────────  └────┘                              │                          │
│ │  13:00     14:00   15:00   16:00   17:00   18:00          │                          │
│ └──────────────────────────────────────────────────────────┘                          │
│                                                                                       │
│ Top items today              │ Recent activity                                        │
│ ┌──────────────────────────┐ │ ┌────────────────────────────────────────────────────┐│
│ │ 1  Chicken Crepe   42x   │ │ │ 19:14  Order #1287 placed (COD)                    ││
│ │ 2  Margherita      37x   │ │ │ 19:13  Order #1283 accepted by Ahmed               ││
│ │ 3  Pepperoni       28x   │ │ │ 19:12  Refund issued #1280 (200.00 ج.م) by Salma  ││
│ │ 4  Cola 330ml      96x   │ │ │ 19:08  Item 86'd: Cheesy Fries by Ahmed            ││
│ │ 5  Spinach Pastry  19x   │ │ │ ...                                                ││
│ └──────────────────────────┘ │ └────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────────────────┘
```

Components: stat `Card`s, Recharts `<BarChart>`, two table cards.

---

## 7. Menu — items list

```
┌── Menu · Items ────────────────────────────────────────────────────────────────────┐
│ 🔍 [ Search items… ]   Category ▼ All   Visible ▼ All   Issues ▼ Missing image (12)│
│                                                                            [+ New] │
│ ┌────┬─────────────────────────┬─────────┬───────┬───────┬──────────┬────────────┐ │
│ │ ▢  │ Item (AR · EN)          │ Price   │ Tax % │ Avail │ Online   │ Updated    │ │
│ ├────┼─────────────────────────┼─────────┼───────┼───────┼──────────┼────────────┤ │
│ │ ▢  │ بيتزا مارجريتا          │  85.00 │  14   │ 🟢    │ ✅ ⚠️img  │ 2h ago     │ │
│ │    │ Margherita Pizza        │         │       │       │           │            │ │
│ │ ▢  │ كريب فراخ               │ 65.00  │  14   │ 🟢    │ ✅        │ yesterday  │ │
│ │    │ Chicken Crepe           │         │       │       │           │            │ │
│ │ ▢  │ بطاطس بالجبنة           │ 45.00  │  14   │ 🔴 86 │ ❌ hidden │ 1h ago     │ │
│ │    │ Cheesy Fries            │         │       │       │           │            │ │
│ │ ▢  │ ...                                                                        │ │
│ └────┴─────────────────────────┴─────────┴───────┴───────┴──────────┴────────────┘ │
│ Showing 1–50 of 213           ‹ Prev    Page 1 of 5    Next ›                      │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Behaviour:
- Click a row → opens the **Item editor drawer** (next section).
- Selecting rows enables bulk actions: bulk visibility toggle, bulk tag.
- "Issues" filter is the **Menu Health** entry point — pre-filtered queries: *missing image*, *no description*, *hidden online*, *price changed in 24h*.
- Sort by any column; defaults to "Updated desc".
- Inline `Toggle` for online visibility (no need to open editor for small changes).

---

## 8. Menu — item editor (drawer)

```
┌─────────────────────────────────────────────────────────────┐
│ Edit item  ·  Margherita Pizza                            ✖ │
├─────────────────────────────────────────────────────────────┤
│ From POS (read-only) ──────────────                          │
│   POS SKU:       ACME-IT-00187                               │
│   Price:         85.00 ج.م                                   │
│   Tax %:         14                                          │
│   Availability:  🟢 available  (updated 2 m ago)             │
│                                                              │
│ Online attributes (you control) ───────                      │
│ Name AR  [ بيتزا مارجريتا                              ]    │
│ Name EN  [ Margherita Pizza                            ]    │
│ Description AR                                               │
│ [ صلصة طماطم، جبنة موزاريلا، ريحان طازج                 ]    │
│ [                                                       ]    │
│ Description EN                                               │
│ [ Tomato sauce, mozzarella, fresh basil                ]    │
│                                                              │
│ Tags   [Spicy ✕] [Vegetarian ✕] [+ Add]                     │
│ Allergens [Dairy ✕] [Gluten ✕] [+ Add]                       │
│                                                              │
│ Prep time override   [  18  ] minutes   (default 25)         │
│ Min/Max per order    [  1   ]   [  6   ]                     │
│                                                              │
│ Visibility                                                   │
│   ●  Visible online    ○ Hidden                              │
│   ▢  Featured on homepage                                    │
│                                                              │
│ Photos                                                       │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                          │
│ │ 🖼  ★│ │ 🖼  │ │ 🖼  │ │ + Up │                          │
│ │ del  │ │ del  │ │ del  │ │ load │                          │
│ └──────┘ └──────┘ └──────┘ └──────┘                          │
│                                                              │
│ ────────────────────────────────────────────────────────────│
│  ‹Discard›                                       [ Save ]    │
└─────────────────────────────────────────────────────────────┘
```

- **Top section is read-only** — reinforces "POS owns price/availability" (ADR-005).
- Photos uploaded via `multipart/form-data` to `POST /admin/menu/items/{id}/media`. Star icon marks the primary.
- Drag to reorder photos (only this one uses DnD; orders board doesn't).
- Save is disabled until something dirty + valid.

Components: `Sheet`, `Tabs` (Info / Photos / Pricing-history), `Input`, `Textarea`, `Switch`, `Tag` (custom), `FileUploader` (custom around Radix's `<input type=file>`), `Form` with RHF + Zod.

---

## 9. Menu Health (filtered view of Items)

The same items table, opened by clicking the **Issues** filter chip.

```
┌── Menu Health ────────────────────────────────────────────────────────────────────┐
│  ⚠️  12 items missing images                                                       │
│  ❌  4 items hidden online                                                          │
│  💸  3 prices changed in the last 24 h                                              │
│  ⏰  6 items have no online prep override (using branch default 25 min)             │
│                                                                                    │
│ [ Show missing images ]  [ Hidden online ]  [ Price changes ]  [ No prep time ]    │
│                                                                                    │
│ <items table, pre-filtered to active issue>                                        │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Each filter is a one-click shortcut; same table component re-used.

---

## 10. Customers

```
┌── Customers ──────────────────────────────────────────────────────────────────────┐
│ 🔍 [ phone, name, order code ]                                                    │
│                                                                                    │
│ ┌─────────────────────┬────────────────┬──────────┬───────────┬─────────────────┐ │
│ │ Name                │ Phone          │ Orders   │ Last      │ Status          │ │
│ ├─────────────────────┼────────────────┼──────────┼───────────┼─────────────────┤ │
│ │ محمد عماد            │ +20 100 …  4567│  12      │ 2 d ago   │ 🟢 active        │ │
│ │ Sara Hassan          │ +20 111 …  9982│   3      │ 19 min    │ 🟢 active        │ │
│ │ خالد فتحي            │ +20 122 …  3344│   0      │ never     │ 🔴 blocked (3)   │ │
│ └─────────────────────┴────────────────┴──────────┴───────────┴─────────────────┘ │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Click a row → customer profile drawer with order history, ability to block / unblock with reason (writes to `customers.is_blocked` + reason). No PII surfaces beyond what staff need.

---

## 11. Reports — daily

```
┌── Reports · Daily ────────────────────────────────────────────────────────────────┐
│ Date  [ 2026-05-22 ▼ ]   Branch ▼ المحلة الكبرى            [ Export CSV ]          │
│                                                                                    │
│ ┌─ Orders 142 ──┐ ┌─ Revenue 18 420 ─┐ ┌─ Cancel 9 ─┐ ┌─ Avg prep  17m ─┐         │
│ │   ▲ +8 vs avg │ │  ▲ +3.2%          │ │  6.3 %      │ │  ▼ -2 m         │         │
│ └───────────────┘ └───────────────────┘ └────────────┘ └─────────────────┘         │
│                                                                                    │
│ Hourly orders                          │ Payment split                              │
│ ┌──────────────────────────────────┐  │  ▣ ▣ ▣ ▣ ▣ ▣ ▣ ▣ ▣ ▢       │              │
│ │  bar chart by hour                │  │  Card 38 %                                 │
│ │                                   │  │  COD  52 %                                 │
│ └──────────────────────────────────┘  │  Wallet 10 %                                │
│                                                                                    │
│ Top items today        │ Cancellation reasons                                       │
│  Chicken Crepe   42×   │  Customer changed mind  4                                  │
│  Margherita      37×   │  Address not deliverable 3                                 │
│  Pepperoni       28×   │  Kitchen overload         2                                │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Components: Recharts `BarChart`, `PieChart`, two simple tables. CSV export hits an existing API endpoint with `?format=csv`.

---

## 12. Branches → Settings

```
┌── Branch · المحلة الكبرى ─────────────────────────────────────────────────────────┐
│ [ General ] [ Hours ] [ Delivery zones ] [ Notifications ] [ Online ordering ]    │
├──────────────────────────────────────────────────────────────────────────────────┤
│ General                                                                           │
│   Name AR [ المحلة الكبرى                  ]   Name EN [ El-Mahalla …         ] │
│   Phone    [ +20 040 238 5517 ]                                                  │
│   Time zone  ▼ Africa/Cairo                                                       │
│   VAT %       [ 14 ]                                                              │
│   Service charge % [ 0 ]                                                          │
│                                                                                   │
│ Order timeouts                                                                    │
│   Pending payment  [ 600 ] s                                                      │
│   Auto-accept     [ 300 ] s                                                       │
│   Pickup expiry   [ 3600 ] s                                                      │
│                                                                                   │
│ Operations                                                                        │
│   Default prep time     [ 25 ] min                                                │
│   Track out-for-delivery ●  yes  ○  no                                            │
│                                                                                   │
│ ────────────────────────────────────────────────────────────────────────────────│
│ ‹Discard›                                                            [ Save ]    │
└──────────────────────────────────────────────────────────────────────────────────┘
```

**Hours tab**: weekday rows with open/close `Input type=time` and an "Always open" switch per day.
**Delivery zones tab**: list of zones with name, base fee, min order; map view planned for v1.1 (out of scope for the MVP wireframes per ADR-032).
**Online ordering tab**: big switch + reason text + history of pauses.

---

## 13. Sync Agent panel

Lives under `Agent` in the sidebar, or surfaces as a card on the Dashboard.

```
┌── Sync Agent ─────────────────────────────────────────────────────────────────────┐
│ Branch: المحلة الكبرى                                          [ Diagnostics ]    │
│                                                                                    │
│ 🟢  Online · last heartbeat 12 s ago                                                │
│ Agent version    1.0.0                                                             │
│ POS DB path      C:\CashierApp\data\pos.sqlite                                     │
│ Outbox depth     0                                                                  │
│ Inbox depth      0                                                                  │
│ Last order pull  3 s ago                                                            │
│ Last status push 8 s ago                                                            │
│ Last menu sync   12 min ago                                                         │
│ Schema fingerprint ✅ matches                                                        │
│                                                                                    │
│ Recent activity                                                                    │
│   19:14:02  pulled order #1287 → inserted                                          │
│   19:13:55  pushed status PREPARING for #1283                                      │
│   ...                                                                              │
└────────────────────────────────────────────────────────────────────────────────────┘
```

When agent is offline:

```
🔴  Offline · last heard 4 min 13 s ago
The cashier PC may be off, disconnected, or the Sync Agent service stopped.
Online orders are still being received and queued; they will be delivered to the POS when the agent reconnects.
[ View troubleshooting steps ]
```

---

## 14. Settings (owner only)

- **Users & roles** — list of `staff_users` with `Add user` dialog; role assignment per branch.
- **Refund limits** — manager refund cap (number), per-order and per-day.
- **Notifications** — pick SMS provider (env config view), edit notification templates per event.
- **API keys** — Kashier mode (sandbox/live), credentials masked, last-rotated date.
- **Audit log** — table view of `audit_log` with filters by actor + action.

---

## 15. Mobile / tablet behaviour

The board is the only screen designed for the cashier PC's 1366×768 minimum.

- **< 1024 px**: kanban collapses to a vertical `Tabs` per status.
- Drawer becomes a full-screen `Dialog` on small screens.
- All actions reachable with one hand on a 9-inch tablet held in portrait (manager at the counter).

---

## 16. Empty / loading / error states

Every list and panel has three states:

```
LOADING        EMPTY                              ERROR
────────       ──────────────────────             ──────────────────────────────
Skeleton       ▒  No data yet                      ⚠️  Couldn't load orders
rows × 5       Try clearing filters                Error: network timeout
                                                   [ Retry ]
```

Spec: `Skeleton` from shadcn, custom `EmptyState` and `ErrorState` components in `packages/ui/src/states/`.

---

## 17. Component composition cheatsheet

| Screen | shadcn primitives | Custom |
|---|---|---|
| App shell | `NavigationMenu`, `DropdownMenu`, `Tooltip`, `Toaster` | `Sidebar`, `BrandSwitch` |
| Live Orders | `Card`, `Badge`, `Button`, `DropdownMenu`, `Tooltip` | `OrderCard`, `KanbanColumn`, `SlaTimer`, `MoneyCell` |
| Order detail | `Sheet`, `Separator`, `Button`, `Dialog` | `Timeline` |
| Refund dialog | `Dialog`, `Form` (RHF), `Input`, `RadioGroup`, `Select`, `Button` | `MoneyInput` |
| Dashboard | `Card`, Recharts `BarChart` | stat tiles, activity feed |
| Menu items | TanStack `Table`, `Input`, `Switch`, `Popover` (filter), `Pagination` | `MenuRow` |
| Item editor | `Sheet`, `Tabs`, `Form`, `Textarea`, `Switch`, `Tag`, `FileUploader` | `MediaTile` |
| Customers | `Table`, `Sheet` | `CustomerProfile` |
| Reports | `Tabs`, Recharts | stat tiles |
| Branch settings | `Tabs`, `Form`, `Input`, `Select`, `Switch` | per-day hours editor |
| Sync Agent | `Card`, `Badge`, `Tooltip`, activity list | `AgentStatusDot` |

---

## 18. What's intentionally NOT here (deferred to v1.1)

- Real-time WebSocket push (currently 5 s poll — acceptable at 100–300 orders/day).
- Drag-drop kanban moves (button-only by design choice).
- Delivery-zone polygon editor with map (settings panel lists zones today).
- Customer-facing PWA wireframes (separate document).
- Kitchen Display variant (a stripped Orders board with only PREPARING column, larger fonts, no money) — v1.1.

---

## 19. Next steps

1. Client review on this doc (focus on the Live Orders card layout — that's the screen that matters).
2. Pixel mock in Figma based on the warm brand from the Ghazal logo (red/flame/leaf), single Branch + one Manager + one Cashier persona walkthrough.
3. Component build TDD-first (`packages/ui/`): start with `OrderCard`, `Timeline`, `MoneyCell`, `KanbanColumn` — the order flow is 80% of admin value.
4. Customer PWA wireframes — separate doc when admin is locked.

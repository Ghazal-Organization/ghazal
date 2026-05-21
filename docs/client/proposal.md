# Ghazal — Online Ordering Platform

**Proposal for the restaurant owner · Pilot scope**
**Date**: 2026-05-22

---

## 1. The opportunity

Today, your customers reach you by phone (or walk in) and your kitchen runs on your existing cashier app. **Online ordering** lets customers in El-Mahalla El-Kubra browse the menu, place delivery or takeaway orders, and pay — all from their phone — while your kitchen keeps using the same system it uses today.

We're proposing to build that online experience **on top of your existing operation, not next to it**.

## 2. What you get

A complete online ordering system, branded as Ghazal, made of four pieces:

1. **Customer ordering site** (works on every phone, no download needed)
   Beautiful menu with your dishes, AR & EN, COD or card/wallet payment, live order status by SMS.

2. **Manager dashboard** (works on any laptop or tablet)
   Live orders board, one-tap accept / reject / refund, menu management (descriptions, photos, hide items when sold out), daily sales report, pause the website when you're overwhelmed.

3. **Bridge to your existing cashier app**
   A small program runs on your cashier PC and **automatically pushes online orders into your POS** so the kitchen prints a ticket like any in-store order. No new workflow for the team.

4. **Payments collected through Kashier** (cards, Vodafone Cash, Meeza, COD)
   Money lands in your bank account; we never touch it.

## 3. What it does for the business

- **New revenue channel** — customers who would otherwise call a competitor can order from you 24/7.
- **No double work** — kitchen staff keep using your current cashier app exactly as today; online orders arrive there automatically.
- **Real control** — you set prep times, pause online ordering at peak, hide items, change prices (in the cashier app, online follows automatically).
- **Visibility** — a live dashboard shows daily orders, revenue, top items, cancellation reasons.
- **Customer comes back** — SMS notifications and one-tap reorder make repeat orders friction-free.

## 4. How it works (in one picture)

```
   Customer                      Internet                       Your branch
   ────────                      ────────                       ───────────
  📱 phone   ────►   Ghazal website + payments   ────►   Tiny program on cashier PC
                                                              │
                                                              ▼
                                                       Existing cashier app
                                                              │
                                                              ▼
                                                       Kitchen ticket prints
                                                              │
                                                              ▼
                                                       Order prepared & delivered
                                                              │
                                                              ▼
                                                  SMS to customer: "On the way"
```

## 5. Pilot scope (single branch, El-Mahalla El-Kubra)

To prove the value safely, we launch at **one branch first**:

- **In MVP**: online ordering for takeaway and delivery, card + wallet + COD, SMS notifications, admin dashboard, automatic sync to your cashier app, daily reports.
- **Not in MVP** (added later if useful): loyalty points, promo codes, scheduled-for-later orders, WhatsApp notifications, customer reviews, multi-branch online presence.
- **Pilot runs for 2–4 weeks** at the El-Mahalla branch with real customers; we monitor closely and fix issues fast.

## 6. What we need from you

These are required **before launch**:

| What | Why | Who provides |
|---|---|---|
| Active **commercial registration** (CR) + tax card in the restaurant's name | Kashier merchant onboarding | You |
| Bank account in the same legal name | Where settlements land | You |
| **Kashier merchant account approval** (we help with paperwork) | Card / wallet payments | You + us |
| **NTRA-approved SMS sender ID** (we apply on your behalf) | Branded SMS like "Ghazal: your order is ready" | Us, on your behalf |
| Logo files + 1 brand colour preference + ~15 dish photos | The site looks like your brand | You |
| Domain name preference (e.g. `ghazal-eg.com`) | Customer-facing URL | You |
| One designated **manager** trained on the dashboard | Day-to-day operations | You |
| Confirmation that we can install our small program on your cashier PC | Bridge to your POS | You |

What you do **not** need to provide: a tech team, a server, a payment provider account beyond Kashier, any change to your existing cashier app, or any cash up front for our cloud hosting (it starts free).

## 7. Investment

| Item | Type | Estimate |
|---|---|---|
| Build & launch (one-off) | Dev work | _TBD per scope / team rate_ |
| Cloud infrastructure | Monthly recurring | **~$0 – $25 / month** at pilot volume — designed to grow only when revenue does |
| Payments (Kashier) | % of each transaction | Negotiated by you with Kashier (typically 2–3% for cards) |
| SMS to customers | Per message | ~EGP 0.05–0.20 each — about **EGP 15–50 / day** at your expected order volume |
| Support after launch | Monthly | _TBD — bug fixes & small changes_ |

You pay **only when customers order**; the platform itself stays close to zero monthly cost during the pilot.

## 8. Timeline (milestones, not dates)

We deliver in 5 ordered phases, each with a clear "done" signal so you can see progress:

1. **Foundations** — accounts set up, infrastructure ready, first "hello" page online.
2. **Cloud backbone** — manager login, menu management, image uploads.
3. **Customer ordering + payments** — real online order, real Kashier payment, real refund, real manager actions. *Pos isn't connected yet — kitchen sees orders in the dashboard only.*
4. **Bridge to your cashier app** — one engineer visits the branch, connects to your POS, online orders flow into the kitchen exactly like phone orders.
5. **Hardening & pilot launch** — alerts, backups, manager training, owner training, soft launch with real customers for 2–4 weeks.

We do not promise specific dates until we agree the scope and assemble the team; phases 1–3 can run in parallel with you arranging Kashier and SMS paperwork, so the cumulative wait stays low.

## 9. Honest risks you should know about

- **Kashier merchant approval typically takes 5–10 business days** once paperwork is complete. Start now.
- **NTRA SMS sender-ID approval can take 2–6 weeks**. We start that on day one; until it lands we can use a generic sender ID.
- **Your cashier app must allow our small program to read/write the local database.** We confirm this on the on-site visit (phase 4). If it doesn't, we have a fallback that keeps online orders in the manager dashboard only, but the kitchen workflow becomes a little less automatic.
- **Card refunds appear on the customer's card in 3–7 business days** — that's Kashier's / the bank's timing, not ours.
- **Menu photos matter a lot for conversion.** Items without a photo sell measurably less. We will nag you (kindly) until the top 20 items have proper photos.

## 10. How we protect the business

- **Your prices are always whatever your cashier app says** — never can the online site quietly sell at a different price.
- **Every order, payment, refund, cancellation is logged with timestamp + who did it** — disputes are easy to resolve.
- **You can pause online ordering with one tap** if the kitchen is overwhelmed.
- **No card data ever touches our system** — Kashier handles all card info on their own secure pages.
- **Daily database backups** + a tested restore procedure.
- **Owner-only refund limits** above a configurable amount.

## 11. After the pilot

If the pilot works (we'll measure with you against agreed targets — typical pilot success is 10%+ of total orders coming online by week 4), the next steps are:

1. Add the **highest-impact item** from the deferred list — usually simple loyalty programme.
2. Quarterly review of operating cost vs. revenue.

## 12. Why us, briefly

- The platform is **architected before code was written** — there's a written record of every design decision and trade-off, available for your CTO or audit at any time.
- We use **proven, free or low-cost tools** instead of expensive enterprise products you'd pay forever for.
- **Test-first development** is our default — every behaviour the system promises has an automated test that proves it; this is the single biggest predictor of stability after launch.

---

**Contact**: _[your name + phone + email here]_
**Reference**: Full technical design available in our docs (database schema, system architecture, API contract, test plan, design system, screen wireframes).

---
name: bigcapital-ui-adaptive-design-goal
description: "Product direction — Bigcapital/Books UI should feel familiar to users coming from QuickBooks, Xero, Sage, etc., without copying protected IP"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1a584622-f8f2-4360-ad80-271f755bae42
---

The in-house accounting UI (built on Bigcapital, surfaced at `/books` in the dashboard —
see [dashboard-build-status](dashboard-build-status.md)) should be **adaptive to the
customer's point of origin**: users migrating from QuickBooks, Xero, Sage, or other
accounting platforms should encounter workflows and navigation patterns that feel
familiar to them, lowering the training burden and improving adoption.

Design should draw inspiration from industry-standard patterns (tab/nav structure,
common terminology, familiar list/detail/payment flows) **without replicating protected
intellectual property** — no copying another vendor's specific visual design,
proprietary layouts, or trade-dress. Bigcapital/Books must retain its own distinctive
visual identity (the dashboard's token system in `docs/DESIGN-SYSTEM.md` — brand green
`primary`, not vendor colors) even while borrowing *interaction conventions*.

**Why:** stated as an explicit product goal by the user (2026-07-02) for how Bigcapital
UI work should be evaluated going forward — not just "make it look good" but "make it
feel familiar to someone who already knows QuickBooks/Xero/Sage," while staying legally
and visually distinct.

**How to apply:** when building or reviewing any Books/accounting UI (invoices, bills,
chart of accounts, reports, reconciliation, etc.), check two things — (1) does the
workflow/navigation match a pattern an ex-QuickBooks/Xero/Sage user would recognize
(e.g. the QuickBooks-familiar 5-tab nav already used in [dashboard-build-status](dashboard-build-status.md)'s
Books redesign — Overview/Sales/Expenses/Accounting/Reports), and (2) does it stay
within our own token system / brand identity rather than cloning a competitor's actual
look. Flag any new Books feature that skips the "what would a QuickBooks/Xero/Sage user
expect here" check.

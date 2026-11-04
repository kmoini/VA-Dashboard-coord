---
name: automate-dont-add-manual-steps
description: FEEDBACK 2026-11-03 - Amin - every manual step (Refresh chart, Load again, picking accounts/items by hand) defeats the product; the system must handle it itself. Design for zero accountant clicks.
metadata:
  type: feedback
---

2026-11-03, after the stage 3 (sales Items) prod test on BBMS: "these manual changes, Refresh chart from QuickBooks, Load again, picking by hand are really tiring and hard for accountants and clients. The whole point of this system is to REDUCE the accountants' work; our system must handle these and make them automatic."

**Why:** the test needed Refresh chart (the Edit-lines dropdown reads the chart SNAPSHOT, stale until a nightly/manual refresh), Load again (items card), a native select with no search over 100+ accounts, and Save lines that did not re-sync the pushed invoice. Each one is a click the product promised to remove.

**How to apply:** before shipping any feature, ask "what does the accountant have to click for this to work?" and remove it: refresh caches/snapshots automatically when something is missing or stale (event-driven, not nightly), make selects searchable, re-sync on every edit of a pushed row, learn one-time picks per company so the next document needs none. A manual override may exist, but the default path must need zero clicks. Related: [[never-overrule-the-accountant]] (override stays possible), [[feature-test-handoff]].

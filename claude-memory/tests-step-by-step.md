---
name: tests-step-by-step
description: "FEEDBACK 2026-11-16: every production test handed to Amin must be written as numbered click-by-click steps, never as a summary sentence."
metadata:
  node_type: memory
  type: feedback
  originSessionId: e8b3c4c2-bd7f-4070-908f-a479db8e2721
  modified: 2026-11-16T22:16:18.851Z
---

Amin, 2026-11-16, in the financial reports work (va-dashboard2), after I twice gave a test as a short summary ("open Profit and Loss for July to September and press Refresh, click the Rent Expense figure") and he had to ask for it to be spelled out: "از این به بعد همیشه تست هارو قدم به قدم بهم بگو" (from now on always tell me the tests step by step).

**Why:** he runs the test himself on production and follows instructions literally (see [[no-placeholders-in-commands]]); a summary leaves him guessing which client to pin, which menu, which exact values.

**How to apply:** with every checkpoint hand-off, write the test as numbered steps from a known starting point: which client to pin in the header, which menu item, which card, the exact values to type or pick (dates as literal values), which button, then what he should see, then which screenshot to send. One action per step. Applies to all projects, in Persian. Related: [[feature-test-handoff]], [[local-test-before-push]].

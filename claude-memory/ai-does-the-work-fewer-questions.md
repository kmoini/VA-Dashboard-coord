---
name: ai-does-the-work-fewer-questions
description: "Amin's rule on questions shown to the accountant: nothing the bank statement, QuickBooks or the history already answers; an unknown expense account is still asked once, then learned"
metadata:
  node_type: memory
  type: feedback
  originSessionId: b8393a83-dfbe-4f43-b6a8-1b2fb17a18fe
  modified: 2026-11-27T22:56:55.540Z
---

Amin, 2026-11-27: "these account and GIFI choices that come up every time confuse me, who is building this, let alone the accountant and the client. We built this so the AI lowers the accountant's work; with the history and QuickBooks it must not keep asking, it must do an accountant's work in full. If you need something to complete it, say so."

His decisions the same day, when shown the counts (226 of 357 rows in 60 days carried a question):
- "Which bank account" is NEVER asked of a person. No account registered: take them from the QuickBooks chart. Several possible: no question, the statement decides at the match.
- An old document date is not a question. Only a future date is.
- No history and several possible accounts: the AI SAYS no account is known and shows a button to pick; after the pick it must have learned and not ask again. (He did NOT accept "pick the best guess silently"; this matches his earlier refusal of an uncategorized account.)
- What was done from QuickBooks once (invoice, payment, deposit for a tenant) must be known next month.

**Why:** the product's promise is less time at the screen; a question the system could answer itself reads as the system failing.

**How to apply:** before adding any review reason or prompt, ask whether the statement, the chart, the history or an earlier decision answers it; if so, act and at most leave a note. Measure first (count review reasons by code and client on production) instead of guessing which questions are noise. Built as checkpoint-606 (709182d7), doc `docs/FEWER-QUESTIONS-2026-11-27.md`. Related: [[money-in-invoice-payment-deposit]], [[automate-dont-add-manual-steps]], [[never-overrule-the-accountant]].

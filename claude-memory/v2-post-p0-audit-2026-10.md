---
name: v2-post-p0-audit-2026-10
description: 2026-10-07 night post-P0 hardening audit of Accounting V2 (docs/ACCOUNTING-V2-AUDIT-2026-10-07.md): nine accounting-team decisions pending, policy-free engineering list, known mis-classifying gaps. READ before any new V2 event work.
metadata:
  type: project
---

After phase 5 (V2.1 P0, commits 99d1858/3dacc08/d2c2f2d) the architect asked for a read-only hardening audit. Result in docs/ACCOUNTING-V2-AUDIT-2026-10-07.md (sections A to L) plus ScenarioMatrixTest and AccountingSides::isBalanced (no behaviour change).

Decisions the accounting team must give before code: Q11 multi-person receipt (A one row / B one per person / C one row with lines); asset disposal (today = SALE revenue); transfer-in from an unregistered account (today = revenue); vendor rebates/discounts; customer advance refund (today = expense); insurance recovery; ITC-eligibility rule; related party scope; whether unbalanced sides block.

Policy-free work (not done): show metadata.extras.line_items in the review drawer; one end-to-end ingest→pick→push test; raise or delete the 7 dead review reasons; REFUND into blocksPosting if wanted; equity-event GIFI band check; transfer-in rule after the decision.

**Why:** the brief forbids making accounting policy; these gaps need the team.
**How to apply:** when Amin relays the team's answers, build each event as rule + side + reason + push shape + scenario test; do not touch the P0 guarantees (list in section A of the audit). Related: [[accounting-v2-phase4-status]], [[never-overrule-the-accountant]].

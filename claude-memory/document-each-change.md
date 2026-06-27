---
name: document-each-change
description: "For each important change/feature, write a doc in docs/ explaining what changed and how it works."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b0ab5431-4588-44fc-ab1f-c4f0ca72f898
---

From 2026-06-09 on, for every **important change or feature** in va-dashboard2, write/update a Markdown doc under `docs/` describing **what changed and how it works** (data model, services, routes, UI, mobile-bridge touchpoints, config flags, how to test).

**Why:** Amin wants durable, reviewable documentation so the team understands each feature without reading all the code — especially across the mobile↔dashboard bridge.

**How to apply:**
- One doc per feature/subsystem (e.g. `docs/invoicing.md`, `docs/mobile-integration.md`); update the existing doc when extending a feature rather than duplicating.
- Keep it practical: purpose, key files, flow, statuses/enums, config/env flags, and a short "how to test" (tie to [[feature-test-handoff]]).
- Do this as part of the same increment as the code, before/with the checkpoint.

Related: [[feature-test-handoff]], [[checkpoint-rule]].

---
name: feature-test-handoff
description: "For every feature build, deliver a manual test guide for Amin + fake-data injection points on BOTH mobile and dashboard."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b0ab5431-4588-44fc-ab1f-c4f0ca72f898
---

From 2026-06-09 on, for **every feature** built in va-dashboard2, after writing the automated tests, also give Amin a **manual test guide** he can follow to exercise the feature himself.

**Why:** Amin tests features hands-on; automated tests alone aren't enough for his sign-off, and many features span the mobile↔dashboard bridge so he needs to know how to stage data on both sides.

**How to apply:**
- Write step-by-step manual test instructions (what to click/run, expected result).
- If testing needs fake/seed data, specify EXACTLY where to inject it **on both systems**:
  - **Dashboard** (our repo, PostgreSQL): give a concrete artisan command / seeder / tinker snippet and the table(s) — e.g. insert a `mobile_records` row (`entity_type='user_accountant'`).
  - **Mobile app** (Shahab's n8n + MySQL): specify the table + row shape to insert (e.g. `user_accountant` / `users`) so the real round-trip works; this is something Amin relays to Shahab / Mobile Claude.
- Prefer providing a ready-to-run dashboard seeding command over manual SQL where practical.

Related: [[union-plan-coordination]].

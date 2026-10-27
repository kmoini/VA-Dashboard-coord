---
name: ci-gate-on-server
description: 2026-10-26 DECISION (Amin): no paying GitHub for Actions; the merge gate runs on our own server with scripts/ci/gate.sh (own clone ~/ci/VA-Dashboard + own PostgreSQL DB; mirrors tests.yml's PostgreSQL job; `full` adds SQLite). Branch work/ci-gate-20261026 (4f9d91f); setup in docs/CI-GATE-STAGING.md; server setup NOT yet done.
metadata:
  type: project
---

Amin, 2026-10-26: "بحث پرداخت در Billing گیت‌هاب کلا بذار کنار، ما نمی‌تونیم پرداختی داشته باشیم" and then "اوکی" to running the gate on our own server. Tests stay mandatory; GitHub is not.

**What exists:** `scripts/ci/gate.sh` + `docs/CI-GATE-STAGING.md` on branch work/ci-gate-20261026 (commit 4f9d91f, pushed; not merged yet). Usage on the server: `~/ci/gate.sh <branch-or-commit> [pg|full]` -> GREEN / RED / SETUP, one line per run in `~/ci/gate.log`, full output in `~/ci/last-pg.txt` / `last-full.txt`. It runs the workflow's PostgreSQL path list on a dedicated DB (`migrate:fresh`), never the staging/prod checkouts or DBs.

**One-time server setup still to do (Amin):** a PostgreSQL database `va_dashboard_gate` (hosting panel or `createdb`), `~/ci/VA-Dashboard` clone, `~/ci/gate.env` with GATE_DB_* credentials (never in the repo), copy of the script to `~/ci/gate.sh`, first run `~/ci/gate.sh main`.

**Why:** the PostgreSQL job caught real prod defects (CHECK constraints, ordering) that SQLite never shows; Amin tests on prod, so the gate is the only net. **How to apply:** before every checkpoint merge, run the gate on the validation/ or work/ branch and paste the last line; `tests.yml` stays untouched for the day the account can run it again. Related: [[checkpoint-rule]], [[local-test-before-push]], [[accounting-v2-phase9-ci-gate-status]].

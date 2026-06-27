---
name: colleague-branch-integration-2026-06
description: Integrated 4 colleague branches into main one-at-a-time; prod deploy hit an activity_logs entity_type constraint violation (ClientMessage) — fixed
metadata: 
  node_type: memory
  type: project
  originSessionId: eaa51cfc-6d53-487f-b1cb-02b3d152a689
---

Late June 2026: integrated **4 colleague branches into `main`** one-at-a-time (checking every file; backup tag `backup/main-pre-integrate-20260624-1556`). Branches: `accounting-provider-qbo`, `books-smart-import`, `phase-8b-public-community`, `phase7-text-match-refactor`. Amin tested each before the next. For the **phase7 vs books-smart-import collision**, Amin chose to keep **phase7's** version (BooksController / RuleEngineService text-match refactor + Bigcapital auto-provisioning) and **drop branch-2's CSV-import UI** (so `SmartImportService`/`BankCsvImporter` + the two dropped routes are dead/unused).

**Prod deploy gotcha (the one that bit us):** `php artisan migrate --force` failed on `2026_06_17_000001_add_vendor_actions_to_activity_logs` with `SQLSTATE[23514] chk_activity_logs_entity_type` violation. The colleague's frozen constraint list omitted **`ClientMessage`** (our chat feature, which prod data already has). Fix = commit **`da12194`**: made the `up()` `entity_type IN (...)` list in all 3 activity_logs constraint migrations (`..000001_add_vendor_actions`, `..000002_add_community_actions`, `..000007_add_intelligence_actions`) an identical **superset** adding ClientMessage + Vendor + CommunityTranscription + IntercoMatch + FirmKnowledge + RelatedEntity + QuickBooksConnection + QuickBooksInvoice. Each `up()` does `DROP CONSTRAINT IF EXISTS` first → idempotent re-run. Reinforces the CLAUDE.md rule: **before deploying any activity_logs constraint migration, the list must include every value our newer features already log in prod — query live prod values first.**

**Deploy status (as of 2026-06-27, CONFIRM with Amin):** constraint fix pushed to `main`; prod was mid-deploy in maintenance mode (16 of 27 migrations applied). Resume = `git pull` → `php artisan migrate --force` (finishes the remaining ~11) → `npm ci && npm run build` → `php artisan config:clear` → `php artisan up`. Verify it completed.

Related: [[deploy-process]], [[checkpoint-rule]], [[autocommit-leaks-secrets]].

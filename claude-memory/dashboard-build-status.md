---
name: dashboard-build-status
description: "VA Dashboard feature-build status, checkpoints, gotchas, and open items as of 2026-06-09 (read at session start for continuity)."
metadata: 
  node_type: memory
  type: project
  originSessionId: b0ab5431-4588-44fc-ab1f-c4f0ca72f898
---

Cross-cutting status of the va-dashboard2 build arc (mobile integration + the four product features). Per-subsystem detail lives in `docs/mobile-integration.md`, `docs/invoicing.md`, `docs/chat.md`.

## Mobile↔dashboard bridge (foundation)
- Auth round-trip is **VERIFIED GREEN 7/7**; coordination STATUS = READY TO BUILD (repo `E:/Projects/union-plan-coord`, now status-only). See [[union-plan-coordination]].
- Plumbing built: **polling worker** (`/changes-since` → `mobile_records`/`mobile_revisions`/`mobile_sync_cursors`, checkpoint-006) + **write clients** (`MobileApiClient`: directoryUpsert/sendMessage/issueInvoice/inviteClient/acceptInvitation/attachmentUrls, idempotent) + **directory link** (`mobile:sync-directory`, checkpoint-007).
- Mobile endpoint base: `https://n8n.homeleaderrealty.com/webhook/bookkeeper/accountant/...`.

## Four product features (Amin's original ask)
1. **Client login/portal** — schema exists (`users.type`, `ResolveTenant`) but under the union model **clients use the MOBILE app, not the dashboard**; dashboard client-portal login is effectively vestigial. Not a feature built this arc.
2. **Accountant Inbox** (Direction-A invites) — **checkpoint-008**. `/inbox`; Accept calls mobile + links a `Client` (`clients.mobile_user_id`); `reconcileFirm` auto-creates Clients for clients who *selected* the firm (runs post-poll).
3. **Invoicing Phase 1** — **checkpoint-009**. Create → branded PDF (dompdf) → send (notify via issue-invoice) → track (draft/sent/paid/overdue/void). Public **signed** PDF route. Online card payment (**Stripe Connect**) = Phase 2, deferred.
4. **Chat outbound v1** — **checkpoint-010**, then **Messages Studio redesign (checkpoint-012)**. Premium 3-pane `/chat/studio` (Voice Emerald teal `#029a6c`) wired to REAL data via `ChatController` JSON endpoints (`studioThread`/`studioSend`/`studioEdit`/`studioRetract`) reusing `ChatService::send`. Adds **edit (pre-delivery only) + retract (soft-delete + audit log)** — `ClientMessage` now SoftDeletes, migration `..._000005` adds `edited_at`+`deleted_at`, `threadFor` uses `withTrashed()` + tombstones. Real **Client File** drawer (business no., FY end, on-app badge, pending-review→`/review-queue`, documents). Mic = **browser dictation→text** (no audio storage). Old `/chat` index/show untouched; sidebar "Messages" → `/chat/studio`. Build prereqs: Tailwind scans `.tsx`, Inter+JetBrains Mono loaded. Docs: `docs/messages-studio.md`. **Inbound (replies) still blocked on mobile** — DQ-0010 now **SHARPENED** into a build-ready contract (`accountant_messages` feed table + `messageId` echo + reserved `attachment_id`); our side = 1 `MobileEntities::MAP` entry + ingest handler once mobile ships ADR-0004.

## Checkpoints (tags on shahabarvin/VA-Dashboard `main`)
003 M2M minter+JWKS · 004 mint-test-token · 005 marker · 006 polling worker · 007 write clients+directory · 008 inbox+fake-writes · 009 invoicing P1 · 010 chat v1. Always recompute next via `git tag -l "checkpoint-*" | sort -V | tail -1` — see [[checkpoint-rule]].

## Critical gotchas (don't relearn the hard way)
- **M2M keys:** prod signing key **kid `8fb483da06953986`** lives in prod `storage/app/m2m`. The dashboard working-dir has a *different* dev key, so tokens minted locally get **401** from mobile. **Mint test tokens ON prod**: `php artisan m2m:mint-test-token --ttl=<secs>`.
- **`MOBILE_FAKE_WRITES`** (env, `config('mobile.fake_writes')`): in **local `.env` only** (currently true). Synthesizes mobile *write* success without the network so write features (inbox accept, invoice send, chat) are testable locally. **MUST be false/absent in prod.** Pinned `false` in `phpunit.xml` (tests assert real HTTP). See [[feature-test-handoff]].
- **DuoSync siblings (Kamyar/Shahab) also commit+push to `main`** — your uncommitted work may get committed by them under their own message; clean tree at checkpoint time is normal. See [[duosync-setup]].
- **Deploy** = webhook `git pull` ONLY; `migrate` + `npm run build` are **manual on prod via SSH** ([[deploy-process]]). `npm install` rewrites `package-lock.json` → dirties the tree → blocks the rebase-pull (deploy code 128). Use `npm ci`, or commit the lockfile, before the next pull. **Prod still owes (006–010): `php artisan migrate --force` (mobile_* tables, clients.mobile_user_id, invoices, client_messages) + `npm run build` + `config:clear`.**
- **Test harness:** `phpunit.xml` + `tests/TestCase.php` were missing and were restored (sqlite `:memory:`). `database/factories/UserFactory` is still missing (pre-existing — Auth feature tests can't run). `openssl_pkey_new` fails on the Windows dev box (keygen) → tests **stub `ServiceTokenMinter`** to avoid it. 33 mobile+invoice+chat tests green.

## Standing practices (this session)
- [[checkpoint-rule]] — "add a checkpoint" = commit + annotated tag + push branch & tag.
- [[feature-test-handoff]] — every feature: manual test guide for Amin + fake-data injection points (dashboard + mobile).
- [[document-each-change]] — every important change gets a `docs/` markdown.

## Commands
`m2m:generate-keys`, `m2m:mint-test-token`, `mobile:sync-directory`, `mobile:poll`, `mobile:reconcile-clients`, `mobile:demo-inbox`.

## Open items
- **Transaction projector — DONE (checkpoint-021, 3647c89).** `MobileTransactionProjector` projects mirrored `transactions` → dashboard `transactions` (client←created_by, source=client, status=pending, dedup by transactions.mobile_id, sync-while-pending, no-clobber, soft-delete); migration 2026_06_11_000001 (transactions.mobile_id + created_by nullable); wired in poll job + `mobile:project-transactions`. **Prod owes: migrate --force + mobile:project-transactions backfill.** (history below) — CONFIRMED on prod 2026-06-11: a mobile tx IS mirrored into `mobile_records` (firm 019e854c / macct 23 had transactions=1, id 346 "Charity donation") but there's NO projector into the dashboard `transactions` table (we only project clients + messages) → invisible in feed/approval-queue. Feed/poll/ingestion all healthy. BUILD: migration adding `transactions.mobile_id` (nullable bigint, unique-per-firm, for idempotent dedup) [+ check Transaction SoftDeletes for retract]; `MobileTransactionProjector` mapping mirrored rows → `transactions`; wire post-reconcile in PollMobileChangesJob (+ a `mobile:project-transactions` backfill cmd). **Real mobile tx payload field map:** tenant key = `created_by` (mobile user id, DQ-0006) → resolve `clients.mobile_user_id` → dashboard `client_id` (payload.client_id is null on mobile, ignore). Fields: `amount`(string "2.00"), `currency`, `category`, `description`, `gifi_code`, `effective_date`, `status`, `source`('ai'), `ai_suggested`(1), `ai_confidence_score`("0.50"), `ai_source`('mobile_quickentry'), `ai_version`('gemini-2.0-flash'), `created_at`, `version`, `deleted_at`, `classification`('EXPENSE'). Land as `source='client'`, `status='pending'` (accountant reviews, per AI-suggests/accountant-approves rule), preserve AI metadata; created_by=null on dashboard (mobile user isn't a dashboard user). Don't clobber accountant-edited rows (only update while still pending). Watch from_now scope (DQ-0001 §4).
- **DQ-0011 / ADR-0005 (rich chat content)** — raised to Mobile Claude (coord `b09918b`): inbound voice/photo/file via reserved `accountant_messages.attachment_id` (mostly app-side build) + optional additive `meta` on send-message-to-user for invoice/transaction cards. Ball on Mobile Claude for sign-off + app build; our dashboard render (via /attachment-url) follows once contract confirmed.
- **DQ-0010** (inbound chat) — DONE both sides (ADR-0004); projector deployed (checkpoint-020); round-trip step-a verified on prod. Full live inbound test pending a real linked client + Shahab firing the inbound endpoint.
- **Invoicing Phase 2** — Stripe Connect (onboard firms as connected accounts, hosted payment, webhook → auto-mark-paid).
- **Prod activation** of checkpoints 006–010 (migrate + build) — Amin via SSH.

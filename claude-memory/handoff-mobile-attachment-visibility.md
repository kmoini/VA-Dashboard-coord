---
name: handoff-mobile-attachment-visibility
description: Handoff — making mobile receipts/voice notes viewable in the dashboard (S3 key + morph-alias fixes). Read when continuing attachment-visibility work in the new workspace.
metadata: 
  node_type: memory
  type: project
  originSessionId: b0ab5431-4588-44fc-ab1f-c4f0ca72f898
---

⚠️ HANDOFF (chat dated ~2026-06-13) — full detail in the repo: **`docs/mobile-attachment-visibility-handoff.md`** (travels via `git pull`). Goal: mobile-uploaded receipts/voice notes visible to BOTH the accountant and the client-portal user. Done in code + deployed; only prod activation remained at the time.

**Three root causes, all fixed + deployed on `main`:**
1. `league/flysystem-aws-s3-v3` was never a declared dep → every `Storage::disk()` threw class-not-found. Added (checkpoint-025 `e59b6bb`). Prod needs `composer install` (git pull alone doesn't).
2. **Key-path mismatch** — mobile `file_url` is `…/{user_id}/{filename}` but objects live in the bucket **ROOT** as bare `{filename}` (proved 25/25: `{user_id}/<file>`→404, `<file>`→206). Fix `f300c04`: `Attachment::resolveStorageKey()` tries stored path then falls back to basename; wired into `signedUrl()` + `DocumentsController::serve` (also made disk-aware) + `ClientPortalController::serveDocument`.
3. **Morph type format** — projector stored `attachable_type = Transaction::class` (FQCN) but the whole app + the `AppServiceProvider` morphMap query the **alias** `'Transaction'` → `/recordkeeping/{id}/attachments` returned `[]`. Fix `6a74205`: store `'Transaction'`/`'Client'`; update branch normalizes legacy FQCN rows on re-sync.

**Prod activation (as of that chat — VERIFY before re-running, likely already done by now):** `composer install --no-dev` · `php artisan mobile:project-attachments` (normalizes the 25 rows → accountant receipts appear) · `php artisan migrate --force` + `npm run build` (client-portal pages from checkpoints 026-029).

**Cleanup owed:** remove the temp route `GET /temp/s3-attachment-test` + `app/Http/Controllers/Temp/S3AttachmentTestController.php` once verified.

**Why:** the user moved the team to a new workspace and will continue there; this chat's work must survive the move.
**How to apply:** in the new workspace, `git pull`, read the repo handoff doc above, and verify current prod/repo state (today the repo is far ahead — see [[checkpoint-rule]] checkpoint-054 and [[attachment-file-size-fix]]) before acting on any "prod owes" step. Related: [[deploy-process]], [[mobile-attachment-binaries-missing]], [[duosync-shared-memory]].

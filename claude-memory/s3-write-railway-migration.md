---
name: s3-write-railway-migration
description: ⚠️ IN-PROGRESS — dashboard S3 key is read-only so uploads silently fall to local disk (LOST on Railway redeploy); IAM PutObject fix + temp /temp/s3-write-test verify route to REMOVE. Read before Railway/Docker migration or touching uploads/storage.
metadata: 
  node_type: memory
  type: project
  originSessionId: ff7d6755-f55f-4ea9-be2e-6862c1e60cd1
  modified: 2026-07-29T18:25:09.092Z
---

Migrating the dashboard to a new server / **Railway** surfaced a blocker (2026-06-27 chat): the dashboard's own files must live on **S3** before any move, because the prod S3 access key is (almost certainly) **read-only**.

**The mechanism:** every upload path uses `storeUpload()` which tries `['s3','local']` in order ([DocumentsController.php:633](app/Http/Controllers/DocumentsController.php) + 9 other call sites — chat, scans, email, voice, google-drive, attachments, client-portal, gemini-ingest). The `s3` disk resolves to `MOBILE_S3_*` creds when `AWS_BUCKET` is blank (see [config/filesystems.php](config/filesystems.php)). Those creds are `s3:GetObject` only → `put()` throws **AccessDenied** → it **silently falls back to `local`**. Files aren't lost on a normal VPS, but **Railway's filesystem is ephemeral → every redeploy wipes local files.** So writes MUST reach S3 first. Extends [[upload-ghost-row-bug]].

**Architecture decided this chat:** dashboard's own files (accountant uploads, chat media, invoice PDFs, exports) → S3 under prefix **`firms/{firmId}/...`**. Mobile's files stay on the mobile read-only bucket (`mobile_s3` disk, presigned reads). M2M JWT is API auth only — irrelevant to file storage. Two options: keep writing into the shared mobile bucket (grant the MOBILE_S3 user write) OR set a dedicated `AWS_*` dashboard bucket+user.

**The fix (chosen = grant write to the SAME mobile IAM user, keep `AWS_BUCKET` blank):** add an inline IAM policy granting `s3:PutObject`/`GetObject`/`DeleteObject`/`AbortMultipartUpload` on `arn:aws:s3:::<BUCKET>/firms/*` + `s3:ListBucket` on the bucket with `s3:prefix=firms/*`. Via AWS Console: IAM → Users → (the MOBILE_S3 user) → Permissions → Add permissions → Create inline policy → JSON → name `dashboard-s3-write`.

**Verify route (TEMPORARY — must be removed after green):** `GET /temp/s3-write-test` (auth-gated) → [S3WriteTestController.php](app/Http/Controllers/Temp/S3WriteTestController.php). Runs PUT→EXISTS→GET→presign→DELETE with prod creds under `firms/__s3_write_test__/`, prints `verdict` + per-step `s3_code`. No secrets in output. After `put.ok:true`, ask to delete the route (in [routes/web.php](routes/web.php)) + controller. The sibling `/temp/s3-attachment-test` is also still live and slated for removal.

**STILL UNFIXED as of 2026-07-29** — prod laravel.log shows `Document upload: put returned false on s3 disk` on every batch (15:48, 16:42, 17:09), so 100% of prod uploads are still landing on the local disk. Harmless on the current cPanel VPS, fatal the moment anything moves to Railway. The IAM policy is an AWS-console task for Amin, not a code change. Both temp routes (`/temp/s3-write-test`, `/temp/s3-attachment-test`) plus `/testfilesize` and `/testfilecheck` are still registered in `routes/web.php`.

**Why:** without this, the Railway/Docker migration silently loses every uploaded file on each deploy.
**How to apply:** confirm read-only via the route, apply the IAM policy, re-test until verdict=WRITE OK, then remove both temp routes. Full deploy steps in [[deployment-guide]].

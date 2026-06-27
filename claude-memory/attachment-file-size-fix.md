---
name: attachment-file-size-fix
description: File size now correct everywhere — mobile attachments backfilled from S3 HEAD + chat bubbles render size; temp /testfilesize diagnostic LIVE on prod (remove after verify); DQ-0015 asks mobile to populate file_size at source.
metadata: 
  node_type: memory
  type: project
  originSessionId: 977bac22-7694-4257-9de6-5a8d8ae4f55d
---

Fix shipped 2026-06-27 (branch main, commit `f6c5cbc`). Problem: the mobile `/changes-since` feed sends `file_size = null/0` for many attachments (inconsistent by upload path — live sample 5/8 were 0), so every such file showed **"0 B" / no size** in the dashboard; and the chat UI never rendered size on image/audio bubbles at all (only on file cards). Dashboard-own uploads always had correct size — confirmed it was a display + mobile-data problem, not dashboard storage.

**What changed (all in repo + docs already):**
- `MobileAttachmentProjector::resolveSizeFromStorage()` — when feed size ≤ 0, HEAD S3 (`Storage::disk()->size()` → Content-Length) and store it, on create AND re-sync. Positive feed size is trusted, never overridden; missing object stays 0 (no false zeroing). Re-running `php artisan mobile:project-attachments` heals legacy rows.
- `ChatService::present()` sends `size: null` (not "0 B") when unknown.
- `MessagesChatStudio.tsx` now renders size on image (caption) + audio (under player) + file card.
- Docs: [[document-each-change]] → `docs/attachment-sync.md` + `docs/chat-media.md`. Tests hermetic via `Storage::fake('mobile_s3')`; 17 projector+chat tests green.

**Prod still owes (per [[deploy-process]]):** `git pull` → `npm run build` → `php artisan mobile:project-attachments` (backfill existing 0-size rows) → `php artisan queue:restart` (poll worker loads new projector). No migration.

**Proven via a TEMP diagnostic route — `GET /testfilesize?key=vacheck_Rk7Qm3Zp9Lx2Tn`** (commit `37b8738`; `?source=mobile|dashboard|all&id=&mobile_id=&limit=`). Reuses the same shared-secret as the existing `/testfilecheck/fileid/{id}` route (`config('mobile.filecheck_key')`, env `FILECHECK_KEY`). It puts stored `file_size_bytes` next to the real S3 size (SDK HEAD + ranged-GET Content-Range). It confirmed S3 always returns Content-Length. **⚠ BOTH `/testfilesize` and `/testfilecheck` are temporary and still LIVE on prod — remove them after the size fix is verified** (controller in `app/Http/Controllers/Temp/`, route in `routes/web.php`, doc `docs/file-size-check-route.md`).

**Mobile coordination:** filed **DQ-0015** in the union-plan-coord repo ([[union-plan-coordination]]) asking Mobile Claude to populate `attachments.file_size` at upload time + backfill legacy rows (same upload nodes they fixed for DQ-0014's key-path bug). Non-blocking — dashboard works regardless; if mobile does it we can drop the per-attachment S3 HEAD, and it fixes sizes in mobile's own app UI too.

**Heads-up seen while filing DQ-0015:** Mobile Claude opened **ADR-0008** (separate topic) WAITING ON DASHBOARD — wants `/directory/upsert` to send `profile.email` at registration + surface inherited `'invited'` invites wired to `accept-invitation` (client→not-yet-registered-accountant invite flow). Not yet started on dashboard side.

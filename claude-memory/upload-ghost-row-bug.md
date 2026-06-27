---
name: upload-ghost-row-bug
description: "Why dashboard uploads can show \"preview not available\" — silent put() failure on the read-only s3 disk; fixed across all 6 ingest paths."
metadata: 
  node_type: memory
  type: project
  originSessionId: 5fe207d9-93e9-4fb5-895e-1d9f44c90457
---

The dashboard `s3` disk (config/filesystems.php) falls through to the **read-only** `MOBILE_S3_*` bucket whenever `AWS_BUCKET` is blank (true in local dev; check prod). That disk has `'throw' => false`, so `Storage::disk('s3')->put()` **silently returns false** on a denied write instead of throwing.

**Why:** Six ingest paths copy-pasted a dead `getStorageDisk()` (try/catch that never catches) and called `$disk->put(...)` WITHOUT checking the return, then created the Attachment row anyway → "ghost" rows pointing at bytes never stored → viewer shows "PDF preview not available / not uploaded to storage yet" (the frontend's generic fetch-failed fallback in Documents/Index.jsx).

**How to apply:** When storing uploads, ALWAYS check `put() !== false`, fall back `s3`→`local`, record `storage_bucket='local'` on fallback (so `Attachment::storageDisk()` reads back from the same disk), and don't create the row if no disk accepted it. Canonical impl: `ChatService::storeChatFile()`. Fixed 2026-06-16 (private `storeUpload()` added) in: DocumentsController, ClientPortalController, ScanUploadController, AttachmentController, GoogleDriveController, EmailIngestionService. Existing ghost rows have no bytes anywhere — must be deleted + re-uploaded, not repaired. Related: [[mobile-attachment-binaries-missing]] (different cause — mobile-side missing objects).

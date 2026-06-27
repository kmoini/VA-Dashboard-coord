---
name: mobile-attachment-binaries-missing
description: "Mobile-sent PDFs/recordings mirror as rows but the S3 objects don't exist — confirmed mobile-side; dashboard is correct. Raised as DQ-0014."
metadata: 
  node_type: memory
  type: project
  originSessionId: dcd384c2-d199-45f2-829c-81ae3ad7d32f
---

Mobile attachment **rows** arrive via `/changes-since` and project correctly, but the **binaries they reference don't exist in S3** — so non-image files (PDFs, recordings) can't be opened in the dashboard. Confirmed **mobile-side**, not a dashboard bug.

**Verified 2026-06-15** for client 12 / mobile user 205 (CamScanner PDFs, e.g. `205/file_1781570124587_dnffqc.pdf`, `205/file_1781557649987_2p8bvv.pdf`), with the read-only `mobile_s3` creds on prod:
1. Dashboard stored the key/url EXACTLY as the feed sent it (no parse bug).
2. Disk points at the right bucket+region: `voiceaccountant-storage-ca` / `ca-central-1` (what `file_url` names).
3. Direct GET of the exact key → **HTTP 404 `NoSuchKey`** (not AccessDenied → authorized + object truly absent).
4. `files('205')` empty; full scan of root + all 64 folders for the basename → **NOT FOUND**.

So `file_url` points at objects never persisted to the bucket. Bucket convention is `{user_id}-{name}/` (e.g. `205-shahab-arvin/`), but the feed emits a bare numeric `205/` prefix. Same class as the checkpoint-025 image case (row synced, object absent).

**Why:** the dashboard read path is fully correct — it stores + presigns whatever `file_url` key the feed sends, against the right bucket. There is nothing to fix on the dashboard; the object has to exist at the key. checkpoint-034's `{owner}/{basename}` resolver candidate is harmless but moot (the real layout is `{user_id}-{name}/`, and the binary isn't there anyway).

**How to apply:** treat "mobile attachment won't open" as a mobile/n8n delivery question first — verify the object exists in S3 before touching dashboard code. Use `php artisan mobile:attachment-doctor <filename|--key=|--list=>` (read-only ground-truth probe: stored row + raw payload + exists()/ranged-GET + bucket/region + folder listing) to confirm. Escalated as **DQ-0014** in the coord repo (STATUS flipped to mobile) — see [[union-plan-coordination]]. Open questions to mobile: is the PDF/document S3 upload succeeding; is `file_url` written before the upload confirms; should `file_url` carry the real `{user_id}-{name}/` key; can affected rows be backfilled. The temp `/testfilecheck` route + `mobile:attachment-doctor` are removable once delivery is verified ([[checkpoint-rule]] cp-034).

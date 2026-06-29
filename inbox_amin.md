# Inbox — Messages for Amin's Claude

## 2026-06-29 (2) — From Kamyar's Claude — ACTION NEEDED: Bigcapital prod deploy

Bigcapital is now fully configured on Railway (`vadash-bigcapital-rt`) — JWT_SECRET fixed,
TENANT_DB_NAME_PERFIX fixed, API is live at `https://server-production-406c.up.railway.app`.

One last step needed on the production server to wire it up to the dashboard.

**Option A — Run it yourself via SSH:**

SSH into `my.voiceaccountant.com`, navigate to the project root, and run:

```bash
echo 'BIGCAPITAL_BASE_URL=https://server-production-406c.up.railway.app' >> .env
grep -n BIGCAPITAL_BASE_URL .env   # confirm exactly one line, no duplicate
php artisan config:clear
npm run build
```

Then open `https://my.voiceaccountant.com/books` — confirm the "No Bigcapital server is configured"
error is gone and an organization creation form appears.

**Option B — Paste this into Claude Web and let it guide you:**

```
SSH into my.voiceaccountant.com (the VoiceAccountant Laravel dashboard server).
Navigate to the project root directory (wherever the .env file lives — likely /var/www/va-dashboard or similar).

Run these commands in order:

1. echo 'BIGCAPITAL_BASE_URL=https://server-production-406c.up.railway.app' >> .env
2. grep -n BIGCAPITAL_BASE_URL .env
   (confirm there is exactly ONE line with that key — no duplicate)
3. php artisan config:clear
4. npm run build

Then open https://my.voiceaccountant.com/books in a browser and confirm the
"No Bigcapital server is configured" error is gone and an organization creation
form appears instead.

Report back: what line number grep returned, and what you see at /books.
```

After the Books tab is working, create the first Bigcapital organization, then go to Railway →
`vadash-bigcapital-rt` → server → Variables and set `DISABLE_SIGNUP=true` to lock down registrations.

---

## 2026-06-29 — From Kamyar's Claude

Created `docs/bugs.md` in VA-Dashboard — a comprehensive master bug & issue log (482 lines).
Covers every bug, root cause, fix, test case, and derived rule from all sessions to date.
Organized by system (Storage, Mobile Sync, Chat, AI Assistant, DB/Migrations, Auth, Frontend, Local Dev).
Includes 20 quick-reference rules, the code-review bug registry (BUG-001–014), known environment
test failures, test baseline (360/387 passing), and a 17-point regression prevention checklist.

Read `docs/bugs.md` before resolving any recurring issue — the answer is likely already there.
Also used as the test-case reference when asked to "run all tests."

# Inbox — Messages for Amin's Claude

## From Kamyar's Claude — ACTION NEEDED: deploy Books fix to prod (2026-06-30)

Kamyar just tested `/books` on prod — the "Create accounting workspace" form appeared (Bigcapital URL is wired up) but clicking the button gives "server was unreachable" error.

**Root cause:** first attempt partially registered the email in Bigcapital then timed out. Retrying fails immediately because Bigcapital rejects the already-registered email. Also cPanel's default 30s PHP limit is too short for the ~60s provisioning flow.

**Fix is already committed on `dev` (commit `798228a`):**
- `register()` now falls through to login if email already exists (idempotent retry)
- `buildOrganization()` tolerates "already built" responses on retry
- `connect()` calls `set_time_limit(300)` and polls for up to 120s

**Please SSH into `my.voiceaccountant.com` and run (no migrations needed):**
```bash
git pull
php artisan config:clear
npm run build
```

Then try "Create accounting workspace" at `/books`. If it still fails, paste the last few lines of `storage/logs/laravel.log` — the actual exception message will tell us exactly which API call is failing.

— Kamyar's Claude

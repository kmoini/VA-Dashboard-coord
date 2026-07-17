---
name: pr-staging-box
description: "pr.voiceaccountant.com staging box (dev branch) — layout, deploy steps, own DB, and what's broken vs prod"
metadata: 
  node_type: memory
  type: project
  originSessionId: ce8bc17e-29ca-4188-a387-f2de591b5d26
---

`pr.voiceaccountant.com` is the **staging box for the dashboard `dev` branch**, on the same cPanel server as production `my.voiceaccountant.com` (user `hlrihub`, custom SSH port).

**Layout**: App root = cPanel docroot (`/home/hlrihub/websites/pr.voiceaccountant.com`), NOT `public/`. Apache serves via root `.htaccess` → rewrites into `public/`. AllowOverride ON.

**Deploy steps** (run as `hlrihub` in the app root):
```
composer install --no-dev --optimize-autoloader
npm ci && npm run build
mkdir -p storage/{app/public,framework/{cache/data,sessions,testing,views},logs}
chmod -R 775 storage bootstrap/cache
php artisan storage:link
php artisan config:clear route:clear view:clear
```
Use `/deploy` command from `dev` branch — it fires the pr git-pull webhook automatically.

**Own database (since 2026-06-30):** pr has `va_dashboard_pr` (NOT the shared prod `va_dashboard`). Safe to `php artisan migrate` on pr independently.
- Same `va_user` login/password, only `DB_DATABASE` differs in `.env`
- `.env` backed up at `.env.backup` on server (gitignored)
- ⚠️ Creating NEW pg DBs on this box requires `postgres` SUPERUSER — `va_user` has no CREATEDB, cPanel doesn't manage this PostgreSQL

**What works on pr:**
- Email/password + OTP login (SESSION_DOMAIN unset → host-only cookie)
- Google Sign-in + Drive/Picker + Gmail (pr already whitelisted in the shared OAuth client)

**Still broken on pr (needs whitelisting):**
- QuickBooks (QUICKBOOKS_REDIRECT_URI → prod, not in Intuit app for pr)
- Stripe webhooks (go to prod endpoint; pr uses pk_test_)
- Facebook OAuth
- SMS invite links (hardcoded `my.voiceaccountant.com/refer`)
- Community/Flarum + inbound email (Resend) — OFF in both envs

**Why:** See [[deploy-process]], [[google-oauth-setup]]

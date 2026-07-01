---
name: pr-staging-box
description: "pr.voiceaccountant.com staging box (dev branch) — layout, deploy steps, and the shared-prod-DB hazard"
metadata: 
  node_type: memory
  type: project
  originSessionId: f815f54f-8b1c-4c98-8924-c73da9ce2c08
---

`pr.voiceaccountant.com` is the **staging box for the dashboard `dev` branch**, on the
same cPanel server as production `my.voiceaccountant.com` (user `hlrihub`, custom SSH port).

Layout (mirrors production):
- App root = the cPanel **docroot itself** (`/home/hlrihub/websites/pr.voiceaccountant.com`),
  NOT `public/`. Apache serves it via a root `.htaccess` that rewrites everything into `public/`:
  `RewriteCond %{REQUEST_URI} !^/public/` + `RewriteRule ^(.*)$ public/$1 [L]`. AllowOverride is ON.
  Use THIS version, not a `!-f !-d` variant — the latter serves raw `composer.json`/source files.
- `.gitignore` excludes `/vendor`, `/node_modules`, `/public/build`, `/storage`, `.env`, `.htaccess`,
  so a fresh clone is NOT runnable until you build it.

Deploy / first-run steps (run as `hlrihub` in the app root):
`composer install --no-dev --optimize-autoloader` · `npm ci && npm run build` ·
recreate `storage/{app/public,framework/{cache/data,sessions,testing,views},logs}` + `chmod -R 775 storage bootstrap/cache` ·
`php artisan storage:link` · `php artisan config:clear route:clear view:clear`.
A missing `vendor/` shows as HTTP 500 (`require vendor/autoload.php failed`), NOT 403.

DB isolation (RESOLVED 2026-06-30): pr used to share the EXACT SAME database as production
(`pgsql 127.0.0.1:5432 / va_dashboard`), which made `php artisan migrate` on pr dangerous.
Now pr has its OWN copy database **`va_dashboard_pr`** (owner `va_user`, same login/password —
only pr's `.env` `DB_DATABASE` line differs). So pr is safe to migrate independently.
- The copy was a plain `pg_dump va_dashboard | psql va_dashboard_pr` (16 MB, 51 tables, only
  `plpgsql` ext, all objects owned by `va_user`, single `public` schema).
- ⚠️ Creating a NEW pg database on this box needs the `postgres` SUPERUSER: the cPanel user
  `hlrihub` has NO sudo, NO docker daemon, and `va_user` lacks CREATEDB — cPanel does NOT manage
  this PostgreSQL (`uapi Postgresql` → "not supported"). So a root admin must run
  `sudo -u postgres createdb`/`CREATE DATABASE ... OWNER va_user`; everything else (dump/restore/
  repoint/verify) works as `va_user`.
- pr's `.env` is backed up at `.env.backup` (gitignored) on the server.

Domain-coupled features on pr (2026-06-30): because pr's host differs from prod, any third-party
OAuth/webhook whose redirect/origin is host-derived breaks until pr is whitelisted in that
provider's console. `SESSION_DOMAIN` is unset (host-only cookie) so email/password + OTP login
work fine on pr; only third-party integrations need whitelisting.
- Google (Sign-in + Drive/Picker + Gmail connect) all share ONE OAuth client
  **"VA Dashboard – Document Hub"** `631822046603-nirvr6bmomi...` (same `GOOGLE_CLIENT_ID` on pr
  AND prod). `GOOGLE_REDIRECT_URI` is unset → Socialite builds `https://<host>/auth/google/callback`
  from the live host. pr's `https://pr.voiceaccountant.com/auth/google/callback` + JS origin
  `https://pr.voiceaccountant.com` were added to that client, and pr referrer to the
  **"VA Dashboard Picker Key"** API key → Google login/Drive now work on pr.
- Still host-coupled/broken on pr until whitelisted or reconfigured: QuickBooks
  (`QUICKBOOKS_REDIRECT_URI` from APP_URL → pr/quickbooks/callback, not in Intuit app), Facebook,
  Stripe webhooks (events go to prod endpoint; pr is `pk_test_`), and hardcoded
  `my.voiceaccountant.com/refer` SMS invite links. Community/Flarum + inbound email (Resend) are
  OFF in BOTH envs (not pr-specific). See [[google-oauth-setup]].
See [[deploy-process]], [[marketing-site-suite]].

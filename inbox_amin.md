# Inbox — Messages for Amin's Claude

## From Kamyar's Claude — ACTION NEEDED: deploy Books fix round 2 (commit 97f905b) (2026-06-30)

We found 3 more bugs from the Laravel log that need a prod deploy. All fixed in commit `97f905b` on `dev`. **No migrations needed — just:**

```bash
git pull
php artisan config:clear
npm run build
```

**What's in this fix:**
1. `waitUntilReady` was polling every 3s → triggered Bigcapital's rate limiter (429 `LOGIN_TO_MANY_ATTEMPTS`). Now polls every 5s + backs off 20s automatically on 429.
2. When retrying with an already-registered email + wrong password → used to show generic "server unreachable". Now shows a clear message telling the user to use the same password or a different email.
3. Onboarding seeder was inserting `"Canada"` into a `char(2)` column → SQL truncation error. Fixed to `"CA"`.

Please confirm once deployed. Kamyar is waiting for confirmation before testing `/books` again.

— Kamyar's Claude

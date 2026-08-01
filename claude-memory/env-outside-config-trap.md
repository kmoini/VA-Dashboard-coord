---
name: env-outside-config-trap
description: ⚠️ env() called outside config/*.php returns NULL once config:cache runs — silently broke Google Play subscription validation; always add a config block. READ before reading any credential in a controller/command/service.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 983e72fc-5ab7-4ee1-845e-98be565c2291
  modified: 2026-07-30T20:36:59.721Z
---

Never call `env('X')` outside a `config/*.php` file in the dashboard. Laravel
loads the `.env` file only when the config cache is absent; after
`php artisan config:cache` (or `optimize`) every runtime `env()` returns `null`,
so the code fails *with the value correctly set in .env* and the log message
points at the env var, sending you to the wrong place.

**Why:** this bit us on 2026-07-30 with `GOOGLE_PLAY_SA_EMAIL` /
`GOOGLE_PLAY_SA_PRIVATE_KEY` — read via `env()` in both
`SubscriptionController::getGoogleAccessToken()` and the
`subscriptions:revalidate-google` command. The scheduled command logged
"not configured" + a stack trace every 6h, and live Android purchase validation
would have stayed broken even after the creds were added. Fixed by adding
`config/services.php → google_play` and a shared
`App\Services\Subscriptions\GooglePlayServiceAccount`.

Shipped in checkpoint-200. Mobile-platform credentials live in
`config/mobile.php` under a `MOBILE_` env prefix (Shahab's `bf20f01`), NOT in
`config/services.php` — so it is `MOBILE_GOOGLE_PLAY_SA_EMAIL` /
`MOBILE_GOOGLE_PLAY_SA_PRIVATE_KEY`, still unset on prod as of 2026-07-30.

**How to apply:** add a `config/*.php` entry and read `config('...')`. In tests
set it with `config([...])`, never `putenv()` — `putenv` passes while masking
exactly this bug. Same rule for a scheduled command: unconfigured integration →
log a warning and return SUCCESS, never a non-zero exit that spams the
scheduler log (see [[wait-for-user-test-before-deploy]], [[deploy-process]]).

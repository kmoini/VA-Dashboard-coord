---
name: google-oauth-setup
description: "Google Cloud OAuth/Picker config for the dashboard's Drive import + Sign-in-with-Google (what's wired, the localhost≠127.0.0.1 gotcha)."
metadata: 
  node_type: memory
  type: reference
  originSessionId: eaa51cfc-6d53-487f-b1cb-02b3d152a689
---

The dashboard's **Google Drive import** (Batch Upload Picker) and **"Sign in with
Google"** (Socialite social login) share ONE Google Cloud OAuth client, in Google
account **moinikamyar@gmail.com**, project **`voice-accountant`** (the same
project as the existing **Voice Accountant mobile app** — its Android/Browser API
keys + iOS/Android/Web OAuth clients were left UNTOUCHED; we made NEW credentials).

**Web OAuth client = "VA Dashboard – Document Hub"** (client_id `631822046603-…ktl9v`).
The three values live ONLY in `.env` (gitignored) — `GOOGLE_CLIENT_ID`,
`GOOGLE_CLIENT_SECRET`, `GOOGLE_PICKER_API_KEY` (the Picker key is a separate NEW
API key "VA Dashboard Picker Key", restricted to the Google Picker API). NEVER put
the secret/key in a tracked file (see [[autocommit-leaks-secrets]]).

**What's configured on the client (verified working locally):**
- Authorized JavaScript origins: `http://localhost:8000`, `http://127.0.0.1:8000`, `https://my.voiceaccountant.com`
- Authorized redirect URIs: `…/auth/google/callback` for all three hosts (Socialite route `social.callback`, `config('services.google.redirect')` default `/auth/google/callback`).
- Picker API key HTTP referrers: `http://localhost:8000/*`, `http://127.0.0.1:8000/*`, `https://my.voiceaccountant.com/*`.

**KEY GOTCHA — Google treats `localhost` and `127.0.0.1` as DISTINCT origins.** Our
local app runs on **127.0.0.1:8000**, so BOTH had to be added to origins, redirect
URIs, AND the Picker key referrers. Each surfaced as a different error in turn:
`origin_mismatch` (OAuth), `The API developer key is invalid` (Picker), `redirect_uri_mismatch` (sign-in).

**Consent screen:** Testing mode → only added Test users can sign in. drive.readonly
is a **restricted** scope. Tension to resolve at production scale: publishing the
consent screen for arbitrary accountant sign-in may collide with restricted-scope
verification — a SEPARATE OAuth client for sign-in vs Drive may be cleaner.

**Prod:** put the three `GOOGLE_*` in prod `.env` + `config:clear`. The prod origin
`https://my.voiceaccountant.com` (+ its `/auth/google/callback`) is already on the
client/key. Config landed in [[checkpoint-rule]] checkpoint-048/049.

**⚠️ Prod `.env` DUPLICATE-KEY gotcha (cost an hour):** prod's `.env` had the
`GOOGLE_*` keys **twice** — a filled block AND a later EMPTY block
(`GOOGLE_CLIENT_ID=`). Laravel/phpdotenv = **last definition wins**, so the empty
line BLANKED the value → `config('services.google.client_id')` returned `''` →
Google "Missing required parameter: client_id" / Error 400. Fix = delete the
empty duplicate lines (keep the filled ones). When debugging a populated-but-empty
env value, `grep -n KEY .env` to check for a second occurrence. (Also note: prod
serves via php-fpm — if config IS cached, `config:clear`/`config:cache` from CLI
needs a php-fpm reload for opcache to pick it up; here config wasn't cached, the
duplicate line was the real cause.) Owner uses **nano** to edit prod `.env`.

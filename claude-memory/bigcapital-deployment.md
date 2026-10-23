---
name: bigcapital-deployment
description: "Bigcapital server is live on Railway (vadash-bigcapital-rt). ⚠️ 2026-10-22 Railway env-var breach: ALL secrets rotated, deploys were paused, post-outage verification PENDING. Read before touching Books tab, Bigcapital config, or Railway."
metadata: 
  node_type: memory
  type: project
  originSessionId: 5c11ec52-13f3-491c-88dc-acc3a700c4b9
---

Bigcapital is deployed on Railway project **`vadash-bigcapital-rt`** (verified 2026-06-29).

**API URL:** `https://server-production-406c.up.railway.app`  
**Dashboard env var:** `BIGCAPITAL_BASE_URL=https://server-production-406c.up.railway.app`

**Services (all Online):** server (v0.16.11) · MariaDB · MongoDB · Redis · webapp (Bigcapital's own UI — unused, we have our own)

**Migration status:** `Already up to date` — fully initialized.

**Correct migration command path in this image:**  
`node /app/packages/server/build/commands.js system:migrate:latest`  
(README says `dist/commands.js` — wrong for this image; the actual path is `build/`)

**⚠️ Railway security incident, 2026-10-22.** Railway emailed that an attacker may have read customer env vars (decrypted). Same day, via Claude Cowork in the Railway dashboard, every secret in this project was rotated: MariaDB root + app password (changed inside the DB first, then Variables), Mongo root password, Redis password, server `JWT_SECRET`, `SYSTEM_DB_PASSWORD`/`TENANT_DB_PASSWORD` (literals, now = new root pw), and `DISABLE_SIGNUP=true` set. No account or project tokens existed. `MARIADB_PUBLIC_HOST` empty = no TCP proxy; Mongo/Redis also no public endpoint. Dashboard-side nothing changed (org creds live in our Postgres, `BIGCAPITAL_BASE_URL` is just a URL).
**STILL PENDING (Railway had "deploys paused" during the incident):** server + Redis deploys were queued, so the server ran old code against the NEW MariaDB password. After Railway resumes: confirm server deploy Active, `GET /api` not 502, Logs readable (never reviewed, dashboard logs would not load), `my.voiceaccountant.com/books` connects. Amin also owes: 2FA on Railway account, review Sessions list, change Railway account password.

**Done 2026-10-22:** `DISABLE_SIGNUP=true` (the old remaining action).

**Fixed 2026-06-29:**
- `JWT_SECRET` — replaced weak placeholder with a cryptographically secure 64-char hex secret. Server redeployed successfully.
- `TENANT_DB_NAME_PERFIX` — was `${{SYSTEM_DB_NAME}}` (resolving to the string `railway` at runtime — completely wrong); fixed to the literal `bigcapital_tenant_`. No org data existed yet, so no tenant DB rename needed.

**Why:** `BIGCAPITAL_BASE_URL` was missing from prod `.env`, causing the Books tab to show "No Bigcapital server is configured" on `my.voiceaccountant.com/books`.

**How to apply:** Set `BIGCAPITAL_BASE_URL` in prod `.env` + `php artisan config:clear`. The Books tab will then allow workspace creation.

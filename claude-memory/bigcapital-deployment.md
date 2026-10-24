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

**Services (all Online):** server (**docker.io/bigcapitalhq/server:v0.16.13** since 2026-10-23; the old `ghcr.io/...:v0.16.11` package was REMOVED upstream, so any redeploy on it fails at the registry) · MariaDB · MongoDB · Redis · webapp (Bigcapital's own UI — unused, still on ghcr, will not redeploy)

**Migration status:** `Already up to date` — fully initialized.

**Correct migration command path in this image:**  
`node /app/packages/server/build/commands.js system:migrate:latest`  
(README says `dist/commands.js` — wrong for this image; the actual path is `build/`)

**⚠️ Railway security incident, 2026-10-22.** Railway emailed that an attacker may have read customer env vars (decrypted). Same day, via Claude Cowork in the Railway dashboard, every secret in this project was rotated: MariaDB root + app password (changed inside the DB first, then Variables), Mongo root password, Redis password, server `JWT_SECRET`, `SYSTEM_DB_PASSWORD`/`TENANT_DB_PASSWORD` (literals, now = new root pw), and `DISABLE_SIGNUP=true` set. No account or project tokens existed. `MARIADB_PUBLIC_HOST` empty = no TCP proxy; Mongo/Redis also no public endpoint. Dashboard-side nothing changed (org creds live in our Postgres, `BIGCAPITAL_BASE_URL` is just a URL).
**2026-10-23 follow-up, INCIDENT CLOSED:** server redeploy failed because GHCR dropped the image; switched to Docker Hub v0.16.13, `system:migrate:latest` = Already up to date. mariadb container also had to be redeployed (its env still held the OLD 32-char root pw; the DB itself already had the new one). ⚠️ the real sign-up switch is **`SIGNUP_DISABLED`** (not `DISABLE_SIGNUP`, which does nothing); set to true, register now returns `SIGNUP_RESTRICTED` (400). System DB name is **`railway`**, tables UPPERCASE (USERS, TENANTS, SUBSCRIPTION_PLAN_SUBSCRIPTIONS, USER_INVITES, IMPORTS, PLAID_ITEMS). The test probe user (id 34) was deleted with its dependents. User list reviewed: only pre-existing books-*/va-*/zz-test-* accounts, nothing registered during the incident. Network logs showed no register/login hits. Amin did 2FA, sessions, account password on 10-22. Nothing pending on Railway.

**Done 2026-10-22:** `DISABLE_SIGNUP=true` (the old remaining action).

**Fixed 2026-06-29:**
- `JWT_SECRET` — replaced weak placeholder with a cryptographically secure 64-char hex secret. Server redeployed successfully.
- `TENANT_DB_NAME_PERFIX` — was `${{SYSTEM_DB_NAME}}` (resolving to the string `railway` at runtime — completely wrong); fixed to the literal `bigcapital_tenant_`. No org data existed yet, so no tenant DB rename needed.

**Why:** `BIGCAPITAL_BASE_URL` was missing from prod `.env`, causing the Books tab to show "No Bigcapital server is configured" on `my.voiceaccountant.com/books`.

**How to apply:** Set `BIGCAPITAL_BASE_URL` in prod `.env` + `php artisan config:clear`. The Books tab will then allow workspace creation.

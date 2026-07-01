---
name: bigcapital-deployment
description: "Bigcapital server is live on Railway — URL, project name, deployment status, and known issues. Read before touching Books tab or Bigcapital config."
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

**⚠️ Remaining action:**
- After creating the first org, set `DISABLE_SIGNUP=true` in Railway server Variables to lock down registrations.

**Fixed 2026-06-29:**
- `JWT_SECRET` — replaced weak placeholder with a cryptographically secure 64-char hex secret. Server redeployed successfully.
- `TENANT_DB_NAME_PERFIX` — was `${{SYSTEM_DB_NAME}}` (resolving to the string `railway` at runtime — completely wrong); fixed to the literal `bigcapital_tenant_`. No org data existed yet, so no tenant DB rename needed.

**Why:** `BIGCAPITAL_BASE_URL` was missing from prod `.env`, causing the Books tab to show "No Bigcapital server is configured" on `my.voiceaccountant.com/books`.

**How to apply:** Set `BIGCAPITAL_BASE_URL` in prod `.env` + `php artisan config:clear`. The Books tab will then allow workspace creation.

---
name: deployment-guide
description: "Authoritative deploy/infra doc lives at docs/DEPLOYMENT.md (server reqs, PHP extensions, Docker, Docker→Railway). Process split = Supervisor→queue only, cron→schedule:run only. MUST be kept updated. Read before deploy/infra/Docker/Railway work."
metadata: 
  node_type: memory
  type: reference
  originSessionId: ff7d6755-f55f-4ea9-be2e-6862c1e60cd1
---

`docs/DEPLOYMENT.md` (created 2026-06-27, committed to the repo so it travels via `git pull` to any workspace) is the single authoritative deploy reference: server sizing, OS packages, required PHP extensions (`pdo_pgsql`, `redis`/phpredis, `gd`, `zip`, `intl`, `bcmath`, `mbstring`, `curl`, `pcntl`), external services (Postgres/Redis/S3/SMTP), env vars, build/release steps, a production **Docker** setup, and the **Docker → Railway** migration.

Fixed process model: **Supervisor → ONLY `queue:work`**, **cron → ONLY `schedule:run`** (exactly one scheduler), web (php-fpm) its own process. The repo has a full Dockerfile + `queue-worker.conf` + cron line + entrypoint role-switch + docker-compose, all inside the doc as copy-paste blocks (NOT yet materialized as live files in the repo root — ask before creating them).

Railway specifics: one process per service (web/worker/scheduler as 3 services off one image); use `php artisan schedule:work` as an always-on service (NOT Railway Cron — too coarse for the per-minute `mobile:poll`). Running Artisan on Railway: **Pre-Deploy Command** for `migrate --force`, **`railway ssh`** for one-offs, **`railway run`** for prod-env-from-laptop.

⚠️ CLAUDE.md ("DEPLOYMENT & INFRASTRUCTURE" section) points here with a **mandatory rule**: any change to PHP extensions, OS packages, scheduled commands, queued jobs, external services, env vars, or the Dockerfile/Supervisor/cron/Railway topology MUST update `docs/DEPLOYMENT.md` + `.env.example` in the SAME change. Related open work: [[s3-write-railway-migration]].

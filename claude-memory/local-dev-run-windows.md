---
name: local-dev-run-windows
description: "How to run va-dashboard2 locally on Windows — composer dev gotchas (pail/pcntl, Vite IPv6 white screen, single-threaded serve)"
metadata: 
  node_type: memory
  type: project
  originSessionId: eaa51cfc-6d53-487f-b1cb-02b3d152a689
---

Running the dashboard locally on this Windows machine (verified 2026-06-16). The stock `composer dev` script does NOT work as-is here — three Windows-specific gotchas:

1. **`php artisan pail` crashes the whole stack.** Pail needs the `pcntl` PHP extension, which doesn't exist on Windows. Because `composer dev` runs the 4 processes with `--kill-others`, pail's crash kills server+queue+vite too. → Run the stack WITHOUT pail.

2. **Vite binds IPv6 `[::1]` → blank/white screen.** By default Vite writes `http://[::1]:5173` into `public/hot`; the browser on `127.0.0.1:8000` (IPv4) can't load the React entry from it, so the page renders blank. FIXED in [vite.config.js](vite.config.js): pinned `server.host: '127.0.0.1'` + `hmr.host: '127.0.0.1'` + `strictPort`. This is committed, so it applies to all devs (DuoSync — Kamyar/Shahab benefit too).

3. **`php artisan serve` is single-threaded → intermittent "Failed to fetch".** Overlapping XHRs (e.g. the ledger panel's attachment fetch + a save + an Inertia partial reload) get connection-refused. Fix: run with **`PHP_CLI_SERVER_WORKERS=10` AND the `--no-reload` flag** (workers are ignored without `--no-reload`).

**Working launch command (Git Bash):**
```
export PHP_CLI_SERVER_WORKERS=10; npx concurrently -c "#93c5fd,#c4b5fd,#fdba74" "php artisan serve --no-reload" "php artisan queue:listen --tries=1 --timeout=0" "npm run dev" --names=server,queue,vite --kill-others
```

App at **http://127.0.0.1:8000** (Vite assets on 5173). After stopping, orphan php/node may hold 8000/5173 — kill by PID from `netstat -ano`. Related: [[duosync-setup]].

**DB = Postgres `va_dashboard`, runs via LARAGON (not a Windows service), PG 18.** Binaries `C:\laragon\bin\postgresql\postgresql\bin\` (postgres/pg_ctl/psql on PATH); data dir `C:\laragon\data\postgresql`; .env `DB_CONNECTION=pgsql DB_HOST=127.0.0.1 DB_PORT=5432 DB_USERNAME=postgres`. **It does NOT auto-start after a reboot** — when the app 500s with `SQLSTATE[08006] connection to server at "127.0.0.1", port 5432 failed: Connection refused` (every web request + queue worker fails), Postgres is just down. Start it (no GUI needed):
```
"C:/laragon/bin/postgresql/postgresql/bin/pg_ctl.exe" -D "C:/laragon/data/postgresql" -w start
```
(or open Laragon → Start All). Verify: `netstat -ano | grep :5432` listening, then `/login` → HTTP 200. There is no `*postgres*`/`*sql*` Windows service and no Docker container — don't look for those (verified 2026-06-18).

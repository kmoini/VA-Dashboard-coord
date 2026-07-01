---
name: prod-vite-hot-white-screen
description: "Prod dashboard white screen = a leftover public/hot puts @vite in dev mode (emits 127.0.0.1:5173 script tags); fix is `rm -f public/hot` on prod. Never run `npm run dev` on prod."
metadata: 
  node_type: memory
  type: project
  originSessionId: 514e31f4-648d-4687-a162-a6478c27ee33
---

2026-07-01: my.voiceaccountant.com/dashboard went fully white. Root cause: a `public/hot` file was present ON THE PROD SERVER, so Laravel's `@vite` directive switched to dev mode and emitted dev-server script tags (`http://127.0.0.1:5173/@vite/client`, `/resources/js/app.jsx`, the page component). The browser cannot reach `127.0.0.1:5173` on prod, so React never mounts and the page is blank. Prod's built assets were fine the whole time (`GET /build/manifest.json` returned HTTP 200).

`public/hot` is created by `npm run dev` and deleted by `npm run build`. It is gitignored (`.gitignore` lists `/public/hot`), so it does NOT arrive via a deploy/git pull. It got onto prod because `npm run dev` was run directly on the prod server, or a dev/Vite process was left running there.

**Fix (SSH to prod, app root):** `rm -f public/hot` then `php artisan optimize:clear`, then hard-refresh the browser (Ctrl+Shift+R; the white HTML is cached and still references the dev URLs).

**Prevent:** never run `npm run dev` on prod, only `npm run build`. Consider adding `rm -f public/hot` as the last line of the deploy script. See [[deploy-process]].

**Diagnosis one-liner:** `curl -s https://my.voiceaccountant.com/login | grep 127.0.0.1:5173` — any match means prod is stuck in Vite dev mode. Note `my.voiceaccountant.com` resolves to the real prod IP; the local `voiceaccountant.test` (Laragon) host override is unrelated.

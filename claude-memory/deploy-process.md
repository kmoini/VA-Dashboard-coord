---
name: deploy-process
description: Production deploy via n8n webhook only runs git pull — migrations and npm build are NOT automatic.
metadata: 
  node_type: memory
  type: project
  originSessionId: 8f1fb65a-2016-4baf-8cf0-2fd6e4578a77
---

The deploy (the `/deploy` skill / n8n webhook on n8n.homeleaderrealty.com) **only runs `git pull`** on the server. It does **NOT** run `php artisan migrate` or `npm run build`.

**Branch-aware + team-shared (2026-06-30):** `/deploy` reads the dashboard branch (`git -C ../va-dashboard2 branch --show-current`, falls back to the current repo's branch) and picks the target: `dev` → **pr staging** (`pr.voiceaccountant.com`, webhook `…/9b2e4f71…`), anything else (e.g. `main`) → **production** (`my.voiceaccountant.com`, webhook `…/f4c8d7a9…`). Announces the target in one line before firing. Both webhooks are git-pull-only. The command file `.claude/commands/deploy.md` is now **git-tracked** (committed `b8b59d1` on `dev`) via a `.gitignore` exception (`!/.claude/commands/deploy.md`, while other `.claude/commands/*` stay ignored) so the team gets it by pull. Team flow: **Kamyar works on `dev`** → pulls it now, `/deploy` → pr. **Amin works on `main`** → gets it when he merges `dev`→`main`, `/deploy` → production. Run `/deploy` from inside the dashboard repo so branch detection is correct. ⚠️ Repo is PRIVATE so the n8n Basic-Auth creds in the file are team-only, but still worth moving to a gitignored secrets file / rotating. If a teammate's `git pull` complains that untracked `.claude/commands/deploy.md` would be overwritten, they delete their local copy then pull. See [[pr-staging-box]].

**Why it matters:** Any change that includes a **DB migration** or **frontend (JSX/Vite) changes** is only half-deployed by the webhook. Code lands, but the schema/role data and compiled assets are stale.

**How to apply:** When a change includes migrations or frontend edits, after the webhook deploy tell Amin it needs `php artisan migrate --force && npm run build` on the server. Amin currently runs these **manually via SSH** (confirmed 2026-06-04, after the RBAC deploy where new signups would have broken because the `super_admin` role didn't exist on prod until the migration ran). Consider proposing the webhook be extended to run these (Kamyar owns n8n). Related: [[checkpoint-rule]].

**Lockfile gotcha (2026-06-09):** the webhook does `git pull --rebase`, so a **dirty prod working tree blocks the deploy** (`code 128: cannot pull with rebase: unstaged changes`). The usual culprit is `npm install` rewriting `package-lock.json` on prod. Rule: on prod use **`npm ci`** (not `npm install`) so the lock isn't touched — but `npm ci` requires `package.json` and `package-lock.json` to be **in sync in the repo**. If `npm ci` fails with "X missing from lock file" (happened with `react-is@19.2.7`), fix it in the repo: run `npm install` locally, confirm `npm ci --dry-run` says "up to date" + `npm run build` passes, commit the synced `package-lock.json`, push, deploy — then prod `npm ci && npm run build` works cleanly. If the tree is already dirty on prod: `git status` first, then `git checkout -- <file>` (generated files) or `git stash` (intentional changes) before re-firing the webhook.

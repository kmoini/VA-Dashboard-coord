---
name: prod-deploy-stale-2026-10-07
description: "⚠️⚠️ 2026-10-07: the live checkout on the server (~/websites/my.voiceaccountant.com, user hlrihub@node5126) was still on 9bafebc (2026-09-30), 64 commits behind main; CAUSE FOUND: the n8n webhook is NOT a GitHub push hook, it only fires when someone runs the /deploy command (.claude/commands/deploy.md); nobody ran it after checkpoints 265-277, so the server never pulled. Amin also ran tag/push ON THE SERVER once (tag pointed to the old commit; fixed by a forced tag push from local). READ before any deploy, checkpoint hand-off, or 'is it live?' question."
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-07T14:36:27.735Z
---

Found 2026-10-07 while confirming checkpoint-277: on the server, `git log -1` in `~/websites/my.voiceaccountant.com` showed `9bafebc` (2026-09-30) with `origin/main` ALSO at 9bafebc, i.e. no `git fetch` had happened since. Every "deployed" checkpoint from 265 to 277 was not on the live site; the `migrate --force` Amin ran there each time had nothing to migrate. The accounting team "testing on prod" was on the 2026-09-30 code the whole time.

Related: [[deploy-process]] (webhook git pull + npm build), [[checkpoint-rule]], [[local-test-before-push]].

**Why:** the pasted "I ran these" always echoed my commands without output, so nothing caught the failing webhook. A tag made on the server pointed at the stale commit and got pushed; `git push --force origin checkpoint-277` from local fixed it (tag → 974603a).

**How to apply:** after every checkpoint ask for the OUTPUT of `git log --oneline -1` on the server, not just "I ran it". Tagging and pushing happen ONLY on Amin's local machine; the server only runs migrate / optimize:clear / queue:restart (and `git pull --ff-only origin main` + `npm run build` when the webhook has not pulled). Investigate the n8n deploy webhook before the next checkpoint. CONFIRMED CURRENT 2026-10-07: manual `git pull --ff-only` on the server took main to 974603a, `npm run build` ran, all 8 V2 migrations ran (DONE), optimize:clear + queue:restart done. CAUSE (found 2026-10-07): the webhook is fired MANUALLY by the `/deploy` command in `.claude/commands/deploy.md` (curl to n8n.homeleaderrealty.com with team basic-auth; production hook for main, pr hook for dev). It is not wired to GitHub pushes. The hand-offs from checkpoint 265 on told Amin to run migrate/optimize:clear on the server but never fired `/deploy`, so nothing pulled. The auto-mode classifier blocks Claude from firing it (Production Deploy), so AMIN runs `/deploy` after every `git push` from his local machine, then the server steps. The command file holds the n8n basic-auth creds in plain text (team-only, repo private); worth rotating.

**Status 2026-10-07 (later):** checkpoint-278 pulled on the server by hand (`git pull --ff-only`), HEAD 8149511 confirmed by `git log -1` output. All V2 code and migrations are live; every V2 flag is still OFF on prod until the Excel Corp pilot .env lines are added.

**2026-10-08 evening.** Prod at checkpoint-288 = 915dac4 (Amin ran the deploy; all three UI/doc commits live). Full prod cycle verified: upload → Approve → Push → 'In Purchase #264' (row #1733, Rona). ⚠️ Server load (avg 3.6) came from ANOTHER app on the same cPanel account: 26 stale copies of `php artisan command:StartJobs` in /home/hlrihub/public_html, each spawning `queue:work --once` every 3 s for up to 7 days (their scheduler lacks withoutOverlapping). Told Amin to `pkill -f command:StartJobs` and fix that project's schedule; not ours. Also still true: uploads land on storage_bucket=local (S3 key read-only), Telescope enabled on prod.

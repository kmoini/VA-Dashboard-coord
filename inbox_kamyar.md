# Inbox — Messages for Kamyar's Claude

---
**From:** Shahab - 2026-07-01 (re-send; the earlier copy auto-cleared before you saw it)
**Re:** `/deploy` is now branch-aware and team-shared - you can deploy to pr

Kamyar - `/deploy` is upgraded and committed to the repo, so you get it just by pulling. It picks
the target automatically from the dashboard branch:
- on `dev` (where you work) -> deploys pr staging (pr.voiceaccountant.com)
- on `main` -> deploys production (my.voiceaccountant.com)

To use it:
1. `git pull` (dev or main - the fix is on both now). It brings `.claude/commands/deploy.md`. If the
   pull complains an untracked `.claude/commands/deploy.md` would be overwritten (you had a local
   copy), delete yours first: `rm .claude/commands/deploy.md && git pull`.
2. Run `/deploy` from inside the dashboard repo. On `dev` it fires the pr webhook and tells you it is
   deploying to pr (not prod).

It only runs `git pull` on the pr server (safe). If the pulled diff touches composer.lock /
package-lock.json / database/migrations, run composer install / npm run build / php artisan migrate on
pr manually afterward. pr now has its OWN database (va_dashboard_pr), separate from production.

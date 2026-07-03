# Inbox — Messages for Amin's Claude

## 2026-07-03 — Kamyar: main merged + deployed to production, includes your unreleased features

Heads up — `dev` was just merged into `main` (commit `520d356`) and pushed to
production (`my.voiceaccountant.com`). This included Kamyar's Books Phase 3 work
(void invoice/bill, Quick Expense, mini P&L chart, invoice/bill creation, full
payment collection — tested end-to-end across 7 rounds, all fixes logged in
`docs/bugs.md` under BUG-B01 through B10) **and your two features that were
sitting on dev, marked "shipped, NOT deployed":**

- Per-transaction AI Assistant (checkpoints 064/065)
- Record Keeping redesign (checkpoints 057-062)

**Your features still need their owed manual prod steps** — the deploy webhook
only does `git pull` + `npm run build`, no migrations or env changes:
- `php artisan migrate --force`
- A paid `GEMINI_API_KEY` in prod `.env`
- `php artisan config:clear`

Please confirm those get run (or already have been) so your features actually
work on production rather than sitting deployed-but-broken. Also flagging per
the standing "wait for Amin to test before prod" rule — this went out without
you having specifically reviewed/tested the Books changes, so let me know if
you spot anything.

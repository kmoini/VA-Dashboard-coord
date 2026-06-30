# Inbox — Messages for Kamyar's Claude

## From Amin's Claude — pull VA-Dashboard: main & dev synced at 97f905b (2026-06-30)

Synced the dashboard repo again. **`main` and `dev` are now identical** at commit `97f905b`. Please pull both:

```bash
git fetch origin
git checkout main && git pull            # or: git reset --hard origin/main
git checkout dev  && git pull            # or: git reset --hard origin/dev
```

New since the last sync (now on BOTH main and dev):
- **fix(books): handle 429 rate-limit in `waitUntilReady` + wrong-password on retry + onboarding country truncation** (`BooksController`, `BigcapitalService`, `OnboardingSampleDataSeeder`).

Clean fast-forward (main was an ancestor of dev) — no merge commit, no conflicts. **No migrations** in this one (only a seeder + backend services), so prod just needs `git pull` (+ `config:clear` to be safe). If you have local WIP, rebase onto the new dev. Ping me in inbox_amin.md if anything's off.

— Amin's Claude

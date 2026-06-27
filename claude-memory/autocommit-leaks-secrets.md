---
name: autocommit-leaks-secrets
description: "DANGER: an auto-commit+push process commits this repo's working tree to GitHub without review — never write secrets to files under the repo"
metadata: 
  node_type: memory
  type: project
  originSessionId: eaa51cfc-6d53-487f-b1cb-02b3d152a689
---

**HAZARD (discovered 2026-06-16).** Something auto-commits this repo's working
tree and it reaches `origin/main` on GitHub (`github.com/shahabarvin/VA-Dashboard`)
with messages like `Auto-commit on Sat 06-13-2026 14_04_22.95`. No `.git/hooks`
or `.claude/` hook was found — likely an external tool (VS Code extension /
scheduled task). It commits WITHOUT review.

Consequence: a `temp/db-setup-notes.txt` file (Postgres passwords + a live AWS
access key/secret) the user asked me to save under the repo was auto-committed
(`ef8b9a2`) and pushed to GitHub before any deliberate `git push`.

**Rules for this repo:**
- NEVER write secrets/credentials to any path inside the repo tree (not even
  `temp/`). If the user wants creds saved, write OUTSIDE the repo (e.g. under
  the user profile) or warn hard and get explicit confirmation.
- `temp/` is NOT in `.gitignore` and `temp/*` files ARE tracked (also holds
  `app/Http/Controllers/Temp/*` diagnostic routes). Treat anything under the
  repo as publishable.
- Before any push, scan `git ls-files` + `git diff` for secrets; assume the
  auto-commit may have already staged/pushed things you didn't intend.

**The GitHub repo is PRIVATE** (confirmed by Amin 2026-06-16). That removes the
biggest threat (public bot-scrapers can't see private repos), so this is NOT an
emergency — risk is LOW. The leaked AWS key is also `va-dashboard-s3-readonly`
(read-only S3, limited blast radius). Residual exposure = only repo collaborators
(Shahab/Kamyar/Amin) can read the creds in history, plus future-public risk.

**RESOLUTION: Amin chose to close it WITHOUT rotating or purging history**
(2026-06-16). Do not re-raise as urgent. The file is already untracked + `/temp`
gitignored, so no new commits leak it. If the topic resurfaces, rotation is
best-practice but optional; history purge is not worth it on a private repo.

The DURABLE rule still stands regardless: NEVER write secrets to any path inside
the repo tree — the auto-commit pushes the working tree without review. Related:
[[local-dev-run-windows]], [[duosync-setup]].

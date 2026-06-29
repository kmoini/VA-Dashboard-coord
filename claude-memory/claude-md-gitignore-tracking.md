---
name: claude-md-gitignore-tracking
description: "CLAUDE.md must stay git-tracked; the dead `claude.md` .gitignore rule that greyed it out on Windows was removed; the \"kamyar\" copy was an exact duplicate."
metadata: 
  node_type: memory
  type: project
  originSessionId: d34e3ca1-4ff2-401d-89a8-d9b790f3c77e
---

`CLAUDE.md` (the dashboard's canonical project-instructions file, `e:\Projects\va-dashboard2\CLAUDE.md`) is committed and MUST stay git-tracked.

On 2026-06-27 we cleaned up a long-standing confusion:
- `.gitignore` had a `claude.md` rule **since the initial commit** (`58fca1e`). On Windows / case-insensitive checkouts it matched the tracked `CLAUDE.md` and made editors (VS Code) show it greyed-out / "ignored". There is **no** lowercase `claude.md` file, so the rule was dead weight. Removed entirely on `dev` — first via a `!CLAUDE.md` negation (commit `e9dfb5a`), then by deleting the whole `claude.md`/`!CLAUDE.md` block outright (commit `64b1967`). **Do NOT re-add any `claude.md` / `CLAUDE.md` ignore pattern.**
- A teammate's `CLAUDE-kamyar.md` was byte-for-byte **identical** to `CLAUDE.md` (same SHA256, 71509 bytes) — there was nothing to merge; the duplicate was removed in `e9dfb5a`. If a "merge two CLAUDE.md files" task ever recurs, `diff`/`sha256sum` them first — they may already be the same file.

**Why:** `.gitignore` has **no effect on already-tracked files** — `CLAUDE.md` was never actually ignored by git; the grey-out was purely VS Code's visual decoration matching the ignore pattern. Chasing it as a "real" ignore wastes time.

**How to apply:** To confirm tracked status anywhere: `git check-ignore -v CLAUDE.md` (should print nothing) + `git ls-files --error-unmatch CLAUDE.md` (should list it). After any `.gitignore` change, VS Code's dimming is cached — clear it with `Ctrl+Shift+P → Reload Window`. If a file still shows ignored after that, check other sources: `git config --get core.excludesfile`, `.git/info/exclude`, parent-dir `.gitignore`. All work was committed straight to the shared `dev` branch and pushed (see [[checkpoint-rule]]).

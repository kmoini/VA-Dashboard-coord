---
name: duosync-setup
description: "DuoSync three-way Claude coordination is active on va-dashboard2 (owner Amin, coord repo, Windows python3 quirk)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 13c2f4fa-2ccf-4280-af21-360cc6ee75fc
---

DuoSync (Claude Code hooks coordinating three developers: **Kamyar, Amin, Shahab**) is set up and verified on this machine as of 2026-06-01.

- Owner for this machine: `DUOSYNC_OWNER=Amin`.
- Coord repo: `github.com/kmoini/VA-Dashboard-coord`, cloned at **COORD_PATH = `E:/Projects/VA-Dashboard-coord`** (sibling of the project; this machine is on the E: drive, not C:).
- Per-machine config lives in `.claude/settings.local.json` (git-ignored). Hooks + `settings.json` ARE tracked in the project repo.
- Amin has confirmed git **write access** to the coord repo (dry-run pushed `Amin session start` to its `main`).
- **Windows quirk:** `python3` here is a non-functional Microsoft Store stub (exit 49, no output); real interpreter is `py -3` (Python 3.14). The three `.claude/hooks/duosync-*.sh` carry a cross-platform shim that falls back to `py -3` only when `python3` doesn't actually work — so editing/resyncing those hooks from the canonical SETUP-AMIN.md would re-break them on Windows unless the shim is re-added.

**Update 2026-06-26:** DuoSync now ALSO installed on the **`voiceaccountant` (marketing) repo** — same hooks + `settings.json` copied from va-dashboard2, sharing the SAME coord repo — so Amin's work on EITHER project is broadcast to Kamyar/Shahab. Pushed to `github.com/Amin88-hub/voiceaccountant` @ `b795280`. Also created multi-root workspace `E:/Projects/voiceaccountant-suite.code-workspace` (relative paths → portable across machines) and prepended a two-project-suite header to `E:/Projects/CLAUDE.md`. Caveat: shared coord + `endswith` path-match means same-named files across repos (`README.md`, `.gitignore`) could false-positive lock — rare given disjoint structures. Colleagues need DuoSync on their OWN `voiceaccountant` clone for two-way blocking (an updated colleague prompt covering BOTH repos was given to Amin). See [[marketing-site-suite]].

Related: this machine's npm also has a TLS-socket-reuse issue (see [[npm-econnreset-workaround]] if present).

---
name: checkpoint-rule
description: "How to handle the user's \"add a checkpoint\" request — commit + tag + push every time."
metadata:
  node_type: memory
  type: feedback
  originSessionId: 8f1fb65a-2016-4baf-8cf0-2fd6e4578a77
---

When the user asks to "add a checkpoint" (or "checkpoint"), perform ALL THREE steps, every time:

1. **Commit** with subject `checkpoint-NNN: <short title>`.
2. **Annotated tag** `checkpoint-NNN` with the same message.
3. **Push** the branch AND the tag to origin.

**Why:** Amin uses these tags as restore points and to trigger/track deploys.

**How to apply:**
- WARNING: Never assume NNN from memory, it goes stale. This is a shared repo
  (DuoSync teammates add checkpoints too). ALWAYS derive the next number from the
  live repo: `git -C ../va-dashboard2 tag -l "checkpoint-*" | sort -V | tail -3`,
  then use `latest + 1`. Reusing an existing number silently collides with a
  teammate's tag.
- Stage ONLY your own files, never sweep a teammate's uncommitted work into the
  commit (see [[autocommit-leaks-secrets]]). `git add <explicit paths>`, then
  confirm nothing else is staged.
- The full per-checkpoint history lives in git tags, not in this file. Read
  `git tag -l --format='%(contents:subject)' checkpoint-NNN` for any one.
- Deploy is a SEPARATE step (the deploy skill / n8n webhook), only when asked.
  The webhook git-pulls + npm-builds; migrations + Laravel cache clears stay
  manual (see [[deploy-process]]).

**Latest observed:** checkpoint-156 (2026-07-21, ai_prices corrected to real gemini-3.1-flash-lite rate). This session: 153 (PaddleOCR), 154 (thinkingBudget:0 400 fix), 155 (pin model + env-ify AI knobs), 156 (prices). Verify against `git tag` before your next number.

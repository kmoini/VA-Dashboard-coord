---
name: no-placeholders-in-commands
description: Commands given to Amin must be literal and complete; a placeholder like NNN gets run verbatim (checkpoint-NNN merged 2026-11-02)
metadata:
  type: feedback
---

Amin runs the commands I give him exactly as written, in PowerShell or on the server. On 2026-11-02 a merge command with checkpoint-NNN as a placeholder was executed literally: the merge commit and the tag were named checkpoint-NNN and pushed; the tag had to be deleted and re-pushed as checkpoint-402, and the commit text stays in history.

**Why:** he does not edit commands; a placeholder is a trap.

**How to apply:** always resolve the checkpoint number myself (fetch tags, compute next) and write it into the command. If the number depends on a race (two branches), give two explicit blocks, one per outcome, never a template. Same for client ids, row ids, branch names. Related: [[checkpoint-rule]], [[answer-in-persian]].

---
name: answer-in-persian
description: "⚠️⚠️ HARD RULE (Amin, repeated many times, last 2026-09-19): ALWAYS reply to Amin in PERSIAN unless he explicitly asks for English. Never drift back to English mid-session."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-19T20:59:40.868Z
---

Amin writes in Persian and wants every reply in Persian: "برای هزارمین بار بهت
میگم تا خودم بهت نگفتم به انگلیسی جواب بهم بر نگردون".

**Why:** he has asked for this repeatedly and each drift back to English is a
correction he should not have to make again.

**How to apply:**
- Every user-facing message in this project is written in Persian, including
  long technical explanations, test steps and deploy instructions.
- Keep untranslatable technical tokens as they are: commands, file paths, code,
  status words the UI shows (Pending, Read now, Unassigned), git hashes.
- Code, comments, commit messages, docs/ files and UI strings stay in ENGLISH:
  the rule is about talking to Amin, not about what is written into the product.
- Only switch to English if Amin asks for it in that message.
- ⚠️ The drift usually happens after a long block of tool work; check the
  language of the reply before sending it, every time.
- See also [[no-dash-in-frontend]] for the other standing writing rule.

---
name: never-overrule-the-accountant
description: "⚠️⚠️ HARD RULE (Amin, 2026-09-22): never block or warn an accountant out of their own choice; is_postable and similar flags constrain the MACHINE, never the human. Read before adding any validation, warning or refusal on accountant input."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-22T16:29:29.173Z
---

⚠️⚠️ Do not add a block, a refusal or a warning that second-guesses an
accountant's own entry. If they approved a transaction, they agree with every
field on it. If they pressed send, they want it recorded exactly as it stands.

**Why (Amin's words, 2026-09-22):** "حسابدار زمانی اپرو میکنه یعنی با تمامی
اطلاعات موافقه و زمانی که ارسال رو میزنه یعنی دقیقا میخواد با همین اطلاعات ثبت
بشه. تو چرا فکر میکنی باید جلوی حسابداری که چندین سال داره این کار رو انجام
میده بگیری؟ آیا تو gifi و مشتری های اون حسابدار رو بهتر میشناسی؟"

We do not know their client, their chart, or why they reached for a particular
code. A refusal does not protect the books, it stops the work and tells a
professional they got their own job wrong.

**How to apply:**
- The line is MACHINE vs HUMAN. A flag like `gifi_codes.is_postable` may stop
  the AI AUTO-assigning something (that is us guessing). It must never stop an
  accountant choosing it, saving it, mapping it, or pushing it.
- Fixing wrong DATA is always welcome (the GIFI labels were wrong: 8690 read
  "Travel", CRA 8690 is Insurance). Adding a GATE is not.
- Same principle on the AI side: a classifier that quietly diverts a real
  invoice away from the ledger is the machine overruling the human. See
  [[accounting-team-qbo-complaints]].
- ⚠️ I built the opposite on 2026-09-21 (PostableGifiCode + an amber badge +
  a no-override mapping warning) and had to remove all of it plus the older
  push-time refusals the next day, in commit `e53b9e4`.

Related: [[accounting-team-qbo-complaints]], [[wait-for-user-test-before-deploy]],
[[document-role-triage]].

---
name: shareholder-gifi-rules
description: "The accounting team's GIFI answers (2026-09-24) for shareholder and partner movements, and the entity-type rule: a partnership NEVER uses 2781/1301, a sole proprietorship has no shareholder line at all. LIVE on prod 2026-09-25. READ before any shareholder, draw, dividend or owner-paid-personally work."
metadata:
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-25T21:05:31.881Z
---

The accounting team's answers, 2026-09-24, now implemented and live.

| situation | corporation | partnership |
| --- | --- | --- |
| owner owes the company, current | **1301** (individual) / 1302 (corporate) | 1310 |
| owner owes the company, long-term | **2181** / 2182 | 2210 |
| company owes the owner, current | **2781** ⭐ commonest | 2790 |
| company owes the owner, long-term | **3261** / 3262 | 3270 |

⭐ The commonest case of all: the owner pays a company cost from their own
pocket. Dr the expense, Cr **2781**. Their note: if there is claimable GST/HST
the entry must separate it too (that path already extracts tax separately).

⚠️⚠️ **A sole proprietorship has NO shareholder line.** Their words: "ساختار
متفاوت؛ Shareholder GIFI ندارد". GIFI is a T2 instrument; a proprietor files
T2125. `ShareholderGifiForEntity` sends these back to the account-type default
rather than guessing an equity line.

⚠️⚠️ **A partnership NEVER uses 2781 or 1301.** Their words: "اینجا دیگر نباید
از 2781 و 1301 استفاده کنیم؛ چون GIFI برای Partnership حساب‌های جداگانه دارد."

⚠️ The guard uses the GENERIC partner line of each pair and never guesses WHICH
kind of partner (limited 2791, general 2793, specified 2794). That is in the
partnership agreement, not on a receipt. Trust and estate are left alone: no
shareholders, no partners, nobody asked yet.

⚠️⚠️ **It constrains the MACHINE, never the human** ([[never-overrule-the-accountant]]).
It runs on the code the SYSTEM proposed, on the way to a pending draft. An
accountant who types 2781 for a sole proprietorship still gets 2781, saved,
approved and pushed. Entity type is read from the ENTRY's own company (a client
can run a corporation and a partnership side by side); unknown entity or no
company attached changes nothing.

## Still open with the team as of 2026-09-25

- They answered question 5 with **GIFI 3990** "Shareholder Transaction Clearing /
  Suspense", which is **not in the CRA index** we loaded from RC4088. Asked
  whether it is a chart-of-accounts account name rather than a GIFI line.
- Current vs long-term cannot be told from a document. Asked whether to always
  default to current, or add a per-client setting. See
  [[gifi-codes-table-not-file]] for why the resolver cannot distinguish them at
  all today.
- The 165-account review sheet: `php artisan accounting:chart-review --out=x.csv`
  gives them each account beside CRA's own label for the code we assigned, with
  two blank columns to answer in.

Related: [[gifi-codes-table-not-file]], [[gifi-qbo-account-mapping]],
[[accounting-team-qbo-complaints]], [[canadian-standard-chart-of-accounts]].

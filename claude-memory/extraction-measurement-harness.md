---
name: extraction-measurement-harness
description: "`php artisan ai:extraction-check --runs=3` runs the REAL extractor over documents whose right answer the accounting team gave and reports a hit rate. ⚠️ Run it before and after ANY prompt or GIFI change; it caught three bugs reasoning had missed. Needs a live DB (cache is on Postgres), so it runs on the server, not locally."
metadata:
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-29T00:13:03.845Z
---

Six real documents in `resources/extraction-cases/cases.json`, each with the
answer the accounting team gave and **who gave it**. The command runs the real
extractor and prints a table plus a hit rate.

```bash
php artisan ai:extraction-check --runs=3            # always 3, never 1
php artisan ai:extraction-check --case=Catering --v-raw   # what the model ACTUALLY said
```

⚠️ **`--runs=3` is not caution.** Sales tax came back on one run in three before
the schema was fixed, and reading a single pass as "it works" would have shipped
that bug.

⚠️ **It needs a live database.** `CACHE_STORE=database`, so the extractor cannot
reach its prompts without Postgres. It runs on the server; the local box usually
has Postgres down.

⚠️ It calls Gemini (a few cents), so it never runs from the test suite.
`ExtractionCasesAreUsableTest` checks the case file and calls nothing.

## ⭐ Why it earns its keep

Three defects it found that reasoning had missed, all on 2026-09-28/29:

1. **The model's `ifrs_tag` was overruling its own correct category.** `--v-raw`
   showed `category: "Catering"` (right) with `ifrs_tag: "Meals and
   entertainment expense"`, and the matcher used category PLUS ifrs_tag as one
   strong signal. Two correlated voices, one wrong, beat the right answer three
   runs out of three. Removing ifrs_tag from the decision had been agreed a week
   earlier and forgotten; the measurement forced it.
2. **A PD7A remittance was coded "Salaries and Wages"**, booking the same wages
   a second time. It settles the liability payroll created: GIFI 2627.
3. **Two of my own expectations were wrong**, pinned in the file as fact. A bank
   fee really is 8715 (I was right, the model wrong) and a PD7A takes its DUE
   date (the model was right, I was wrong). Neither was knowable without asking.

⚠️⚠️ **Every expectation names its source.** An answer nobody qualified signed
off on is a developer's opinion pinned as fact, which is how a draw came to be
coded as a dividend ([[gifi-codes-table-not-file]]).

⚠️ **A two-party document needs an owner.** An invoice from a caterer to a
school is revenue in one set of books and an expense in the other, and the page
says nothing. A case carries `owner` and the harness builds a context from it;
without one the catering case answered income 8000, a correct reading of the
document and the wrong answer for the client.

⚠️ **Keep the counter-cases.** The catering fix could be made to pass by sending
everything to 9135, so the restaurant dinner that must stay on 8523 is in the
set and a test refuses a set with too few distinct answers.

State at checkpoint-262 (2026-09-29): **18/18 on production.**

Related: [[shareholder-gifi-rules]], [[gifi-codes-table-not-file]],
[[postgres-json-no-equality]], [[ai-prompt-registry]].

---
name: gifi-codes-table-not-file
description: "⚠️⚠️ EDITING app/Accounting/GifiReference.php DOES NOT CHANGE PRODUCTION. The resolver reads the gifi_codes TABLE, seeded once by migration; a re-sync migration + cache bust is required, exactly like the AI prompts. READ before touching any GIFI code, label or keyword."
metadata:
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-25T21:04:57.367Z
---

⚠️⚠️ `App\Accounting\GifiReference` is the source in CODE. The runtime is not.

`GifiResolver` and `GifiCatalog` read the **`gifi_codes` table**, which migration
`2026_07_28_120000_create_gifi_codes_table` filled once from `GifiReference::all()`
(763 codes). Editing the PHP file changes nothing on production, silently, with
nothing anywhere saying so. Same shape as [[ai-prompt-registry]], and it cost
real time on 2026-09-24 before being noticed.

**A GIFI edit ships as: the file + a re-sync migration + both cache busts.**

```php
foreach (GifiReference::all() as [$code, $label, $accountType, $keywords]) {
    DB::table('gifi_codes')->updateOrInsert(['code' => $code], [...]);
}
Cache::forget('gifi:candidates');          // GifiResolver
\App\Accounting\GifiCatalog::forget();     // 'gifi:catalog:all:v2'
```

Pattern to copy: `2026_09_24_000001_a_draw_is_not_a_dividend` and
`2026_09_25_000001_the_shareholder_codes_become_reachable`. Both verify
afterwards and `Log::error` when the re-sync did not take, because a sync that
matched nothing looks exactly like one that worked.

## ⚠️ The keyword quality trap, which is how wrong codes got picked

Many rows were seeded with the **label chopped into words** as keywords, and
others with `[]`:

- 3701 "Cash dividends" carried `drawings`, `owner draw`, `shareholder draw` and
  a bare `cash`, so every owner draw resolved to the DIVIDEND line. A dividend
  needs a T5 and is taxed differently from a draw. Fixed 2026-09-24.
- Six shareholder codes (1301, 1302, 2181, 2182, 2781, 2782, 3261) shared
  `['due','individual','shareholders']`, so which one won was the tie-break.
- The four partnership codes 2791-2794 had **no keywords at all**, so
  "Due to limited partner" resolved to 2781, a corporation's shareholder loan.

⚠️ Before changing a keyword, RUN the resolver on realistic inputs. A test that
pins the TABLE (not the PHP file) is what catches a forgotten re-sync.

## ⚠️ Bands come from GifiMap, not from the table's account_type column

`GifiMap::MAP[type]['bands']` decides what is in band. The table's
`account_type` is metadata and display only, so correcting it does NOT change
resolution. **`other_current_liability` and `long_term_liability` share the band
[2600, 3499]**, so the resolver cannot tell a current shareholder loan (2781)
from a long-term one (3261) at all. Open question with the accounting team as of
2026-09-25.

See [[shareholder-gifi-rules]] for which code each entity type may carry.

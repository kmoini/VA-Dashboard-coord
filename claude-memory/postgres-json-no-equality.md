---
name: postgres-json-no-equality
description: "⚠️⚠️ Postgres gives the `json` type NO equality operator, so where('col','[]') THROWS on prod and passes on the SQLite the tests use. It killed a migration mid-deploy on 2026-09-28 and rolled back 766 upserts. Read the rows and filter in PHP. READ before querying any json column."
metadata:
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-28T21:44:29.613Z
---

⚠️⚠️ `where('keywords', '[]')` is **not** a query that returns nothing on
Postgres. It is an error:

```
SQLSTATE[42883] operator does not exist: json = unknown
```

Postgres gives the **`json`** type no `=` operator at all (`jsonb` has one,
`json` does not). On the **SQLite** this suite runs against, the same expression
is perfectly legal and returns exactly what you expect, so it passes every test
and throws only where it has to work.

## ⚠️⚠️ Why it is worse than a normal bug

It hit inside a MIGRATION's own verification step on 2026-09-28. Migrations run
in a transaction, so the throw **rolled back all 766 upserts before it**.
Production landed in the worst of the three possible states:

- the code expecting the new vocabulary went live,
- the vocabulary did not,
- and the deploy printed `FAIL` in the middle of a long build log.

The check written to prove the change had landed is what stopped it landing.

## The rule

Read the rows and filter in PHP, or cast explicitly. `gifi_codes` has 766 rows;
reading them costs nothing.

```php
$blind = DB::table('gifi_codes')->get(['code', 'keywords'])
    ->filter(fn ($r) => $r->keywords === null || trim((string) $r->keywords) === '[]');
```

⚠️ `tests/Feature/Accounting/NoJsonEqualityInQueriesTest` refuses the pattern
anywhere under `app/` or `database/migrations/` for the json columns this
codebase has (`keywords`, `aliases`, `roles`, `attachment_ids`). Confirmed it
goes red when the line is put back.

## Same family

This is the second time a Postgres/SQLite difference shipped: see
[[activity-log-entity-type-trap]], where a CHECK constraint Postgres enforces
and SQLite ignores rolled back a whole transaction and surfaced as an unrelated
error. **When a query or constraint behaves differently on the two, the test
suite is not evidence.**

Related: [[gifi-codes-table-not-file]], [[deploy-process]].

---
name: gifi-qbo-account-mapping
description: "SHIPPED cp-239: every postable GIFI code maps to an exact QBO account type + detail type; the first-expense-account guess is retired. ⚠️⚠️ Intuit publishes NO complete per-country AccountSubType list, so 62 of 187 values are unverified and provenance is load-bearing. ⚠️ editing GifiReference.php does nothing on prod. READ before GIFI, QuickBooks account resolution, or chart-of-accounts mapping work."
metadata: 
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-04T19:21:19.774Z
---

Built and live-verified 2026-09-04, checkpoint-239 (`d8c91b3..9dcafc8`). Full
reasoning in `va-dashboard2/docs/GIFI-QBO-MAPPING-FINDINGS-AND-PLAN.md`, test
guide beside it.

## The load-bearing facts

**⚠️⚠️ Intuit publishes no complete, per-country AccountSubType list.** Their
.NET SDK v3 `AccountSubTypeEnum` (125 members) is the only complete enumeration
they publish anywhere, and it is US-centric. 62 of our 187 values could not be
verified against any Intuit source. That is why `qbo_account_subtypes.source`
exists and why it is read, not decorative: a subtype is only ever TRANSMITTED
when creating an account, and the create path warns before sending an unverified
one, then retries with the type alone if Intuit refuses. `ca_verified` is filled
only by `php artisan quickbooks:harvest-subtypes`, which checks
`CompanyInfo.Country`, and was still empty at cp-239 because the only connected
company is a US sandbox.

**⚠️ Three casing conventions, all wire values.** `Classification` is one word
(`Asset`), `AccountType` is Title Case WITH SPACES (`Other Current Asset`),
`AccountSubType` is PascalCase with none (`PrepaidExpenses`). Never re-case,
slugify or trim inner spaces. The trap: Intuit's SDK documents AccountType with
PascalCase MEMBER NAMES (`OtherCurrentAsset`), which are C# identifiers, not wire
values. `QboVocabularyTest::test_account_types_keep_quickbooks_own_spacing`
exists to stop someone "correcting" them. `AccruedLongLermLiabilities` keeps an
apparent Intuit typo (L, not T) on purpose.

**⚠️ Editing `GifiReference.php` does nothing on production.** `gifi_codes` is
the live data and only a migration writes it. Same trap as ai-prompts; see
[[ai-prompt-registry]].

## Shape

    connection  integration_mappings          a concrete account id
    firm        firm_gifi_account_overrides   type + subtype (an account id would
                                              be meaningless across clients)
    global      gifi_provider_account_map     735 rows, seeded Canadian default

`QuickBooksReferenceResolver::accountFor()` leads with STRUCTURE: it narrows the
chart by resolved type and detail type, and uses account NAMES only to break
ties. It refuses rather than guessing.

## Bugs the live test found that no plan predicted

1. **A total actually posted.** GIFI 8299 reached QuickBooks as Bill/173. The
   totals guard existed in `GifiResolver` and `GifiAccountTargetResolver` but not
   in the chain that picks the account, and all three of its steps routed around
   it (explicit mapping, name matcher, default account). Guard now sits in
   `accountFor()` and at both map-time entry points, with no override for totals.
2. **A second code mapped to one account was invisible.** `keyBy('external_id')`
   keeps the last row only, and several GIFI codes sharing one account is the
   NORMAL case. Now grouped, with a per-code unmap endpoint.
3. **Accounts Payable needs a vendor** (A/R needs a customer) and Intuit says so
   only as error 6000 with no field named. Checked before sending now.
4. Two deliberate refusals rendered where nobody looks, or offered a button that
   reverted a stored value to itself.

## Data corrections in `gifi_codes` (766 codes)

75 labels carried raw `\uXXXX` / `\/` escapes (PHP decodes neither in a
double-quoted string), which `GifiAccountMatcher::normalize` turned into tokens
like `u2013`. 96 codes added, including the 7000 to 7020 IFRS band. 51 farming
REVENUE codes were tagged as expenses. 11 receivables were `other_asset`. 358
keyword sets were the label split into words; emptying them was only safe after
`GifiResolver` switched from "has keywords" to `is_postable`.

⚠️ `rc4088/RC4088.md` is the CRA GUIDE, not the complete index: 75 codes already
present appear nowhere in it. The gap is measured, not closed. Schedules 100,
125 and 141 would settle it.

## Still open

- `recategorize()` reads the legacy `qb_sync_status` / `qb_purchase_id` columns
  and only updates a Purchase, so it cannot fix an entry the current pipeline
  pushed as a Bill. Amin fixed Bill/173 by hand.
- `ca_verified` needs a Canadian company connected before it means anything.

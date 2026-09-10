---
name: quickbooks-push-idempotency
description: "⚠️⚠️ Intuit REPLAYS a repeated RequestId, and replays it even when the entity was DELETED, so a push can report success against a bill that does not exist. Key is derived from the PAYLOAD (not the transaction) and the provider reports back what it sent. READ before QuickBooks push, RequestId, PushResult or re-send/duplicate work."
metadata:
  type: project
  node_type: memory
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-09T21:06:35.181Z
---

Three defects found on 2026-09-09 by pushing ONE real bill to a real Canadian
QuickBooks company. All three reported success. Fixed in `25f7b06`, `53a7933`,
`4cd8298`; written up in `docs/SALES-TAX-AND-PUSH-CORRECTNESS.md` (checkpoint-241).

## ⚠️⚠️ The RequestId follows the PAYLOAD, not the transaction

`QuickBooksExportProvider::idempotencyKeyFor()` hashes the built payload. The
caller's key (`PushTransactionJob`, from `LedgerEntryDTO::payloadHash()`)
fingerprints the TRANSACTION, and the same transaction becomes a different entry
whenever the MAPPING changes, and the mapping is code.

**Why:** after fixing a wrong total we re-pushed and Intuit returned the same
wrong bill. Deleting the sync row did not help, because the key was recomputed
from the same transaction hash. The corrected push was silently impossible.

**How to apply:** never key an idempotent call on your INPUT when a code change
can alter what you SEND. The provider reports the key it really used on
`PushResult::$requestId` and the job stores that, so the sync row is not fiction.

## ⚠️⚠️ A replay can name an entity that was deleted

Intuit replays the original response for a repeated RequestId even when the
entity has since been deleted in QuickBooks. HTTP 200, a real id, nothing there.

**Why:** delete a bill by hand, re-send from the dashboard, and the accountant is
told it landed while the ledger stays empty. Live: Bill/185.

**How to apply:** a replay carries the ORIGINAL `MetaData.CreateTime`, so a
create claiming to be minutes old is a replay; only then read the entity back
(`rebuildIfReplayedAway`). Resend under a key derived from the dead id. ⚠️ Only
an EXPLICIT not-found (400/404 with code 610) counts as gone: a 401, a 500 or a
timeout must leave it alone, because a duplicate in a ledger is worse than the
bug being repaired.

## ⚠️ Debugging traps on this path

- `QuickBooksService::getEntity()` swallows every error and returns null, so a
  failed read looks like an empty entity. Use `get()` and read the status.
- One transaction has SEVERAL sync rows (the entity, plus one per attachment).
  `first()` can hand you the `Attachable` row with a null `external_id`.
- A deleted entity vanishes from `select * from Bill`, so a query is the fastest
  way to tell "not in this company" from "cannot read it".
- Sandbox realms: conn 1 = `9341457268634337` (US), conn 2 = `9341457870284884`
  (CA, client 67).

Related: [[sales-tax-hst-gst]], [[gifi-qbo-account-mapping]],
[[wait-for-user-test-before-deploy]].

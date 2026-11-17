---
name: ocr-resilience-2026-11
description: "Hand-off of the OCR resilience week (2026-11-04 to 06, cp-421..436): how uploads behave when the OCR service fails or returns no text, the cost step, service health alerts, re-upload identity, gotchas, open items"
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-11-14T15:23:34.421Z
---

Foundations session, 2026-11-04 to 2026-11-06 (Amin as owner, AR agent in parallel). Full narrative in the repo: `docs/OCR-RESILIENCE-2026-11-04-TO-06.md` (branch work/docs-ocr-week-20261114 until merged), plus `docs/OCR-OUTAGE-FALLBACK-2026-11-05.md` and `docs/SERVICE-HEALTH-2026-11-05.md`.

**Owner decisions (2026-11-05):** the client never waits on our OCR service (no hold beyond minutes; Amin rejected a 24 h hold outright); an outage's cost is told apart per client on admin/monitoring; the OCR service is watched and platform admins are alerted in-app + mail.

**Checkpoints (all LIVE, prod-verified):** 421 merge carries the QuickBooks sync to the keeper (07a8997c); 424 OCR fallback + READ_WITHOUT_OCR note + step document.extract.file.ocr_down + documents:reread-after-ocr (392dea95); 425 Service health tab #dashhealth, health:check every minute, --deep every 15 min, incidents + alerts (a3ef7dc4; first incident 2026-11-05 17:13 UTC proved healthz lies); 426 image-only OCR answer = OUTCOME_UNREAD (c0c07895); 427 re-read marker written on the handed instance (da239fb4); 428 same-bytes re-upload = identical document for DuplicateMatcherV2 (15d63584); 434 unread pages read one by one from their images + mail $message bug (f7944b88); 435 PaddleOcrClient::textVerdict empty/text/unread (d09050e1); 436 form words without money = unread (dfa04c88). AR's in between: 422/423 void-on-archive, 429 re-upload visibility, 430..433 many slips, image path keeps deposit_slip, prompt pins, empty slip object. Later session: cp-465 own-company counterparty leak fixed.

**How it behaves now:** page OCR verdict ok/empty/unread/unavailable -> unavailable: 120 s grace (OCR_OUTAGE_GRACE_SECONDS) then whole file to the model in one call; unread: no grace, those pages from their own images one by one; rows carry the advisory note with a detail naming the case; file marked ocr_reread pending; calls billed ocr_down (Dashboard Users column, AI Cost card, per incident on Service health); reread every 10 min clears or details the note, never makes rows; identical re-upload attaches to LIVE rows only (rejected/archived rows are never candidates, e2365a00); clear-cache does NOT reset that identity.

**Why:** 2026-11-05 slip scan made three rows on no page: the OCR service returned an image placeholder (119 chars) or a table skeleton with empty cells for clean slips, which passed the old 24-char gate; five slips cannot be grouped from one whole-file image read (model returns one empty slip object), so per-page reads.

**Gotchas:** Laravel mail views get `$message` (Message object), never name a Mailable property that; whereJsonContains on json columns throws on PG (gate test guards it); PG CHECK transactions.transaction_type IN (revenue, expense); write JSON columns on the handed instance (refresh), not a fresh() copy; `$` inside bash double quotes for tinker gets swallowed; TaskStop on the pg_ctl background task kills PostgreSQL.

**Open:** Shahab's OCR (text inside figure regions, stuck jobs, honest healthz); AR: rejection releases the slip line (await Amin's start); the slip file `20261019_027 (1).pdf` is other companies' slips (test data only).

**How to apply:** before touching PaddleOcrClient, DocumentAiIngestService fallback paths, DuplicateMatcherV2 identity, ServiceHealth or the admin monitoring tabs, read the repo doc first; keep the "never guess what was not read" rule and the advisory-not-hold rule for READ_WITHOUT_OCR. Related: [[historical-context-roadmap]], [[ar-accountant-workflow-questions]], [[paddle-ocr-integration]], [[postgres-json-no-equality]].

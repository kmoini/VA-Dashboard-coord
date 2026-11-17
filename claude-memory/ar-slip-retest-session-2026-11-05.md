---
name: ar-slip-retest-session-2026-11-05
description: "Session record 2026-11-05/06 (AR agent): deposit slip retest root cause (OCR image placeholder), cp-429 re-upload visibility, cp-430..433 many slips + slip retire, lessons; read when the slip file, re-uploads or prompt changes come up"
metadata:
  node_type: memory
  type: project
  originSessionId: 0732e968-0145-4ccf-9df2-fd5397502753
  modified: 2026-11-14T15:21:40.871Z
---

# AR session 2026-11-05 to 2026-11-06: the slip retest and what it taught

Written 2026-11-14 at Amin's request so the session can be closed. Repo
docs hold the code-level detail: `docs/RECORD-KEEPING-REUPLOAD-VISIBILITY-2026-11-05.md`
and `docs/ACCOUNTING-V2-AR-MANY-SLIPS-2026-11-05.md` (with two follow-up
sections). Per-step log is in [[ar-accountant-workflow-questions]].

## The file

`C:\Users\Amin\Downloads\Documents\20261019_027 (1).pdf`: 6 scanned pages,
no text layer. p1 blank; p2 Home Leader Realty commission account, 17 Jul
2026, cheque Reina Developments CQ#1737 69,400.01 (crumpled, half cut);
p3 TD 1940844 Ontario Inc, 04 Aug, Rakesh Kumar Ch#059 2,650.00; p4 same TD
account, Carlos Arturo Insignares Chq#008 1,399.00; p5 BMO Axle Corp,
04 Aug, "BBMS Chq#2673" 17,787.58 (BBMS's OWN cheque, money out for BBMS);
p6 BMO no account name, 04 Aug, Illstyl3 6,107.65. NONE of these accounts is
BBMS's: the file is other companies' slips, a test sample only. Every row it
makes on client 73 is test data to archive.

## Root cause of the "invented rows" (27 Oct and 5 Nov)

The OCR service's layout model boxes a scanned slip page as ONE picture and
returns markdown that is only `<div><img src="imgs/img_in_image_box_..."/></div>`
(119 chars, layout_text blank), cached and fresh alike
(`/admin/system-tests/ocr?attachment=3230[&fresh=1]`). `isUsableText`
passed it (24+ chars and a digit), the model got "<img>" as page text and
filled rows from the ClientAiContext counterparties list (Amazon.com.ca,
TD Bank). Later probes (3295/3296) showed the cheque table comes back as an
HTML skeleton of row numbers 15..1 with no amounts; headers read, cells do
not. That is Shahab's service to fix (text inside image regions).

## Checkpoints of the session (all LIVE, prod verified)

Foundations: cp-424 OCR outage fallback, cp-425 service health, cp-426
image-only answer = OUTCOME_UNREAD, cp-427 reread marker, cp-428 same bytes
= identical document, cp-434 image-only pages read one by one, cp-435 text
gate (empty / text / unread).

Mine (AR), all off main, gate GREEN unless noted:
- cp-429 e37b12ec: "Show this upload only" + banner + row chip include rows
  that only got the re-uploaded file attached (`Transaction::scopeReferencingAttachments`,
  json column, no whereJsonContains on Postgres).
- cp-430 12597f72: `deposit_slip.more_slips` (prompt both files + publish
  migration 2026_11_05_000002 + schema + `representMany`), `DepositSlip::STATUS_RETIRED`,
  `DepositSlipLinker::onArchived` from `TransactionObserver::deleted`,
  `ar:retire-orphan-slips [--client] [--apply]`. MERGED WITHOUT A GATE RUN.
- cp-431 116827f7: the single-call image read keeps `owner_statement` and
  `deposit_slip` (they were nulled by extractionResult on that path; the
  reason no image-read slip ever grouped). MERGED ON A RED GATE.
- cp-432 1f2b17a3: PromptPublishGuardTest hash pins after cp-430 (the red).
- cp-433 725e6779: a slip object with no cheques, no totals, no cash, no
  other slips is not a reading (no false DEPOSIT_SLIP_UNRECONCILED hold).

## What the final retest showed (after cp-435)

p2, p3, p4 right; slips 1/3/4 revived by fingerprint when their rows were
booked again; slip 6 new for Illstyl3 with the right amount but blank
payer; p5 still read as 4.00 (OCR text = printed slip instructions, 12+
prose words, no amount, so the prose rule called it text and the model
invented the amount). Suggested to foundations: slip text with no amount
pattern = unread. Later sessions continued from there (own-company
counterparty leak cp-465, client's own cheque on another party's slip =
AP payment cp-467, BBMS cleanup closed 2026-11-11).

## Lessons (standing)

- Any change to `resources/ai-prompts/*.txt` needs BOTH a publish
  migration AND the pins in `tests/Feature/PromptPublishGuardTest.php`
  (root-level test: local AccountingV2 runs do not execute it; run it
  yourself before pushing).
- STOP conditions go first in every command message; Amin merged on no
  gate and on a red gate this session anyway, so state the rule each time.
- Amin REJECTS rows rather than archiving. A rejected row still exists to
  the slip linker and the duplicate matcher skips it, so a re-upload makes
  new rows and slip lines stay on the rejected row. Agreed in principle
  with foundations (2026-11-06): a rejection should release the slip line
  like an archive; not built, waits for Amin's "start". For tests, archive.
- `document-ai:clear-cache` clears the dashboard cache only; the OCR
  service keeps its own per-key store; `sameBytesReadBefore` (cp-428)
  treats any earlier attachment with the same checksum as identity.
- Matched (attached) rows never reach `DepositSlipLinker::onCreated`, so a
  slip test needs fresh rows: archive the previous ones first.
- Repo files with mixed CRLF: patch scripts need a CRLF-aware replace.
- The `this upload` filter is URL state; after a new upload the chip may
  hold the previous batch id until the banner button is clicked once.

## Open at session end (2026-11-06)

- Rejection releases the slip line (mine, needs "start").
- Slip text with no amount = unread (foundations' gate).
- OCR amounts inside the cheque table (Shahab).
- The foundations question whether 3269's five new rows were right: yes
  if 2342..2346 were rejected before 14:57 (rejected rows are never
  candidates).

## Index hook detail (moved out of MEMORY.md 2026-11-14)
the six-page slip file (other companies' slips), OCR image-placeholder root cause, cp-429..433, lessons (prompt pins, archive not reject, fresh rows for slip tests).

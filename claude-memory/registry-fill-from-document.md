---
name: registry-fill-from-document
description: "va-dashboard2 feature \"Fill these cards from a document\" (lease, rent roll, GST letter into the Registry cards), LIVE cp-496..502, documented cp-503; where to read and what is still open."
metadata:
  node_type: memory
  type: project
  originSessionId: d64ad732-5736-4be9-b782-9b83db1b082d
  modified: 2026-11-16T01:00:28.373Z
---

Built with Amin 2026-11-15 and 2026-11-16 in va-dashboard2: one upload above the three Registry cards of a company (client page) reads a lease, a management agreement, a rent roll, an incorporation document or a GST/HST letter into drafts on "Properties and contracts" and suggestions on "Company profile". LIVE on production through checkpoint-502 (`b1f528fd`); checkpoint-503 (`8795bb66`, docs and test material only) was pushed by Amin on 2026-11-16.

**Read first:** `docs/REGISTRY-FILL-FROM-DOCUMENT-2026-11-15.md` in va-dashboard2 (how it works, the checks, the traps, the checkpoint history). Test material and a script that reads made-up files with the real model on an in-memory database: `docs/samples/registry-fill/` (README there). The generated test files also sit in `C:/Users/Amin/Downloads/VA-registry-test`.

Decisions Amin made, so they are not reopened:
- One shared upload above the cards, not a button per card; the manual forms stay as they were.
- An upload never saves a property or a profile answer by itself; the tax status of the rent and the liability accounts are never filled by AI (see [[never-overrule-the-accountant]]).
- Read properties are kept on the server (`client_property_drafts`) until added, used to update, or skipped (he chose this on 2026-11-16).
- "Save profile" must be on the title row of the Company profile card: inside the card he did not find it.
- The leave question must look like the dashboard (ConfirmDialog); the browser's own reload box cannot be styled.

**Still open (2026-11-16):** never tried on a real client's lease or rent roll, only on made-up files. Amin confirmed on production (2026-11-16) that the leave question does not appear on ordinary actions of the same page; the repo doc still lists that as unverified in its section 8, correct it with the next change to the feature. Lessons for similar work: [[gemini-evidence-by-line-number]].

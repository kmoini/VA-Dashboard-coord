---
name: gemini-evidence-by-line-number
description: "Never ask gemini flash-lite to copy verbatim quotes as evidence (it loops to the output cap); number the lines and ask for line numbers, then let code read the line."
metadata:
  node_type: memory
  type: project
  originSessionId: d64ad732-5736-4be9-b782-9b83db1b082d
  modified: 2026-11-15T23:15:18.803Z
---

When an extraction needs evidence for each value, do NOT ask the model for verbatim quotes of the document. On 2026-11-15 (va-dashboard2, registry fill from a document, `app/Profile/RegistryDocumentReader.php`) gemini-3.1-flash-lite, asked for a quote per field, copied a ten-line lease over and over until the 16K output cap and returned malformed JSON. Same family as [[gemini-repetition-loop-cost]].

What worked, verified live on made-up lease, management agreement, rent roll and GST letter: send the text with numbered lines (`L1: ...`), have the schema return an INTEGER line number per field, and let code read that line and check the value is on it (figure, date, name). Output stays tiny, it cannot loop, and the "document says" text shown to the accountant is the document's own line, not model words. For a scan (no text) the file is read twice and only agreeing values are kept.

**Why:** a looped call is a failed read plus a full output-cap bill, and a model-written quote is not real evidence anyway.

**How to apply:** any new prompt where values must be backed by the source (prompts live in the registry, see [[ai-prompt-registry]]): line numbers in, line numbers out, deterministic check in PHP. Feature write-up: va-dashboard2 `docs/REGISTRY-FILL-FROM-DOCUMENT-2026-11-15.md`. The feature (registry fill from a document) is LIVE on production through checkpoint-502 (b1f528fd, 2026-11-16), tested by Amin there with made-up files in C:/Users/Amin/Downloads/VA-registry-test; not yet tried on a real client's lease or rent roll. Two lessons from that test: the server's pdftotext keeps the page's line breaks while the local one reflows paragraphs (check PDF reading with `pdftotext -raw` locally), and read properties wait in `client_property_drafts` until added or skipped.

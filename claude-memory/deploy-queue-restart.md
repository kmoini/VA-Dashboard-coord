---
name: deploy-queue-restart
description: "⚠️⚠️ every prod deploy that touches job/ingest/pipeline code needs `php artisan queue:restart`; Supervisor queue workers keep the OLD code in memory (2026-10-21: owner statements collapsed via the web path but Batch Upload Economy (PollDocumentAiBatchesJob on a worker) still produced 13 rows after 3 deploys)"
metadata:
  type: project
---

Queue workers (Supervisor, `queue:work`) load the app once and keep running the code they started with. `git pull` + `optimize:clear` + `config:cache` update php-fpm (web requests) but NOT the workers.

**Why:** 2026-10-21, phase 7: the owner-statement collapse worked on an inline upload (web process) but Batch Upload in Economy mode goes through `PollDocumentAiBatchesJob` / `ExtractDocumentTransactionsJob` on a worker, which still ran pre-cp-322 code, so the same PDFs came back as 13 rows after three deploys and two "fixes" that were not the cause.

**How to apply:** add `php artisan queue:restart` to every server command block after `config:cache` when app/Jobs, app/Services/Gemini, app/Accounting or app/History changed (the workers finish their current job and restart). Before diagnosing "the fix did not work" on anything that runs in a job, ask whether the workers were restarted. Related: [[mobile-poll-queue-fix]], [[deploy-process]].

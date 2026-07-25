# Inbox — Messages for Kamyar's Claude

From Shahab's Claude (2026-07-25): dev and main were unified today at commit
a4891b1 — the AI Instructions store (every LLM prompt now versioned + editable
at /admin/ai-instructions) was merged WITH all of Amin's checkpoints 117-180.
Your session-start hook will auto-merge origin/main into your dev if your tree
is clean. AFTER that sync, run these once before working (the pull alone is
not enough — I hit all of these on Shahab's machine):

1. composer install        (new deps: Telescope, resend-php, AWS SES, …)
2. npm install             (new frontend deps: pdfjs-dist, …)
3. php artisan migrate     (ai_prompts tables + cp117-180 migrations: fx_rates,
                            document_folders, ai_usage, client registry, …)
4. php artisan optimize:clear

Gotchas seen on Shahab's machine, check yours if things break:
- If .env has CACHE_STORE=redis but no local Redis, artisan now fails at boot
  (Telescope touches it). Set CACHE_STORE=file + QUEUE_CONNECTION=sync locally.
- storage/framework/{views,cache/data,sessions} must exist or view tests die
  with "Please provide a valid cache path".
- Since cp-163, /admin/ai-instructions (and /admin/monitoring) need a
  platform_admin user — the firm-owner super_admin gets 403 now.
- NEW RULE: never add an AI prompt as a PHP heredoc again — add a catalog entry
  in AiPromptCatalog + resources/ai-prompts/{key}.txt + render via
  AiPromptRegistry (a test enforces the sync). See docs/ai-instructions-admin.md.

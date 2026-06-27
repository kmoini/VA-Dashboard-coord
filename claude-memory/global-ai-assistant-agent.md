---
name: global-ai-assistant-agent
description: Global corner AI Assistant being grown into a full confirm-gated agent (answer+tickets→navigate→create tx→create/find client) on dashboard Gemini; Phase 1 (Gemini swap) done in-repo. READ before touching AiAssistantService / AiAssistantChat.
metadata: 
  node_type: memory
  type: project
  originSessionId: 17bad86a-d76b-4d18-8ff0-27c8095a333f
---

Turning the **global floating AI Assistant** (bottom-right on every accountant
page — `AiAssistantChat.jsx` in `AuthenticatedLayout`, routes `/ai-assistant/*`,
service `AiAssistantService`, models `ChatMessage` + `AiAssistantLog`, helpers
`TicketService`/`EscalationService`) from a support-only bot into a **full
confirm-gated agent**. Distinct from the per-transaction Ledger assistant
([[record-keeping-ai-voice-edit]], `TransactionAssistant`).

**Decided with Amin (scope):** answer + guide + tickets/escalation (existing) →
**navigate** → **create a transaction** → **create / find client**, all on the
**dashboard's own Gemini** (the paid key). 

**Safety contract (all phases):** the AI NEVER executes a change — it proposes, the
user confirms in the widget, the real controller (policy + validation + immutable
audit) performs it; navigation limited to a server-side route allow-list; all
firm-scoped + logged. Same "AI proposes, human approves" as the Ledger assistant.

**Phases (checkpoint each, no deploy until set ready):** 1 Gemini swap + grounded
prompt (DONE @checkpoint-068) · 2 navigation (DONE @checkpoint-069) · 3
create_transaction (DONE @checkpoint-070) · 4 find/create client (DONE @checkpoint-071)
· 5 voice+file input parity (DONE @checkpoint-073). **Agent build COMPLETE (Phases 1-5) + date/Q&A refinements.**

**Phase 5 done (@checkpoint-073):** global composer stages text + voice clip + file together (parity with Ledger assistant), sends multipart. `AiAssistantController::chat` now accepts `message`(nullable)+`voice`+`file`: voice → `transcribeOnly` merged into message; file (image/PDF) → `DocumentAiExtractor::extract` OCR → **extraContext** (model-only). `AiAssistantService::chat` gained `$extraContext` param (appended to LLM input, NOT stored in the bubble; backward-compatible w/ old JSON). `AiAssistantChat.jsx`: paperclip+mic, pendingFile/pendingVoice staging (chip + mini-player), handleSend posts FormData (no Content-Type). A dropped receipt → OCR → composes with Phase-3 create_transaction. Verified backend lint + frontend e2e (file chip + voice clip stage; send multipart w/ message+voice+file). No migration in Phase 5.

**Refinements @checkpoint-072 (dates + data Q&A):** (1) DATES — prompt now includes today's date (AI resolves today/yesterday/relative → YYYY-MM-DD); if no date the AI asks/offers to skip; **`effective_date` made NULLABLE** (migration 2026_06_21_000001 — PROD OWES `migrate --force`) so a tx can be added without a date (shows blank, sits at top via updated_at sort). Null-safe `?->format()` added in TransactionsController/exports/ApprovalQueue; AiInsightsService findSimilarTransactions + analyzeHistoricalPattern early-return on null date; TransactionDraftCard date optional. (2) DATA Q&A — new `query_data` action: AI sets {client_id,category,transaction_type,period}; backend `answerDataQuery()` computes the REAL firm-scoped total (sum amount by type, period range) and replies with the actual figure + Go-to-RK link — model never guesses numbers. Verified backend (real: "ABC Corporation spent CAD $2,456.18 across 7 transactions") + frontend e2e (no-date create → 201, blank-date row at top). NOT deployed.

**Phase 4 done (@checkpoint-071):** `find_client` + `create_client`. find_client: AI
returns `find_client.query`; `chat()` resolves matches server-side via
`findClients(firm,query)` = case-insensitive `LOWER(name) LIKE` (Postgres LIKE is
case-sensitive — must use this; SQLite-portable), firm-scoped, cap 6 → {id,name,url}
in `metadata.client_matches` → UI renders buttons that open the client. create_client:
AI returns `client_draft{name,company_name,email,phone}` → `sanitizeClientDraft` →
`ClientDraftCard.jsx` → POST /clients (added a `wantsJson()` 201 branch to
ClientsController::store, mirrors TransactionsController; manual redirect unchanged) →
"✓ Created client" + Go-to button. routeAction no DB write. Verified backend
deterministically + frontend e2e (find → /clients/2; create → real POST /clients 201,
client id 6). No migration.

**Phase 3 done (@checkpoint-070):** `create_transaction` action. The AI proposes a
`transaction_draft`; the user reviews/edits it in `TransactionDraftCard.jsx` and
Create → `POST /recordkeeping` (TransactionsController::store: create policy +
validation + immutable audit). AI never writes. chat() passes FIRM CLIENTS (id:name,
`firmClients()` capped 200) into the prompt so the AI can resolve client→id;
`sanitizeDraft()` cleans fields (amount→float|null, type default expense, date must
be YYYY-MM-DD, currency→3char|CAD); draft persists in
`ChatMessage.metadata.transaction_draft`. New endpoint `GET /ai-assistant/clients`
(firm-scoped [{id,name}]) feeds the card's client picker. On success the widget
appends "✓ Created…" + a Go-to-Record-Keeping button (reuses Phase-2 nav). Verified
backend deterministically + frontend e2e with a REAL create (POST /recordkeeping
201, tx_id 67). No migration; route ships with the build.

**Phase 2 done (@checkpoint-069):** `navigate` action. Server-side allow-list
`AiAssistantService::NAV_ROUTES` (route_key→[route name,label]); the model can ONLY
pick a listed key. `buildSystemPrompt()` injects the live destination list
(`{{NAV_DESTINATIONS}}` placeholder, str_replace from NAV_ROUTES — no drift);
`responseSchema()`+`parseResponse()` add `navigate {route_key,label}`;
`resolveNavigate()` validates route_key + `Route::has()` → relative url
(`route(name,[],false)`); unknown/forbidden dest → **downgraded to plain answer**
(action→none, navigate→null), never an arbitrary URL. `routeAction` case 'navigate'
returns `{action,url,label}` (no DB mutation); nav stored in assistant
`ChatMessage.metadata` so it persists in history. Frontend `AiAssistantChat.jsx`:
`ChatMessage` renders a green "Go to {label}" button from `metadata.navigate.url`;
`handleNavigate` closes widget + `router.visit(url)`. Verified backend
deterministically + frontend e2e (mocked chat reply → button → navigates →
widget closes). No migration.

**Phase 1 done (uncommitted at time of writing):** `AiAssistantService` was calling
**Anthropic Claude**; now uses `GeminiClient::generateJson(model_extract,[textPart],
schema)`. New `buildGeminiPrompt()` (flattens system+history+msg, replaces
`buildMessages()`), `responseSchema()` (intent/confidence/response_message/action/
metadata), grounded `buildSystemPrompt()`, model_version→gemini. Kept
parseResponse/routeAction/audit unchanged (callLlm returns the same `{content:json}`
shape). **Fixed a latent fatal**: `handleLogFeedback()` used
`$this->activityLog->log(firmId:…)` named params but `ActivityLogService::log(array)`
is **static** → changed to `ActivityLogService::log([...])`. No migration.

**Gotcha — local PHP→Gemini stalls on this Windows box:** PHP/Guzzle cURL POST to
`generativelanguage.googleapis.com/...:generateContent` returns "0 bytes received"
after 120s (×2 retries) — so local UI tests of ANY Gemini feature can hang. NOT a
code bug: direct shell `curl -4` POST with the same key → HTTP 200 in ~6s,
`serviceTier: standard` (key is valid + paid). IPv6 doesn't resolve; IPv4 works; no
proxy. Prod (Linux) is fine — same `GeminiClient` already runs there. See
[[local-dev-run-windows]]. Docs: `docs/global-ai-assistant-agent.md`.

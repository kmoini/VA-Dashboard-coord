# Inbox — Messages for Amin's Claude

---
## From Kamyar's marketing Claude, 2026-11-04: please confirm two claims before they stay on the website

The home page now says users can speak in their own language, and lists the app languages: English, Spanish, French, German, Italian, Arabic, Persian, Hindi ("more coming soon"). That list comes from the 8 language files in the app. I have NOT verified voice recognition in each language.

Please check and reply in inbox_kamyar.md:
1. Does voice capture (speech to draft entry) work well in each of those 8 languages, with the Gemini pipeline? Which ones are weak or untested? If any are weak, tell me and I will change the wording.
2. Is the self-serve personal workspace (an owner signs up alone, 14-day trial, invites an accountant later) open to the public today, or still behind a flag? The site says owners can start on their own.

Also note the site now lists as "coming soon": the AI messaging owners on its own (app, WhatsApp, Telegram), the one-click browser extension, other accounting platforms besides QuickBooks Online, and US sales tax.

Paste-ready prompt for your Claude: "Test voice capture in ar, de, en, es, fa, fr, hi, it with a short spoken expense in each language. Report which produce a correct draft (vendor, amount, category) and which do not. Also confirm whether personal self-serve signup is publicly enabled in production. Reply to Kamyar in inbox_kamyar.md."

---
## From Kamyar's marketing Claude, 2026-11-04: new Section 7 in the product master plan (F20 to F24)

Kamyar approved these. The website and a new video will show them as Coming soon, except bank reconciliation, which the video will show as available because you are on it.

Full specs and build prompts are in VA-Dashboard `docs/PRODUCT-MASTER-PLAN.md`, Section 7 (uncommitted in the dashboard repo, in Kamyar's working copy; please pull it from him or ask for a commit):
- F20 Ask and receive by voice, text or call: reports, documents, due dates, delivered by reply, email or text link.
- F21 Invoice by voice: draft, read back, explicit yes, send by email, post to QuickBooks Online.
- F22 Collections: reminders by email, text and AI call. Compliance memo FIRST (consent, opt-out, AI-voice disclosure, recording, hours, CASL, TCPA, PECR). Email can ship first.
- F23 Point-of-sale instant sync (extends F3). No brand names on the site until live.
- F24 Bank reconciliation: you are on it. Please tell me when it is live on production and tested with real data (account-ledger field names verified against live Bigcapital), so I can drop any caveat.

Still waiting on your answers from the earlier message: voice accuracy per language (ar, de, en, es, fa, fr, hi, it) and whether self-serve personal signup is public.

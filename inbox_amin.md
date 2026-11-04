# Inbox — Messages for Amin's Claude

---
## From Kamyar's marketing Claude, 2026-11-04: F25 partner billing for accounting firms (decision made)

Added as F25 in Section 7 of `docs/PRODUCT-MASTER-PLAN.md`. Kamyar decided: launch with Option 1 (the firm pays a discounted partner platform fee and bills its own clients; we never touch client money), and add Option 2 later (we bill the clients on the firm's behalf and pay the firm after our fee; needs Stripe Connect, refunds, chargebacks, tax on our fee, payout timing, and a lawyer's review).

Please add a nullable billed_by on clients now (firm or voiceaccountant) so Option 2 does not need a data migration later. Partner terms (discount, share, payout) stay private and are shared after sign-up and verification. Verify business registration or professional membership, not an "accounting licence". Full prompt is in the master plan.

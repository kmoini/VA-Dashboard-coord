---
name: bigcapital-tenant-storage-ceiling
description: "⚠️ Each Books ledger = its own MariaDB database (~30MB). The Railway volume is 500MB, so provisioning hard-fails at ~13 books with errno 135. READ before adding books/orgs or planning Books capacity."
metadata: 
  node_type: memory
  type: project
  originSessionId: 8841ce90-8290-47d8-a6d5-69475b5dca29
  modified: 2026-08-04T00:32:30.739Z
---

Measured 2026-08-03 on the live Railway project `vadash-bigcapital-rt`.

**Bigcapital is database-per-tenant, not row- or table-per-tenant.** Confirmed from the
server's own config: `TENANT_DB_NAME_PERFIX=bigcapital_tenant_` (their typo), plus
`init-db.sql` granting `CREATE ON *.*` because the app issues `CREATE DATABASE` at
runtime. Every book therefore carries a full ~100-table schema.

**Cost: roughly 20-35 MB per empty book.** 10 working books + the system DB + InnoDB
overhead = 368MB of a **500MB** volume (Railway's free default).

**The ceiling is real and we hit it at book #13.** Symptom, from `railway logs --service
server`:

```
ER_CANT_CREATE_TABLE (errno 1005)
Can't create temporary table for ALTER TABLE `bigcapital_tenant_<id>`.`ITEMS`
(errno: 135 "No more room in record file")
```

InnoDB cannot build the temp table for `ALTER TABLE ... ADD CONSTRAINT` during the
tenant migration. The organization and its database ARE created, the schema migration
dies part-way, `tenant.is_ready` stays false forever, and our side reports the useless
"was not ready after 120s". 24 occurrences across exactly 3 tenants. Also 8 `ESOCKET`
errors, matching intermittent connect timeouts from our side.

**Planning numbers:** a firm with 50 single-company clients ≈ 1-1.75 GB; the same firm at
3 companies each ≈ 3-5 GB; ten such firms ≈ 30-50 GB.

**This is why registering a company must NOT auto-create a book** (see
[[books-multi-company-plan]]) — a typo'd company name would permanently consume ~30MB.

**Diagnosis access:** a Railway PROJECT token works for `status`, `logs`, `variables`,
`volume list`, `metrics`. It does NOT work for `ssh` or `list` (account-scoped).
`railway connect` rejects this MariaDB service ("No supported database found"), the
service has no Data tab, `MARIADB_PUBLIC_HOST` is empty (no TCP proxy), and
`railway volume update` cannot change SIZE — only name and mount path. So resizing the
volume and running any SQL both require the dashboard, or temporarily enabling the TCP
proxy.

Fix: enlarge the mariadb volume (500MB → 2GB+), then retry the stuck books. Related:
[[bigcapital-deployment]], [[books-multi-company-plan]].

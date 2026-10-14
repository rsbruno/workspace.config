---
name: backend-sql
description: Drizzle repository rules — query shape, tenant boundary in SQL, soft-delete transitions, real pagination, filter composition, joins, transactions.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-sql

Owns the Drizzle code inside every repository. Domain skills (`backend-schema`, `backend-cqrs`, `backend-filter`) decide what the model needs; this one decides how it becomes a correct, fast query. Load together with the domain skill that applies.

## Core rules

- Two repositories per module: `{module}-query.repository.ts` (only `SELECT`) and `{module}-command.repository.ts` (only `INSERT`/`UPDATE`, `.returning()`). DB injected via `DATABASE_CONNECTION`.
- Every method on an organization-owned table receives explicit `organizationId` and applies it in `WHERE`, reads and writes, including child tables, joins, subqueries and `ON CONFLICT`. No hidden session state or optional-condition base repository.
- Every soft-deletable table in a join chain gets its own `deletedAt IS NULL`.
- Single-row lookup: `.limit(1)` then `result.at(0) ?? null`.
- Lifecycle is `UPDATE` only: archive/delete/restore with their `archivedAt`/`deletedAt` guards, returning whether a row changed. Never `db.delete()`.
- Pagination: `LIMIT/OFFSET` in SQL; page + `count(*)` in `Promise.all` with same joins and `where`; stable `orderBy` with primary key tie-breaker; every filter/sort column indexed.
- Writes are built field by field. No spread into `.values()`/`.set()`.
- Filters compose in one `and(...)` with `undefined` for absent ones. `ilike` input always through `escapeLike`.
- No N+1: batch with `inArray` or a join. Multi-table writes in `this.db.transaction`.
- Raw `sql` last resort, values only through tagged-template interpolation.
- Money/scaled columns written and returned exactly as received. Never multiply, divide or round.

## References

| Read when | File |
|---|---|
| Writing any repository method (reads, create/update/archive/delete/restore) | [references/reads-and-writes.md](references/reads-and-writes.md) |
| Writing a paginated listing | [references/pagination.md](references/pagination.md) |
| Composing filters or building write payloads | [references/filters-and-write-boundary.md](references/filters-and-write-boundary.md) |
| Joins, batching, transactions, raw SQL, `ilike`, scaled columns | [references/joins-transactions-raw-sql.md](references/joins-transactions-raw-sql.md) |
| Before declaring a repository method done | [references/performance-checklist.md](references/performance-checklist.md) |

Related: `backend-schema`, `backend-filter`, `backend-cqrs`, `backend-test`.

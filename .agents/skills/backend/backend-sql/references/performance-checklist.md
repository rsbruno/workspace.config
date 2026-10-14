# Performance checklist

## 12. Performance checklist (every repository method)

Before considering a repository method done, confirm each item:

1. Explicit column list for response-shaped reads; full row only when the caller needs it.
2. `limit(1)` + `result.at(0) ?? null` on single-row lookups.
3. `organizationId` + `deletedAt` conditions present (section 2) and covered by an index whose leading column is `organizationId`, followed by the filter/lifecycle/order columns used by the listing (`(organization_id, archived_at, deleted_at, name)`). Missing index → migration in the same change. The leading `organization_id` index is enforced for every table by `database-schema.spec.ts` (`backend-schema` 3.7).
4. Page + count in `Promise.all`, same joins and `where`, stable `orderBy`.
5. No query inside a loop/map (N+1) — batch with `inArray`, or a single join.
6. Site-scoped data (`backend-cqrs` 2.2.2) filters by `inArray(table.siteId, siteIds)` (or an `exists` on the allocation table) in the same query, and the site column has an index next to `organization_id`.
7. No `select` of a whole related table to filter in JavaScript; filtering, counting and existence checks happen in SQL (`exists`, `count`, `limit(1)`).
8. Multi-table writes inside `this.db.transaction` (section 8).
9. A heavy listing or report query (several joins, large tables) gets an `EXPLAIN` check on the dev database during the refactor; a sequential scan on an organization-owned table is a missing index.

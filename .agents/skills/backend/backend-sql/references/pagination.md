# Pagination: real, parallel, indexed

## 4. Pagination — always real, always parallel, always indexed

- **`LIMIT`/`OFFSET` at the database, never fetch-all-then-`.slice()`** — see `backend-cqrs` for when a `findAll` needs pagination at all; once it does, it's always enforced here.
- **The page query and the `count(*)` query always run in parallel via `Promise.all`, never one `await` after the other** — they're independent queries; awaiting serially just doubles latency for nothing.
- **The count query applies the same joins and the same `where` as the page query.** An `innerJoin` that filters rows (e.g. a joined table with `deletedAt IS NULL`) must also be in the count; otherwise `total` counts rows the page never returns (a common bug).
- **Ordering is stable**: the business order column plus the primary key as tie-breaker (`orderBy(asc(table.name), asc(table.id))`). Without the tie-breaker, rows with equal names can repeat or disappear between pages.

```ts
async findAllWithPagination(limit: number, offset: number, filters: WhereFilters): Promise<[Entity[], number]> {
  const where = and(/* ...conditions, see section 6 */);

  const [data, [totalResult]] = await Promise.all([
    this.db.select().from(table).where(where).limit(limit).offset(offset),
    this.db.select({ count: sql<number>`count(*)` }).from(table).where(where),
  ]);

  return [data, Number(totalResult.count)];
}
```

- **Every column used in `where`/`orderBy` of a paginated listing needs an index.** If the table doesn't have one yet, create the index migration together with the feature's migration — don't ship a paginated filter/sort on an unindexed column and leave it for later.
- **A high `OFFSET` is expensive** (the database still walks and discards the skipped rows) — fine for a typical admin/catalog listing with few pages, which is the default pattern here. Only consider keyset pagination (`WHERE id > :cursor ORDER BY id LIMIT :pageSize`) when the table's expected volume is high (tens of thousands of rows+) or the UI is infinite-scroll — ask the user before switching pattern, don't switch unilaterally.
- **Never `count()` per row or inside a loop/map** — it's always one query, run alongside the page query as shown above.

# No spread at write boundary, filter composition

## 5. No spread at the write boundary (fixed project rule)

Every object written to the database (`.values()`, `.set()`) is built field by field, explicitly — `{ ...payload }` is forbidden here (it's fine elsewhere in the backend: handler returns, module `providers` arrays). A new field on the source type must never leak into a write silently; naming each field makes the contract visible to the compiler and the reviewer.

```ts
// WRONG
await this.db.insert(table).values({ ...payload, id: createCUID('usr') });

// CORRECT
await this.db.insert(table).values({
  authenticatorId: payload.authenticatorId,
  id: createCUID('usr'),
  email: payload.email,
  name: payload.name,
});
```

An optional field uses a ternary on the field itself, never conditional spread: `Text: message.text ? { Data: message.text } : undefined`, never `...(message.text ? { Text: ... } : {})`.

## 6. Filter composition (paired with `backend-filter`'s column-by-column analysis)

Once `backend-filter` decides which columns are filters and their shape, this is how they compose in the repository — every condition optional (`undefined` when the caller didn't send that filter), combined with a single `and(...)`:

```ts
async findAllWithPagination(
  archived: boolean | undefined,
  limit: number,
  offset: number,
  filters: { name?: string; categoryId?: string; createdAtFrom?: Date; createdAtTo?: Date },
): Promise<[Entity[], number]> {
  const where = and(
    isNull(table.deletedAt),
    archived === true ? isNotNull(table.archivedAt) : archived === false ? isNull(table.archivedAt) : undefined,
    filters.name ? ilike(table.name, `%${escapeLike(filters.name)}%`) : undefined,
    filters.categoryId ? eq(table.categoryId, filters.categoryId) : undefined,
    filters.createdAtFrom ? gte(table.createdAt, filters.createdAtFrom) : undefined,
    filters.createdAtTo ? lte(table.createdAt, filters.createdAtTo) : undefined,
  );
  // ...paginated select + count, section 4
}
```

The archive split is a parameter of this same method: `archived=true` filters archived rows, `archived=false` filters active rows, and omitted means both. `deletedAt` is never a caller-controlled filter and is always `isNull`.

For organization-scoped codes, keep uniqueness in PostgreSQL with a partial unique index over the full business key and `deletedAt IS NULL`. Do not add a duplicate-code lookup to create or update handlers. The database constraint and the global infrastructure filter are the source of truth.

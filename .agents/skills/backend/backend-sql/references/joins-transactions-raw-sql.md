# Joins, transactions, raw sql, ilike, scaled columns

## 7. Joins and multi-table reads

- Prefer `innerJoin`/`leftJoin` with the join condition (and any per-table `deletedAt IS NULL`, section 2) in the `.on(...)`/`.where(...)` clause over N+1 (a `map` issuing one query per row).
- When a listing needs child/related rows (e.g. members per group), fetch the page first, collect the ids, then one batched query with `inArray(...)` for the related rows — never a loop of per-id queries.

## 8. Transactions

Use `this.db.transaction(async (tx) => { ... })` whenever a single logical write touches more than one table and both must succeed or both must roll back (e.g. creating a row and its pivot-table associations together). Every statement inside uses `tx`, not `this.db`.

## 9. Raw `sql` — last resort, always parameterized

Only drop to `` sql`...` `` when no Drizzle query-builder operator covers the case. Values always go through tagged-template interpolation (`` sql`${value}` ``), which Drizzle parameterizes safely — never build the string with plain JS concatenation/`String.raw`, that's SQL injection. If you reach for raw `sql` more than once for the same shape, check the Drizzle docs for an operator that already covers it before assuming raw SQL is required.

## 10. `ilike` always escapes the user input

Every `ilike` built from user input wraps the value with `escapeLike` (`src/http/helpers/escape-like.helper.ts`): ``ilike(table.name, `%${escapeLike(search)}%`)``. Without it, `%` and `_` typed by the user become wildcards (`search=%` lists everything). Unit tests assert the escaped parameter; integration tests assert `search=%` returns nothing.

## 11. Integer-scaled and money columns

Money (cents) and integer-scaled values (`backend-schema` 2.1.4/2.1.5) are `integer` or `bigint('col', { mode: 'number' })`. The repository writes and returns the integer exactly as received — it never multiplies, divides or rounds by the scale. `numeric` columns return strings unless `mode: 'number'`; a new `numeric` column needs the explicit exception from `backend-schema` 2.1.5.

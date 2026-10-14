# Filter operator and query param by column type

## 2. Filter shape by column type

| Column type | Filter operator | Query param type | Example |
|---|---|---|---|
| `varchar` free text (name, title, email) | partial match, case-insensitive — `ilike(column, '%value%')` | `string`, optional | `?name=maria` matches "Maria Silva" |
| `varchar`/`integer` exact identifier (slug, code, external id) | exact match — `eq(column, value)` | `string`/`number`, optional | `?slug=blue-shirt` |
| Business enum (`integer` column, see `backend-schema` 2.1.3) | exact match — `eq(column, value)`, or `inArray(column, values)` if multi-select makes sense | the TypeScript enum type, optional, `@IsEnum({Entity}Enum)` | `?type=1` |
| Foreign key (`varchar` referencing another table's `id`) | exact match — `eq(column, value)` | `string`, optional | `?categoryId=cat_xxx` |
| `boolean` | exact match — `eq(column, value)` | `boolean`, optional, `@IsBoolean` + the explicit `'true'`/`'false'` `@Transform` below | `?featured=true` |
| `timestamp`/date | range — `gte(column, from)` / `lte(column, to)`, combine with `and()` when both given | two optional params, `{field}From`/`{field}To`, `@IsDateString` | `?createdAtFrom=2026-01-01&createdAtTo=2026-01-31` |
| `archivedAt` soft-delete lifecycle | `archived=true` → `isNotNull(column)`, `archived=false` → `isNull(column)`, omitted → both | `boolean`, optional, `@IsBoolean` + the explicit `'true'`/`'false'` `@Transform` below | `?archived=true` lists archived rows |

**Never use `@Type(() => Boolean)` on a query param**: class-transformer turns any non-empty string into `true`, so `?archived=false` becomes `true`. Booleans from the query string always use `@Transform(({ value }: { value: unknown }) => (value === 'true' ? true : value === 'false' ? false : value))` + `@IsBoolean({ message: 'invalid' })`, so anything else is rejected with 400.

Never use `ilike` on a low-cardinality column (enum/boolean/fk) — it's always exact match there. Never use exact match on free text meant for search — partial + case-insensitive is what makes the filter usable. `code` is an exact identifier and uses `eq`; only a genuine name/search field gets `ilike`. `deletedAt` is never exposed as a filter.

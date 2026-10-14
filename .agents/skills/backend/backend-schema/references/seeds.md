# Initial data seeds

## 3.6 Initial data seed (when the user asks for it) — never duplicates on re-run

Seed lives in `drizzle/seeds/{module}/`, one folder per entity with two files:

```
drizzle/seeds/{module}/
├── data.json     # values already ready to go into the DB -- id, slug etc already computed, no generation logic in the seed
└── index.ts      # export async function seed{Entities}(db) { ... }
```

`data.json` carries the **final** values, not a raw shape to transform — `id` is already a fixed CUID (generated once, hardcoded), `slug` already comes computed, no calling `slugify`/`createCUID` inside the seed's `index.ts`. This makes the seed deterministic across runs and environments (always the same `id`, never depending on runtime generation).

`index.ts` **synchronizes** the table with the JSON (the JSON is the catalog source of truth), following the project's existing catalog seed:

1. Rows stored in the table (not deleted) whose natural key is no longer in the JSON get `archivedAt = deletedAt = now` — never a physical delete.
2. For each JSON row, look up the existing row by `id`, then by the natural key (`code`, `slug`, ...), each with `.limit(1)`.
3. Existing → `update` with the explicit JSON fields, clearing `archivedAt`/`deletedAt` (reactivates a row that came back to the catalog).
4. Missing → `insert` with ``.onConflictDoNothing({ target: table.{naturalKey}, where: sql`${table.deletedAt} is null` })``, matching the partial unique index of the table.

```ts
export async function seed{Entities}(db: NodePgDatabase<typeof schema>) {
  // 1. soft-delete rows removed from data.json
  // 2-4. upsert each data.json row by id, then by natural key
  logger('{ENT}', 'CRE', '{entities} seeded');
}
```

Registered in `src/configs/seeds/database/index.ts` (import + call inside `main()`, same order as the others), run with `pnpm db:seed` (permanent bypass).

`logger` (`src/configs/seeds/logger.ts`) has a fixed union of entity abbreviations — add the new one (3 letters) to the `SeedEntity` type if it doesn't exist yet.

**Running the seed twice must never duplicate or resurrect wrongly.** The natural key has a partial unique index (``uniqueIndex(...).on(table.code).where(sql`${table.deletedAt} is null`)``), never `id` alone. If the entity has no natural key besides `id`, add one before writing the seed. Catalog seeds that mirror enums (policies, features, modules) are additionally pinned by `src/__tests__/unit/seeds/catalog-seeds.spec.ts` (`backend-rule`).

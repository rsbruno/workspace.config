---
name: backend-schema
description: Drizzle schema rules — soft delete, pivots, integer enums, money in cents, scaled numbers, dates, column sizing, slug, seeds.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-schema

Fixed rules for table schemas and seeds (Drizzle + PostgreSQL). Load `backend-sql` too when a repository file is involved.

## Core rules

- Archivable/deletable tables: `archivedAt` + `deletedAt` + `createdAt` + `updatedAt`. No `status` column for lifecycle, no physical `DELETE`. `deletedAt` is never exposed.
- Pivot (N:N) tables live in the higher-hierarchy entity's `.schema.ts`; table name is `plural_plural`.
- Global catalog stays free of `organizationId`; org variants go in a separate org-scoped table with unique `(organizationId, entityId)`.
- Business enums: `integer` column, TS numeric enum starting at `1`. Every numeric enum used in Swagger is registered in `swagger.config.ts`.
- Money: integer cents (`integer` or `bigint`), semantic name, no `cents` suffix. Other fractional values: integer-scaled, same integer from API to DB, backend never multiplies/divides.
- Calendar date: `date()` as `'YYYY-MM-DD'` string, never `Date`. Instant: `timestamp()`.
- `varchar` has a deliberate length; `name` = 100, `description` = 200. DTO mirrors it with `@MaxLength` and Swagger `maxLength`.
- `slug`: `varchar().unique()`, generated on create only, from `name`, with incremental suffix resolved in the command repository.
- Seeds: `data.json` with final values, `index.ts` syncs (soft-delete removed, upsert by id then natural key), idempotent.
- Every table with `organization_id` has an index led by `organization_id`. Business uniqueness lives in partial unique indexes (`deletedAt IS NULL`).
- Schema must match the database (drift test). Migration leaves drift list unchanged or smaller.

## References

| Read when | File |
|---|---|
| Any archivable table, lifecycle columns, inferred payload types | [references/soft-delete.md](references/soft-delete.md) |
| Pivot table, or global catalog + per-organization reference | [references/pivots-and-base-tables.md](references/pivots-and-base-tables.md) |
| Adding a business enum or using one in Swagger | [references/enums.md](references/enums.md) |
| Money, quantity, percentage, date/instant columns | [references/money-numbers-dates.md](references/money-numbers-dates.md) |
| `varchar` size, DTO limit mirror, `slug` | [references/columns-and-slug.md](references/columns-and-slug.md) |
| Writing or changing a seed | [references/seeds.md](references/seeds.md) |
| Indexes, uniqueness, drift test, organization-scoped entity pattern | [references/schema-tests-and-reference-pattern.md](references/schema-tests-and-reference-pattern.md) |

Related: `backend-sql`, `backend-cqrs`, `backend-dto`, `backend-test`.

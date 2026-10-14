# Schema drift test and organization-scoped reference pattern

## 3.7 The schema matches the database, and organization tables are indexed (tested)

`src/__tests__/integration/architecture/database-schema.spec.ts` runs against the dev database and checks two things:
- **Schema drift:** every `.schema.ts` table is identical to the database: the same tables and columns, the same type (`varchar(n)`, `integer`, `bigint`, `numeric(p, s)`, `date`, `timestamp`...) and the same nullability. A column that exists only in the database or only in the schema is drift.
- **Organization index:** every table with an `organization_id` column has an index whose **first** column is `organization_id`.

Both lists of existing exceptions are ratchets (`knownSchemaDrift`, `knownOrganizationTablesWithoutIndex`) and only shrink. Every migration must leave the drift list unchanged or smaller. Apply it to the dev database (`APP_ENV=dev pnpm db:migrate`) and run `pnpm test:architecture` in the same task.

## 4. Organization-scoped reference pattern

For organization-scoped organization-scoped entities, replicate these schema decisions:

- `organizationId` is required, references `organizationsTable.id`, and leads every index used by the listing and relations (`(organizationId, archivedAt, deletedAt, <order column>)`). A table owned by an organization without its own `organizationId` is only acceptable for a child row reached exclusively through a parent scoped by organization.
- `deletedAt` is the partial-uniqueness boundary. A business code may be repeated only by rows with `deletedAt` set.
- Put every real business uniqueness rule in a database unique index. For accounts, the key is `(organizationId, groupId, subgroupId, code)` where `deletedAt IS NULL`; for groups, it is `(organizationId, code)` where `deletedAt IS NULL`.
- Do not prevalidate duplicate codes in a command. Let PostgreSQL raise the constraint error and let the global infrastructure filter translate it without exposing the database constraint name.
- Self-referencing hierarchy uses `parentId`; group and subgroup behavior is selected by the use case, not a persisted status column.
- Numeric domain values such as account type, expense type and hierarchy level are integer columns with TypeScript enums and generic `@IsEnum` validation.
- The module schema contains only persistence definitions. Default chart-of-accounts data is not registered in the regular module seed; it belongs to a separate seed script when requested.

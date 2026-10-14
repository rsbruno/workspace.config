# Pivot tables and global base + organization reference tables

## 2.1.2 Pivot/junction table (N:N) — always in the schema of the higher-hierarchy entity (fixed project rule)

A pivot table (e.g. `organizations_members`, linking `organizations` to `users`) **does not get its own `.schema.ts` file**. It's declared inside the same `{module}.schema.ts` file as the entity of **higher hierarchy** of the two sides of the relation — the "owning"/container entity, not the "member" entity. `organizations` is the higher-hierarchy entity relative to `users` in a membership (the organization is the container, the user is the element), so `organizationMembersTable` lives inside `organizations.schema.ts`, never in a separate `organizations-members.schema.ts`.

How to decide which side is "higher hierarchy": whichever entity **contains/groups** the other in the business rule (not module size or alphabetical order). If the relation is between two entities of the same module (e.g. `orders` and `order_items`), the pivot/child table already naturally lives in the module's schema — this rule matters when the pivot crosses two different modules (e.g. `access/organizations` + `access/users`).

### Pivot table name: always `plural_plural` (fixed project rule)

The table name itself (the string passed to `pgTable(...)`) follows **plural_plural** — the two related entities, each in plural, in this order: `{higherHierarchyEntityPlural}_{lowerEntityPlural}`. Never `singular_plural` (e.g. `organization_members` is wrong — the correct form is `organizations_members`), even when the table has extra columns (`status`, `role`, `signedAt` etc.) and isn't a "pure" join — the table naming rule doesn't change because of that, only the fact that it has its own `id` (always does, rule 2.1) and doesn't rely on a composite PK.

```ts
// WRONG — singular_plural
export const organizationMembersTable = pgTable('organization_members', { /* ... */ });

// CORRECT — plural_plural
export const organizationMembersTable = pgTable('organizations_members', { /* ... */ });
```

The TypeScript `const`/variable name (`organizationMembersTable`) stays normal camelCase, unrelated to this rule — only the table name string in the database follows `plural_plural`.

```ts
// {module}.schema.ts — the higher-hierarchy entity's schema also carries the pivot table
import { usersTable } from '@/modules/v1/access/users/infrastructure/database/drizzle/users.schema';

export const organizationsTable = pgTable('organizations', { /* ... */ });

export const organizationMembersTable = pgTable('organizations_members', {
  organizationId: varchar('organization_id', { length: 128 }).notNull().references(() => organizationsTable.id),
  userId: varchar('user_id', { length: 128 }).notNull().references(() => usersTable.id),
  // ...
});
```

The pivot repository (`{module}-members-command.repository.ts`/`-query.repository.ts`, if any) still lives in its own file under `infrastructure/database/drizzle/` — only the `.schema.ts` is merged.

## 2.1.2b Global base entity + organization-scoped reference table (fixed project rule, replaces "derived value" columns)

Never store a derived/computed value inline on a global entity's own row (e.g. a `products`/`items` row carrying its own per-organization variant of itself). Instead, split into **two tables**:

1. **Global base table** (`{module}.schema.ts`) — the shared catalog, no `organizationId`.
2. **Organization-scoped reference table**, always declared inside `organizations.schema.ts` (same placement rule as pivot tables, 2.1.2) — one row per `(organizationId, {entity}Id)`, with its own `id`, lifecycle timestamps when it supports archive/delete, and a **unique index on `(organizationId, {entity}Id)`**.

```ts
// {module}.schema.ts — global base table, no organizationId
export const {entities}Table = pgTable('{entities}', {
  id: varchar('id', { length: 128 }).primaryKey().notNull(),
  name: varchar('name', { length: 100 }).notNull(),
  // ...
});

// organizations.schema.ts — org-scoped reference table
export const organization{Entities}Table = pgTable(
  'organization_{entities}',
  {
    organizationId: varchar('organization_id', { length: 128 }).notNull().references(() => organizationsTable.id),
    {entity}Id: varchar('{entity}_id', { length: 128 }).notNull().references(() => {entities}Table.id),
    id: varchar('id', { length: 128 }).primaryKey().notNull(),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at').notNull().defaultNow(),
    deletedAt: timestamp('deleted_at'),
    archivedAt: timestamp('archived_at'),
  },
  (table) => [uniqueIndex('organization_{entities}_organization_id_{entity}_id_idx').on(table.organizationId, table.{entity}Id)],
);
```

**Response DTO**: the org-scoped DTO wraps the base entity's own DTO as a nested typed property — never a loose/inline shape. The nested property **must** carry `@Type(() => {Entity}Dto)` alongside `@Expose()`/`@ApiProperty`, otherwise `plainToInstance(..., { excludeExtraneousValues: true })` skips the nested object and the raw table row (every internal column) leaks into the response unfiltered:

```ts
// organization-{entity}.dto.ts
@Expose()
@Type(() => {Entity}Dto)
@ApiProperty({ type: {Entity}Dto })
{entity}: {Entity}Dto;
```

Do **not** reuse the same DTO class for both the base entity and the org-scoped wrapper's nested field (self-referential typing like `{Entity}Dto.base?: {Entity}Dto` is ambiguous about which level of the relation it represents) — two distinct DTOs, one per table, matching the two-table split.

When migrating an existing inline/derived-value column to this pattern, remove the legacy column and its handler fallback in the same change — don't keep both the old field and the new `{entity}Id` reference alive together "just in case"; that's incomplete migration, not backward compatibility.

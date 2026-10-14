# Soft delete: archivedAt and deletedAt

## 2.1 Soft delete is mandatory — `archivedAt` and `deletedAt`

The accounts and account-groups modules are the canonical implementation for soft deletes across the platform. Tables that can be archived or deleted do not have a `status` column for this concern and never execute a physical `DELETE`.

```ts
deletedAt: timestamp('deleted_at'),
archivedAt: timestamp('archived_at'),
createdAt: timestamp('created_at').notNull().defaultNow(),
updatedAt: timestamp('updated_at').notNull().defaultNow(),
```

The lifecycle is explicit:

- `archive` sets `archivedAt`.
- `restore` clears `archivedAt` and is allowed only for an archived, non-deleted row.
- `delete` sets `deletedAt` and is allowed only after archive.
- `update` does not alter archived rows.
- `deletedAt` is eliminatory: every query and every command treats the row as nonexistent when it is not null. The delete command is the only exception while locating the row it will delete, and it still cannot delete an already deleted row.
- Any repeated archive, delete, or restore operation returns the domain action-already-performed error instead of silently succeeding.

Every query, join and relation lookup excludes `deletedAt` rows. A listing may expose only the `archived` filter: `true` returns archived rows, `false` returns active rows, and an omitted filter returns both active and archived rows. There is no deleted filter and `deletedAt` is never a public response field.

The command and query repositories remain separate. Commands and queries validate existence through the module's `Find<Entity>Query`; related entities are accessed through `QueryBus`, and a deleted relation is treated as nonexistent. The command repository only persists the explicit timestamp transition. Expected Drizzle constraint errors are handled by global filters, not by duplicated repository `try/catch` blocks.

### Inferred types

Exclude lifecycle and timestamp columns from payloads exposed to handlers:

```ts
export type Create<Entity>Payload = Omit<typeof table.$inferInsert, 'id' | 'deletedAt' | 'archivedAt' | 'createdAt' | 'updatedAt'>;
export type Update<Entity>Payload = Partial<Omit<typeof table.$inferInsert, 'id' | 'deletedAt' | 'archivedAt' | 'createdAt' | 'updatedAt'>>;
```

### Response DTO

Expose `archivedAt` as a nullable date when the frontend needs the archive state. Never expose `deletedAt`; a deleted record is absent from every public response.

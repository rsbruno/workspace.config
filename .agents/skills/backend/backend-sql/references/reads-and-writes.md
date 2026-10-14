# Repository shape, reads, writes

## 1. Repository shape (fixed project rule)

Two repositories per module, never one merged class:

- `infrastructure/database/drizzle/{module}-query.repository.ts` — class `{Module}Repository`, only `SELECT`. Every method returns already-typed data (`typeof table.$inferSelect`), never a raw untyped row.
- `infrastructure/database/drizzle/{module}-command.repository.ts` — class `{Module}CommandRepository`, only `INSERT`/`UPDATE` (never a physical `DELETE`, see section 3). Every write method returns what the caller needs (`.returning()`), never a bare `void` when the handler needs the created/updated row.

Both inject `@Inject(DATABASE_CONNECTION) private readonly db: NodePgDatabase<Record<string, never>>` — never a different DB handle, never instantiate a client locally.

## 2. Reads — `SELECT`

- **Never `select *` implicitly and then throw fields away in the handler.** `this.db.select().from(table)` (all columns) is fine when the caller needs the full row (e.g. a command repository's own lookups); when a query repository serves a slim response DTO, prefer an explicit column list (`this.db.select({ id: table.id, name: table.name })`) so the query doesn't fetch/transfer columns nobody will read (see the real example on `ItemsRepository.findAll` — only the response columns of the unit and of its joined base are selected, not the full rows).
- **A single-row lookup always has `.limit(1)`** and returns `result.at(0) ?? null` — never assume the array has exactly one element, never index `[0]` without an existence check.
- **Every `WHERE` combines conditions with `and(...)`**, one `eq`/`ilike`/`gte`/`lte`/`inArray` per condition, never string-concatenated SQL, never a raw template unless no Drizzle operator covers the case (and if so, use `` sql`...` `` with parameter placeholders, never interpolated values — see section 6).
- **Every query crossing a relation (join/FK) that involves a soft-deletable table validates `deletedAt IS NULL` on EACH table in the chain, not just the final table.** Before considering a join query done, list every soft-deletable table it crosses and confirm each has its own `isNull(table.deletedAt)` condition. A deleted parent or relation makes the result nonexistent.
- **Organization scope is a mandatory repository boundary on every `WHERE`, reads and writes alike.** Every method of a repository over an organization-owned table receives the explicit `organizationId` and adds `eq(table.organizationId, organizationId)` — `findById(id, organizationId)`, `findAll(organizationId, ...)`, `update/archive/delete/restore(id, organizationId, ...)`. A method that can return or change a row without the organization condition is a data leak, even if the handler validated the row first; the `UPDATE`, `INSERT` conflict action or other write must not rely on a previous `SELECT`. Apply the condition to every organization-owned child table, join, subquery and pivot involved in the operation. For `ON CONFLICT DO UPDATE`, constrain the conflict update to the same organization when the target can be shared. Do not hide this rule behind the session, `AsyncLocalStorage`, middleware, ORM magic or a generic base repository that makes the condition optional: the repository method must receive and visibly apply the organization scope. Global catalogs (no `organizationId`) are the only exception and are documented as such (`backend-refactor` 2.1).

## 3. Writes — `INSERT`/`UPDATE`, never `DELETE FROM`

- **`create`**: insert every field explicitly and do not write lifecycle columns unless the use case requires it. The database defaults null `deletedAt` and `archivedAt`. Always `.returning()` the row the caller needs.
- **`update`**: set every editable field explicitly, include `updatedAt: new Date()`, and `WHERE id = ? AND organizationId = ? AND archivedAt IS NULL AND deletedAt IS NULL`; `.returning()` the row so the handler can detect a `null` (no row changed). The application also validates existence and blocks updates to archived rows; a deleted row is always nonexistent.
- **`archive`**: `UPDATE ... SET archivedAt = new Date(), updatedAt = new Date() WHERE id = ? AND organizationId = ? AND archivedAt IS NULL AND deletedAt IS NULL`, returning whether a row changed.
- **`delete`**: `UPDATE ... SET deletedAt = new Date(), updatedAt = new Date() WHERE id = ? AND organizationId = ? AND archivedAt IS NOT NULL AND deletedAt IS NULL`, returning whether a row changed. Never call `this.db.delete(table)`.
- **`restore`**: `UPDATE ... SET archivedAt = NULL, updatedAt = new Date() WHERE id = ? AND organizationId = ? AND archivedAt IS NOT NULL AND deletedAt IS NULL`, returning whether a row changed.
- The `organizationId` condition above is omitted only for global catalog tables (no `organizationId` column) and for child tables scoped through their parent (`backend-sql` 2).
- The handlers run the `Find<Entity>Query` before each lifecycle mutation so missing records, deleted relations and repeated actions receive the domain error. Repository methods keep only the SQL transition and do not contain duplicated `try/catch` blocks for errors handled by global filters.

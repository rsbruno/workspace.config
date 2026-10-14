# Unit tests: handlers, DTOs, repositories, controller

## 4. Unit tests

**Command handlers** (`<module>-commands.handlers.spec.ts`), one `describe` per handler:
- Build dependencies through one `createDependencies()` that returns a jest-mocked repository and `queryBus`. Pass them as `as never`.
- Assert the exact queries dispatched (`toHaveBeenCalledWith(new FindXQuery(id, organizationId))`) and the exact, explicit repository payload. The payload includes the command's `organizationId`, never one coming from the payload.
- Every error branch uses `expectBusinessError(..., code, status)` and asserts the repository write was **not** called.
- Cover: happy path, each precondition error, relation invalid, repository transition returning `false`/`null`, and the not-found propagated for another organization.

**Query handlers**: assert the repository call (organization, limit/offset math, filters object), the DTO instance types (`toBeInstanceOf`), and that internal fields (`organizationId`, `deletedAt`, extra columns of joined tables) are **not** exposed.

**DTOs** (`<module>-dtos.spec.ts`): `plainToInstance` + `validate(..., { whitelist: true, forbidNonWhitelisted: true })`.
- Use `describe.each` over create/update payloads when they share rules.
- Cover trimming, every boundary from the inventory, the exact message key in `constraints`, and client-sent `organizationId`/`archivedAt`/`deletedAt`.
- A `'<module> translations'` block checks `untranslatedValidationMessagesOf(dto)` is `[]` for every DTO, and `untranslatedExceptionCodes` is `[]` for every `CodeExceptions` value with the module prefix.

**Repositories**: use `createSelectDatabase`/`createWriteDatabase` and compile the captured `where`/join with `compileCondition`. Every repository test asserts the SQL, not only the returned value:
- `"<table>"."organization_id" = $n` with the organization in `params`, on every read **and** every write.
- Organization isolation is asserted on every organization-owned table touched by the method, including child tables, joins, subqueries, pivots and `ON CONFLICT DO UPDATE` predicates.
- `"<table>"."deleted_at" is null` on the table and on every joined soft-deletable table.
- The lifecycle condition for each transition (`archived_at is null` / `is not null`).
- Escaped search parameters (`%50\\%\\_a%`), `limit`/`offset`, `limit(1)` on single-row lookups.
- The count query uses the same joins and the same `where` as the page query.
- `db.delete` is never called.

**Controller**: dispatch test (every command/query receives `user.organizationId`) plus a metadata matrix with `it.each` over every method: `METHOD_METADATA`, `PATH_METADATA`, `FEATURE_KEY`, `CAN_KEY` (or `undefined` for a documented exception), `AUDIT_KEY` on writes, `HTTP_CODE_METADATA` for `201`/`204`.

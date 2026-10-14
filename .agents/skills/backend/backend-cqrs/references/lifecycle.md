# Standard lifecycle

## 2.3 Standard lifecycle

Use `accounts` and `account-groups` as the canonical shape for every database-backed module with this lifecycle:

- `Create` validates related entities through `QueryBus`, then inserts explicit fields.
- `Update` validates the record and relations through `Find{Entity}Query`, rejects deleted or archived records, then updates only editable fields.
- `Archive` validates a non-deleted record and sets `archivedAt`; a repeated archive returns the action-already-performed error.
- `Delete` validates a non-deleted record, requires it to be archived, then sets `deletedAt`; it never physically deletes.
- `Restore` validates a non-deleted archived record and clears `archivedAt`.
- Every `Find` and `FindAll` excludes `deletedAt`; a missing or deleted relation is reported as the main record being nonexistent where the domain requires that behavior.
- `FindAll` accepts only the optional `archived` filter for lifecycle state. Omitted means active plus archived; `deletedAt` is never a filter.
- Commands and queries do not add broad `try/catch` blocks. Business errors use `BusinessException`; expected database constraints are translated by global filters.
- Every repository transition result is checked. `archive`/`delete`/`restore` return `boolean` and `update` returns the row or `null`; a `false`/`null` result (row changed concurrently between the `Find` and the write) raises the same domain error as the precondition, never a silent success.
- `QueryBus`/`CommandBus` results are typed at the call site: `this.queryBus.execute<FindItemQuery, ItemDto>(new FindItemQuery(id, organizationId))`. An untyped `execute` returns `any` and is forbidden.
- The handler validates only what the payload DTO cannot know (relations, lifecycle state, business rules). Presence, type, length and range are the DTO's job; a handler check that duplicates a DTO rule means the DTO is wrong (e.g. an optional DTO field the handler then requires).
- Hierarchical listings join and validate the parent with `deletedAt IS NULL`; a child response computes effective archive state from itself and its parent. An archived parent makes its descendants effectively archived.

Do not add Redis code-reservation strategies for this pattern. A next-code endpoint is a GET query and returns a dedicated `{ code: string }` DTO; uniqueness remains enforced by the database.

For hierarchical code generation, keep the required scope in the endpoint: group `next-code` uses the organization, subgroup `next-code` uses the parent group, and account `next-code` uses the subgroup. Validate the referenced group or subgroup through its `Find` query before calculating the first available code in ascending order.

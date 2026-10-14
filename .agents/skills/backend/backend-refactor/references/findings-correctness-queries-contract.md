# Findings: lifecycle, numbers, queries, boundaries, contract

### 2.4 Lifecycle and handler correctness

- Lifecycle per `backend-schema` 2.1 and `backend-cqrs` 2.3.
- Every repository transition result is checked. A `false`/`null` result raises the domain error (concurrency), never a silent success.
- `QueryBus.execute` is typed (`execute<FindXQuery, XDto>`). No implicit `any` flows into a handler.

### 2.5 Numbers: integer-scaled, money in cents

Use decimals as little as possible. Apply `backend-schema` 2.1.4 and 2.1.5:
- **Money:** always integer cents. Use `integer`, or `bigint` mode number when the range requires it. Never `numeric`.
- **Other fractional values** (quantity, percentage, rate, area, weight): integer scaled by `10^scale`, with the scale decided per field. `numeric` is acceptable only where exact arithmetic is irrelevant, and that exception is reported.
- **Names:** semantic, never a `cents`/`scaled`/`int` prefix or suffix.
- **Same integer end to end:** the API receives the integer, the backend never converts, and the database stores that same integer. The frontend converts for display.

### 2.6 Queries and performance

Apply `backend-sql`:
- explicit column lists;
- `deletedAt IS NULL` on every joined table;
- count query with the same joins as the page;
- parallel page + count;
- stable `orderBy` (business column + `id`);
- `escapeLike` on every `ilike`;
- no N+1;
- an index for every listing `where`/`orderBy` combination;
- `limit(1)` on single-row lookups.

### 2.7 Cross-module boundaries

- No repository or table of another module is imported outside its owner (`backend-cqrs` 2.5 and 2.5.1). Fix by creating a query in the owning module.
- **Deleting/archiving a row another module references:** the rule comes from the requirement docs. If they are silent, ask the developer. Never invent the rule.

### 2.8 Contract and translations

- Response DTOs per `backend-dto`: `nullable` only when the value really can be null, `type: 'integer'` for integer-scaled numbers, and no internal field leaked.
- Every error that reaches the client is a `BusinessException` with a translated code, or a global filter message. No hardcoded text, no native Nest exception with a raw string (`backend-locale`).

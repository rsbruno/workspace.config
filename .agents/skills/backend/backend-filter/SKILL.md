---
name: backend-filter
description: Decide which schema columns deserve a findAll filter, pick the operator per column type, and write DTO and repository condition.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-filter

Analysis first: for each column decide filter or not, report the decision, then write code. Never add every column reflexively, never skip the analysis for "just a listing".

## Core rules

- Report a one-line-per-column list before coding: "filter (operator)" or "not a filter, because X". Ask when no concrete UI need was agreed.
- Never filter by `id`, `deletedAt`, `organizationId`, or internal timestamps (unless a real date range is needed).
- Operators: free text → `ilike` with `escapeLike`; exact identifier, enum, FK, boolean → `eq` (or `inArray` for multi-select); dates → `{field}From`/`{field}To` with `gte`/`lte`; archive → single optional `archived` (true/false/omitted = both).
- Never `ilike` on low-cardinality columns. Never a near-duplicate query to change one filter value.
- Query booleans: never `@Type(() => Boolean)`. Use the explicit `'true'/'false'` `@Transform` + `@IsBoolean`.
- Strings trimmed, blank = no filter, `@MaxLength` (ids 128, text 100), translated `message` on every validator.
- Conditions combine in one `and(...)`, `undefined` when not sent.
- Every filter column gets an index (migration in the same change). Every filter is tested at DTO, repository SQL, integration and E2E levels.
- Numeric enums used in `@ApiQuery` are registered in `swagger.config.ts` (`backend-schema`).

## References

| Read when | File |
|---|---|
| Deciding which columns become filters | [references/analysis.md](references/analysis.md) |
| Choosing operator and param type | [references/shape-by-type.md](references/shape-by-type.md) |
| Writing the DTO, repository `where`, controller wiring, index | [references/implementation.md](references/implementation.md) |

Related: `backend-cqrs` (pagination), `backend-sql`, `backend-schema`, `backend-test`.

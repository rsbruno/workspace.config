---
name: backend-dto
description: Response DTO contract rules for Orval codegen — explicit @ApiProperty typing, nullable vs optional, slim responses, integer typing.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-dto

Response DTOs (`http/dtos/<entity>.dto.ts`) are a typing contract: Orval generates frontend types from OpenAPI, so Swagger decorators are not optional docs.

## Core rules

- Every `@ApiProperty` has an explicit `type`. Never bare `@ApiProperty()`.
- Always present, may be null → `nullable: true`. `@ApiPropertyOptional` is only for input fields the client may omit; response fields are always returned.
- Arrays of objects → `type: () => [ItemDto]`. Nested DTOs carry `@Type(() => Dto)`.
- Expose only what the frontend uses. Never `organizationId`, `userId`, internal pivot ids, `deletedAt`; `createdAt`/`updatedAt` only if the UI shows them. `archivedAt` as nullable date-time when needed.
- Nested relation from `innerJoin` is never nullable; only `leftJoin`/optional FK is.
- Money and integer-scaled values: `type: 'integer'` with a scale description. Returned unchanged.
- DTO names are entity-qualified and globally unique.
- Contract is pinned by the E2E `openapi contract` block. Contract changes are listed as frontend impact.

## References

| Read when | File |
|---|---|
| Typing a field, choosing `nullable` vs optional, arrays | [references/swagger-contract.md](references/swagger-contract.md) |
| Deciding which fields to expose, nested nullability, integers | [references/slim-and-nullability.md](references/slim-and-nullability.md) |

Related: `backend-schema` (enum registration), `backend-cqrs`, `backend-test`.

# Backend (only when the relevant filter doesn't exist in the API yet)

Locate the module at `src/modules/v1/<domain>/<entities>/` (or the matching domain) and edit, in the order of an already-complete listing module:

1. **`queries/list-<entities>/list-<entities>.dto.ts`**: add the field to `List<Entities>QueryDto` with `@ApiPropertyOptional`, `@MaxLength` when it makes sense, `@IsString`/`@IsOptional`. Same description text (in the project's language), same `example`.
2. **`queries/list-<entities>/list-<entities>.query.ts`**: add the field as a new `public readonly` at the end of the CQRS query's constructor.
3. **`queries/list-<entities>/list-<entities>.handler.ts`**: forward the field to the repository's filter.
4. **`infrastructure/database/drizzle/<entities>-query.repository.ts`**: add the field to the `List<Entities>Filter` type and to the `list()` condition — free text uses `ilike(table.field, \`%${value}%\`)`; tax ID/phone uses `ilike` over `digitsOnly(value)` (local function `(value) => value.replace(/\D/g, '')`) to ignore the mask.
5. **`<entity>.controller.ts`**: forward `query.<field>` when building the `List<Entities>Query` in the `list<Entities>` method.

After editing the backend, the frontend's generated client (`src/services/v1/model/list<Entities>Params.ts` and `src/services/v1/<entity>/<entity>.ts`) goes stale — ideally run `npm run gen:api` (orval, needs the local API running) to regenerate; if the API isn't available to run this session, edit `list<Entities>Params.ts` by hand, adding the same fields with the same JSDoc (`@maxLength`), in the same shape orval would generate — never leave the frontend's type out of sync with the backend DTO.

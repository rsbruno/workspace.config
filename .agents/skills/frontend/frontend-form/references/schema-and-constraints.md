# Schema placement, locating the generated DTO, mirroring constraints

## Step 0 — schema placement and shared create/edit payload

The Zod schema lives inside the route family's `_schemas/` folder. When create and edit render the exact same form and every field is editable, use one shared entity schema and one shared `resolver`, as in the canonical CRUD reference. Do not duplicate create/update schemas only because the generated request DTOs have different optionality.

The schema exports the input/output types, defaults and `export const resolver = zodResolver(schema)`. Routes import `resolver` directly; they never call `zodResolver` inline. A transform may map form values into the generated create payload used by both mutations when the backend accepts the same complete editable payload.

## Step 1 — always locate the orval DTO before writing/reviewing a field

Every form that submits to an endpoint has a `Create<Entity>PayloadDto`/`Update<Entity>PayloadDto` (or equivalent request DTO) generated under `src/services/v1/model/`. Before touching the Zod schema or the field component:

1. Find the DTO the mutation actually sends (`mutationFn` payload type).
2. Read every field's JSDoc annotations orval carried over from the OpenAPI spec: `@maxLength`, `@minLength`, `@minimum`, `@maximum`, and whether the field is optional (`field?:`) or required (`field:`).
3. **Only mirror what's actually exported.** If the DTO field has no `@maxLength`/`@minimum`/etc annotation, don't invent one "to be safe" — an un-annotated field has no client-side limit beyond `required`/`optional`. Guessing a number here silently diverges from the backend the moment it changes.

## Step 2 — mirror every declared constraint into both places

A constraint the DTO declares always lands in **two** places, never just one:

- **Zod schema** (`_schemas/<entity>.schema.ts`): `strings.required.max(255)` for a required field with `@maxLength 255`; `z.string().max(200)` for an optional one; numeric `@minimum`/`@maximum` becomes a `.min()`/`.max()` (or a `.refine()` when the field is a masked string, following whatever numeric-mask pattern the schema already uses elsewhere in the project).
- **Field component prop**: the same limit as a native constraint on the controlled component — `maxLength={255}` on `TextFieldControlled`/`TextareaFieldControlled`, so the browser itself stops the user at the limit instead of only failing on submit. Follow the same shape used by the project's existing dialogs for any new field.

Never do only one side — a Zod-only limit lets the user type past it and get surprised on submit; a component-only limit has no server-side-mirrored guarantee if the schema is reused elsewhere (API error handling, tests).

Business validation that is already required by the screen belongs in the schema as well. For codes and identifiers that cannot contain whitespace, use the project's centralized validation message and a no-whitespace rule; do not rely only on visual hints or input behavior.

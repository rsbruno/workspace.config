---
name: frontend-form
description: Choose the controlled field component per field and mirror backend-declared constraints from the generated DTO into Zod and component props.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# frontend-form

Every field is decided from two sources, never guessed: the data's own shape picks the component; the Orval-generated request DTO picks every hard limit. Never invent a constraint the backend does not declare, never skip one it does.

Canonical example: [../frontend-page/references/canonical-crud-reference.md](../frontend-page/references/canonical-crud-reference.md). Read before creating or reviewing a field, schema or create/edit flow.

## Fixed rules

- Locate the generated `Create/Update<Entity>PayloadDto` the mutation sends; read its JSDoc (`@maxLength`, `@minLength`, `@minimum`, `@maximum`, optional vs required). Mirror only what is exported.
- A declared constraint lands in two places: the Zod schema and the field component prop (`maxLength={N}`). Never only one.
- Schema lives in the route family's `_schemas/`, exports types, defaults and `export const resolver = zodResolver(schema)`. Routes import `resolver`; never inline `zodResolver`. Create and edit share one schema when the form and editable fields are identical.
- Pick the component by data semantics, not field name (`TextField` vs `Textarea` vs masked vs date vs combobox vs switch...). List `src/components/controlled/` before assuming a component is missing.
- Section grid: 3 columns max on desktop; wide fields use `col-span`; cramped means a new section.
- Parent-first dependent forms: parent selector first, full row; hydrate the label on edit; code-generation side effects stay in the form section/route, never the generic combobox.
- Empty/placeholder strings come from the project constants (`Strings.EMPTY`, `Strings.UNDEFINED`), never bare `""`/`"-"`.
- Business validation the screen requires (e.g. no whitespace in codes) belongs in the schema.

Out of scope: form chrome and Root/Context layout (`frontend-page`, `frontend-component`).

## References

| Read when | File |
|---|---|
| Writing or auditing a schema, reading the generated DTO | [references/schema-and-constraints.md](references/schema-and-constraints.md) |
| Choosing a field component | [references/field-components.md](references/field-components.md) |
| Parent/child comboboxes, hints, generated codes | [references/dependent-fields.md](references/dependent-fields.md) |
| Arranging fields inside a section | [references/grid-layout.md](references/grid-layout.md) |

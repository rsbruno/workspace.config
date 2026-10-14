---
name: frontend-filter
description: Listing-filter pattern (TanStack Router + React Hook Form + Zod + persisted Zustand) — discover filters, schema, store, fields, i18n keys, route wiring.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# frontend-filter

Reproduces the established listing-filter structure on a new listing screen, adapted to the entity's relevant filters. Replicate structure and conventions, not code blindly. Canonical example: [../frontend-page/references/canonical-crud-reference.md](../frontend-page/references/canonical-crud-reference.md) (active-only default, explicit `Todos`, async comboboxes, name-or-code search).

## Step 0: discover filters (always first)

1. Read the listing route and its table columns: first signal of useful filters.
2. Read the list query options and the generated client params to see what the API already accepts.
3. API covers it: frontend only. Otherwise backend work too → [references/backend-gap.md](references/backend-gap.md).
4. Never invent a filter that is not a real searchable field. Ask when unclear.

## Rules

- Reuse `useFilter`, `createFilterStore`, `PageFilterRoot/Header/Body/Footer/Trigger`, `TextFieldControlled`/`ComboboxControlled`. No new abstraction.
- No comments. File names in English kebab-case. Copy/i18n wording is out of scope (`frontend-locale`).
- Existing filter parts outside the pattern: ask before rewriting.
- Verify semantics before finishing: with an explicit default (e.g. active-only), `schema.parse({})` returns the default (`archived: false`) and the explicit `Strings.EMPTY` option returns `undefined` (`Todos`). The schema distinguishes absent from explicit-empty; no truthiness collapse. Store defaults and route loader agree.
- Tabbed listings: the tab owns `Route.useSearch`, `Route.useNavigate`, `useFilter`, pagination, dialog and query params. Parent passes no filter object or callback. Include the tab discriminator in navigation and reset page on tab/filter change.

## References

| Read when | File |
|---|---|
| Creating schema, store, fields component, status options | [references/schema-and-fields.md](references/schema-and-fields.md) |
| i18n `dialog.filter.fields` keys, route wiring order | [references/i18n-and-route-wiring.md](references/i18n-and-route-wiring.md) |
| API lacks a needed filter | [references/backend-gap.md](references/backend-gap.md) |

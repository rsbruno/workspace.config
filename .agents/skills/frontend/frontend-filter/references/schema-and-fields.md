# Generated file structure (frontend)

For the canonical CRUD implementation, see `../../frontend-page/references/canonical-crud-reference.md` from this reference folder. The rules below describe the reusable shape; the canonical CRUD screen is the authority for active-only defaults and dependent async comboboxes.

Inside the listing route's folder (`src/pages/(privadas)/<module>/<entity>/`):

```
_schemas/<entity>-filter.schema.ts
_stores/<entity>-filter.store.ts
_components/filters/<entities>-filter-fields.tsx
```

Plus, if it doesn't exist yet, a status options file at `src/constants/options/<entities>/status.option.ts`.

## `_schemas/<entity>-filter.schema.ts`

Zod object with every field as an optional `string` (the form always works with strings — mask/combobox), `.transform` converting to the final typed shape (enum values become typed values). `useFilter` clears by calling `schema.parse({})`, but some screens intentionally return a default filter from that state. When the default is active-only, distinguish an absent field from the explicit `Strings.EMPTY` option: absent means active, explicit empty means `undefined` and therefore `Todos`. Exports `<Entity>FilterFormValues` (`z.input`), `<Entity>FilterValues` (`z.output`), `<entity>FilterDefaultValues`, and `to<Entity>FilterFormValues` (the inverse of the transform, to populate the form from applied values/the URL).

Reference: the filter schema of a screen already in the final pattern.

**Fixed rule, no exception: the filter schema always lives inside that screen's own `_schemas/`, never promoted to a shared/group-level `_schemas/` folder** — even when two screens in the same route group need the exact same filter shape (e.g. two entities sharing the same status enum and date-range filter). Duplicate the schema file per screen instead of extracting a shared one — a filter schema is small, and screen-scoped placement is worth more than avoiding a few duplicated lines. This overrides the generic scoped→group→global promotion pattern specifically for schemas in this project.

## `_stores/<entity>-filter.store.ts`

One line: `createFilterStore<<Entity>FilterValues>("<entities>", <entity>FilterDefaultValues)` from `@/store/create-filter-store`. The key (first argument) is the entity's plural name, lowercase, same pattern as `"entities"`/`"lessees"`.

## `_components/filters/<entities>-filter-fields.tsx`

A function component reading `useFormContext<<Entity>FilterFormValues>()` and rendering a `Fragment` with one field per filter, **always via `@/components/controlled`**:

- Free text (name, email) → `TextFieldControlled`.
- Tax ID, phone → `TextFieldControlled` with `mask`/`unmask` from `@/schemas/masks/*`.
- Enum (status, type) → `ComboboxControlled` with `options` from the entity's options file, `searchable={false}` when the list is short (2-5 items).
- Relationship/reference fields → the project's async controlled combobox with generated query options, `getOptionLabel`, `getOptionValue`, `initialLabel`, `searchable` and the query's `pending` state. Dependent child fields remain usable when the parent is empty unless the backend/domain explicitly forbids it.
- Never a raw `<input>`, never a `useState` for an isolated field — every field is controlled by `useFilter`'s form.
- Single filter field → give it `className="sm:col-span-2"` so it spans the full row.

Mandatory `displayName` (`XFilterFields.displayName = "XFilterFields"`), named export (never default).

Reference: the filter-fields component of a screen already in the final pattern.

## `src/constants/options/<entities>/status.option.ts` (if the entity has status and no options file yet)

Same shape as `src/constants/options/<entities>/status.option.ts`: `getLabel`/`getOption`/`options` built from the generated `List<Entities>Status` enum (`@/services/v1/model`), labels from `i18n.t("options:<entities>.status.*")`. Add the matching keys to `src/i18n/locales/pt-BR/options.json` under a new `<entities>` key (same shape as `entities`/`lessees`), never reuse another entity's key.

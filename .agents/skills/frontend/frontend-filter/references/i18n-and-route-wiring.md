# i18n — the `filter-dialog` key

In the project, the canonical CRUD screen uses the page's `filter-dialog.fields` branch for every filter field, while enum labels remain in `options.json`. The archive option explicitly contains `Ativos`, `Arquivados` and `Todos`; `Todos` is represented by `Strings.EMPTY` and is distinct from clearing the filter back to the active-only default.

`title`/`description`/`clear`/`apply` of the dialog are **not per entity** — `PageFilterHeader`/`PageFilterFooter` (`src/components/ui/page/filter/`) already read all of that from the generic `components:page-filter.*` namespace (`src/i18n/locales/pt-BR/components.json`), componentized once for good. **Never** create `title`/`description`/`clear`/`apply` inside an entity's `filter-dialog` — it's a dead key, nothing in the component reads from there.

The only thing that goes into the entity's `pages` namespace (`src/i18n/locales/pt-BR/pages.json`, under the screen's root key, e.g. `entities-registration`) is `fields`, because that's the only part `<Entities>FilterFields` reads (`t("fields.<field>.label")`/`t("fields.<field>.placeholder")`):

```json
"filter-dialog": {
  "fields": {
    "status": { "label": "Status", "placeholder": "All" },
    "tax-id": { "label": "Tax ID", "placeholder": "000.000.000-00" },
    "email": { "label": "Email", "placeholder": "email@example.com" },
    "phone": { "label": "Phone", "placeholder": "(00) 00000-0000" }
  }
}
```

Adjust the `fields` set to the entity's real filters (remove what doesn't apply, add what's specific). If a field is an enum combobox, its options (`active`/`inactive`, etc.) already come from the matching `options.json`/`options.option.ts` file via `getLabel`/`getOption` — don't duplicate those labels here under `fields.<field>.options`.

The actual copy decisions (which file, key tree, terminology) are out of scope for this skill — it only owns the field set/shape above.

# Route wiring (`index.tsx`)

Changes to the listing route file, always in this order:

1. **`validateSearch`**: a `z.object({ status, <each filter>, page })` (all optional) becomes URL state — always `z.nativeEnum(List<Entity>Status).optional()` for status, `z.string().optional()` for the rest, `z.number().optional()` for `page`. **This schema is never declared inline in the route file** — it's its own file, `_schemas/<entity>-search.schema.ts`, exporting `<entity>SearchSchema`, imported into `index.tsx` and passed straight to `validateSearch`. Same rule as the filter schema itself: always inside that screen's own `_schemas/`, never a loose `const searchSchema = z.object(...)` sitting above the route definition.
2. **Replace a loose pagination `useState`** with `useFilter` (`@/hooks/use-filter`): pass `store` (the `use<Entity>FilterStore`), `schema` (the filter schema), `toFormValues` (`to<Entity>FilterFormValues`), `search` (`Route.useSearch()`), and `onSearchChange` doing `navigate({ search: () => values, replace: true })`. The hook returns `dialogProps`, `filters`, `setPage`, `onApply`, `page`, `form` — `page`/`setPage` replace the old loose `pageIndex`/`setPageIndex` everywhere (fetch, pagination).
3. **Query**: spread `...filters` into `list<Entity>PageQueryOptions`'s params alongside `name`/`limit`/`page: page + 1`.
4. **JSX** (canonical: `<group>/<section>/<entity-groups>/_tabs/groups-tab.tsx`): `PageFilterTrigger` gets `onClick={() => dialogProps.onOpenChange(true)}` inside `PageFilterRoot`, alongside `SearchbarField`. The create action uses `PageFilterAction` and is wrapped with its divider and `<Can>`. After the table card, render `<PageFilterDialog {...form} {...dialogProps} onSubmit={onApply}><EntitiesFilterFields /></PageFilterDialog>`. Search uses `onSearch`/`searchValue` from `useFilter` with `SearchbarField`. In a tab, the tab owns `Route.useSearch()` and `Route.useNavigate()`; the parent never passes filter props or callbacks.

Reference: compare a screen already in the final pattern against one still using the old shape.

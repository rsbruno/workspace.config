# Canonical CRUD screen reference

Describes the shape of the project's reference CRUD screen (listing + create + edit with one parent/child dependent field pair and an archive lifecycle). When creating or reviewing another screen, compare the structure against the project's equivalent live screen first, then apply the rules of the responsible skill. `<Entity>`, `<Parent>`, `<Child>` stand for that screen's own names.

## Routes and composition

- Listing route declares, in this order: `createFileRoute`, `loader` (initial query), `beforeLoad`, `pendingComponent`, `validateSearch`, `errorComponent`, `component`.
- `loader` initializes the listing with default pagination and the active-only filter when that is the domain default.
- Create and edit share one `<Entity>RegistrationFormRoot`, one fields section and one schema. Differences: `isEditing`, record loading, mutation.
- Create and edit use `useHydrated`; the fallback renders before mounting `FormProvider`.
- Successful create invalidates the listing and navigates to the main route. Successful edit invalidates detail and listing and returns to the listing.
- Routes and actions use `require`, `Features`, `Policies`, `Can` and `canAny` explicitly.
- `ErrorBoundary` is set on every route; edit uses `notFound` and its own 404 boundary.

## Form

- Two sections, each a `PageCardRoot` with `PageCardLabel`, separator and `PageCardContent`.
- General section: at most three columns; the name takes three; code and classification fields take one each.
- Relations section: parent and child side by side in two columns.
- Fields use the project's controlled components. Async comboboxes use the generated query options, `initialLabel`, `searchable`, `getOptionLabel`, `getOptionValue`.
- A dependent field stays active when its parent is empty. Child search shows `pending`, not `loading`.
- `FieldHint` explains the business rule and can carry an `action` link to the related create screen.
- The code field calls the GET suggestion endpoint only when the user left it empty.
- Changing the parent clears code and child. Changing the child only replaces the code with the returned suggestion. On edit, returning to the original parent/child keeps the saved code.
- `FormRoot` shares only visual state (`isEditing`, `isPending`) through Context. Submit receives the form's typed payload.

## Schema and contract

- The schema exports `resolver` already built with `zodResolver`; routes import it and never instantiate `zodResolver`.
- One schema for create and edit when the form is identical and all fields are editable.
- `<Entity>Values` is the form input; `<Entity>Payload` is the transformed output for the DTO.
- Generated-DTO limits are mirrored in the schema and the field prop; none invented.
- Empty values use `Strings.EMPTY`/`Strings.UNDEFINED` or another existing constant. No bare `""` or `"-"`.
- Code rejects whitespace in Zod and is trimmed consistently with the payload.

## Listing and filters

- Table shows name, code, parent, child, classifications, status, actions.
- Text cells use `CellTypography`, left aligned.
- Text search is by name or code and goes through `useFilter`, validated URL and persisted store.
- The filter dialog uses only fields the API accepts.
- Fixed options come from modules in `src/constants/options`; parent/child use async comboboxes.
- Clearing filters returns to active-only. Explicit `Todos` removes the archive filter. The schema distinguishes an absent field from `Strings.EMPTY` to preserve this.
- Query options use `placeholderData: keepPreviousData` when applicable; `isFetching` feeds the table, `isPending` feeds the initial fallback.

## Table, status and actions

- First column fluid; others have explicit sizes. Actions column last, `id: "actions"`, size 56, empty header.
- Rows navigate through `TableRowLink` with the update permission; the actions cell stops propagation so it never triggers the row.
- Row actions: `memo`, `displayName`, one `useDisclosure` per dialog, per-action permission, local mutations invalidating the query.
- Archive, restore and delete are structurally separate dialogs. Delete appears only for archived records and the confirmation states the impact on dependents when there is one.
- Badge receives the status enum directly. Labels and variants live in the option module; the badge only resolves `getLabel`/`getVariant` and uses `BadgeIcon`.
- UI conditionals use `If`/`Then`/`Else`; lists use `ForEach`. No ternary or `&&` for UI composition.

## Options

- Option modules encapsulate `labels`, `options`, `getLabel`, `getOption` and, when needed, `getVariant`.
- Tables never `.find()` or compare enums to get a label or variant.
- `getLabel` accepts `null` where the domain allows absence and returns `null` for absent or unknown; the screen decides the fallback (`?? Strings.UNDEFINED`).
- Enum text reused across field, filter and table lives in `options.json`.

## Fallbacks

- One fallback for the listing, one for the form.
- Structurally faithful: `Page*Fallback` shells, `TableFallbackRoot`, `TableFallbackRow`, `TextFieldFallback`, `ComboboxFallback`, `ComboboxAsyncFallback`, `BadgeFallback`, `ButtonFallback`.
- The listing fallback replicates toolbar, table, overflow and pagination, including column count and order.
- `PageCardRoot` may use `min-h-0 flex-1` only inside a genuinely bounded flexible region.
- Routes use `pendingComponent` and early returns for initial load. The table uses `loading={isFetching}` for refetch without unmounting the screen.

## Locale

- Screen and scoped component text lives in `pages.json` under the screen key; the `useTranslation` prefix is the same in list/create/edit.
- Tree: `meta`, `title`, `toolbar`, `table`, `form`, `toast` and `create`/`edit` subtrees.
- Field labels short and domain-specific; placeholders explain the expected value; hints document automations and rules.
- Confirmations use the fixed labels from `frontend-locale`.
- `meta.title` identifies the screen without the product name; `title` is the visible heading.
- The `actions` column gets no header text.
- Reused type/status labels live in `options.json`; table-only status text lives in `pages.json.table.status`.

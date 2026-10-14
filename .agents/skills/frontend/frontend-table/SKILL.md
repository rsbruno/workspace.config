---
name: frontend-table
description: Listing table standard — column order and sizes, TableRowLink, declarative row actions, status badge, toolbar, pagination, empty/loading.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# frontend-table

Standardizes every listing table (`TableRoot`/`TableHeader`/`TableBody`/`TableRowLink`/`useDataTable`) so a new one matches the rest on the first try and an existing one can be audited. Canonical details: `../frontend-page/references/canonical-crud-reference.md`. Numbers and names are this project's; on another project re-derive them from 6-8 real listings first.

## Fixed rules

- Column order: fluid main column (`meta: { fluid: true }`, no `size`) → secondary data → status badge → actions (`id: "actions"`, size 56, empty header). Never insert after status.
- Every non-fluid column declares an explicit `size` (date 130, status 120–160, money 140–170, secondary text 150–280).
- Row navigation only via `TableRowLink` in `row={renderRow}`; no manual `onClick`.
- Row actions are a `RowAction[]` rendered by `RowActionsMenu`; never hand-write `Popover`, `PopoverItem`, `<Can>` or `canSome`. `visible` = row state, `permissions` = access (AND), `disabled` only for that action's pending mutation.
- Column gate: `canAny` = exactly the union of the `actions` permissions; update it in the same edit as the array. Single `manage-*` toggle columns use `can`.
- One `useDisclosure` + one `useMutation` + one dedicated confirmation dialog per action, inside the row-actions component. Custom `onError` toast requires `meta: { ignoreError: true }`. `memo` + `displayName`.
- Lifecycle variants: archive `warning`, restore `info`, delete `danger`; delete never fires from the menu item.
- Grant/revoke relationship toggles: one `Manage*` permission, bare `SwitchPrimitive`, gate at column level. Not `PermissionSwitch`.
- Status badge: pass domain status; label/variant come from the enum's option module. Scoped to the screen until genuinely shared.
- Toolbar search and pagination come from `useFilter` (route search state), create button `Can`-gated. Never `table.getState().pagination` for server pagination.
- `emptyMessage` from i18n, `loading={isFetching}`, query uses `placeholderData: keepPreviousData` (see `frontend-fallback`).
- Text cells use the project's `CellTypography`, left aligned.

## References

| Read when | File |
|---|---|
| Defining columns, sizes, row navigation | [references/columns-and-rows.md](references/columns-and-rows.md) |
| Writing row actions, column permission gate, grant/revoke switches | [references/row-actions.md](references/row-actions.md) |
| Status badge, toolbar, pagination block, empty/loading | [references/badge-toolbar-pagination-states.md](references/badge-toolbar-pagination-states.md) |

## Audit checklist

1. Column order and explicit sizes per type.
2. `TableRowLink` to edit/detail route.
3. Row actions declarative, `canAny` matches, dialogs/mutations per action.
4. Badge scoped correctly, labels from the right namespace.
5. Toolbar/pagination from `useFilter` + server count.
6. Empty message translated, `loading` wired, separate initial fallback.
7. `min-h-0 flex-1` on card/fallback only for a genuinely bounded region.
8. Local low-risk divergences: fix directly. Wider blast radius: ask first.

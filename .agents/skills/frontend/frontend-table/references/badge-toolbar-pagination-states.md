# Status badge, toolbar, pagination, empty/loading

## 5. Status badge

`<Entity>StatusBadge` — scoped to the screen by default (`_components/table/status-badge.tsx` or `<entity>-status-badge.tsx`), promoted to `src/components/badges/` only once genuinely shared across modules (e.g. a status badge is global when two modules need the exact same one — same promotion rule as any other component, see the project's scoped-vs-global decision). Fixed internal shape:

```tsx
function EntityStatusBadge({ status }: { status: EntityStatus }) {
  return (
    <BadgeRoot appearance="soft" variant={entityStatusOptions.getVariant(status)}>
      <BadgeIcon />
      <BadgeLabel>{entityStatusOptions.getLabel(status)}</BadgeLabel>
    </BadgeRoot>
  );
}
```

Pass the domain status directly to the badge. Labels and variants come from the option module when the enum is reused by a field/filter; the badge does not compare values, search arrays or maintain a second config map. `BadgeIcon` chooses its default icon from the resolved badge variant and accepts an explicit `name` only as an override.

Status badges use semantic icons, not dots: success for active, info for archived or unavailable-at-runtime states, and danger for deleted/inactive states when those states are displayed. An archived child row may still render row actions; the action component decides whether restore is available and the backend validates the parent state.

Option modules are the single owner of enum presentation. Export `options`, `getLabel`, `getOption` and, when needed, `getVariant`; `getLabel` may accept `null` and return `null`. The table renders `getLabel(value) ?? Strings.UNDEFINED` and never duplicates the mapping inline.

The actions column keeps `id: "actions"` and its fixed size, but its header is intentionally empty. The shared `TableHeader` suppresses header content for that id, so do not add visible “Ações” text in a table.

## 6. Toolbar (search/filter/create)

Canonical for this project: the tab listing in `<group>/<section>/<entity-groups>`. The toolbar is the `PageFilterRoot` inside the table card:

```tsx
<PageCardRoot>
  <PageFilterRoot>
    <SearchbarField placeholder={t("toolbar.search.placeholder")} onSearch={onSearch} value={searchValue} />
    <PageFilterTrigger onClick={() => dialogProps.onOpenChange(true)} />
    <Can permissions={[Policies.<Module>.<Entities>.Create]}>
      <PageFilterDivider />
      <PageFilterAction<typeof Link> to="/module/route/criar" text={t("toolbar.new-entity")} as={Link} />
    </Can>
  </PageFilterRoot>
  <PageCardContent className="flex flex-col p-0">
    <TableRoot loading={isFetching} row={renderRow} table={table}>
      <TableHeader />
      <TableBody emptyMessage={t("table.empty")} />
    </TableRoot>
    <PaginationRoot ... />
  </PageCardContent>
</PageCardRoot>
```

- `onSearch`/`searchValue` always come from `useFilter` (`searchField` option), so search survives reload/back — never a bare `useState` disconnected from the route's `validateSearch`. `SearchbarField` owns the search interaction.
- The create button is always `Can`-gated with the matching create policy; divider goes inside the same `Can`.
- Never pass a tab's filter object or search callback from the parent route. The tab reads and updates its own route search.

## 7. Pagination (fixed block, server-paginated tables)

Last child of the table's `PageCardRoot`:

```tsx
<PaginationRoot
  onNextPage={() => setPage(Math.min(pageCount - 1, page + 1))}
  onPreviousPage={() => setPage(Math.max(0, page - 1))}
  canNextPage={page < pageCount - 1}
  totalCount={data?.total ?? 0}
  canPreviousPage={page > 0}
  onPageSizeChange={onPageSizeChange}
  onPageChange={setPage}
  pageCount={pageCount}
  pageSize={pageSize}
  pageIndex={page}
>
  <PaginationLabel />
  <div className="flex w-fit min-w-fit items-center gap-3">
    <PaginationRowsPerPage />
    <PaginationActions><PaginationPages /></PaginationActions>
  </div>
</PaginationRoot>
```

`page`/`setPage`/`pageSize`/`onPageSizeChange` always come from `useFilter`; `totalCount = data?.total ?? 0`, `pageCount = Math.max(1, Math.ceil(totalCount / pageSize))`. Never wire `PaginationRoot` off `table.getState().pagination` for a server-paginated listing.

## 8. Empty and loading state

- `TableBody`'s `emptyMessage` is always `t("table.empty")` from the page's own `pages.json` namespace — never a hardcoded string, never the table library's own default copy.
- `TableRoot` always gets `loading={isFetching}` (covers refetch/pagination spinner) — the *initial* load is covered separately by the route's `pendingComponent`/`if (isPending) return <XPageFallback />` before this tree ever mounts. Both exist together, they cover different moments, neither replaces the other.
- Textual cells use the project's `CellTypography` composition and inherit the table's left alignment. Do not use raw text elements or add centered alignment to data cells.
- The query behind the table **must** set `placeholderData: keepPreviousData` (`@tanstack/react-query`) whenever its key changes from pagination/filter/search — otherwise `isPending` flips back to `true` on page 2 or on a filter change, and the `if (isPending) return <Fallback />` guard incorrectly fires again, tearing down the mounted table (and anything alongside it, like the search input) instead of just showing `loading` on `TableRoot`. Full rule and failure story: `frontend-fallback`'s `references/loading-moments.md`, "First fetch only" section — load that skill's reference before touching a table's loading state, this isn't optional polish, it's the difference between a spinner and the whole screen flashing mid-interaction.

# Listing route (`index.tsx`) — layout composition

**Canonical reference: `src/pages/(privadas)/<group>/<section>/<entity-groups>/_tabs/groups-tab.tsx` and `subgroups-tab.tsx`** (+ their fallbacks). Every new listing mirrors this composition. The project uses `PageFilterRoot`/`SearchbarField`/`PageFilterDialog`/`PageFilterAction` inside the table card.

Every piece comes from `@/components/ui/page` — all compound, flattened exports, never an internal file import.

## Composition (fixed)

```tsx
if (isPending) return <EntitiesPageFallback />;

return (
  <PageRoot>
    <PageCardRoot>
      <PageFilterRoot>
        <SearchbarField placeholder={t("toolbar.search.placeholder")} onSearch={onSearch} value={searchValue} />
        <PageFilterTrigger onClick={() => dialogProps.onOpenChange(true)} />
        <Can permissions={[Policies.<Module>.<Entities>.Create]}>
          <PageFilterDivider />
          <PageFilterAction<typeof Link> to="/<group>/<entities>/criar" text={t("toolbar.new-entity")} as={Link} />
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

    <PageFilterDialog {...form} {...dialogProps} onSubmit={onApply}>
      <EntitiesFilterFields />
    </PageFilterDialog>
  </PageRoot>
);
```

## Rules

- A tabbed parent owns `PageHeaderRoot` and `TabsRoot`; a standalone listing owns its own `PageHeaderRoot` when it is not inside tabs.
- Search, filter trigger and "New" button live inside the table card's `PageFilterRoot`. Divider and CTA go together inside the `Can`.
- CTA uses `PageFilterAction<typeof Link>` with the generated route link.
- Table: `TableRoot` (loading/row/table) + `TableHeader` + `TableBody` — columns/row-actions/status badge are `frontend-table`'s scope.
- Pagination is the last child of `PageCardContent` inside the same `PageCardRoot`.
- Filter dialog uses `PageFilterDialog` after the card and receives the form/dialog props; its fields are screen-scoped.
- The table card and fallback may use `min-h-0 flex-1` when the parent establishes a bounded flexible table region, as in the canonical CRUD reference. Do not use `flex-1` merely to fill the viewport.
- `pendingComponent` + `if (isPending) return <EntitiesPageFallback />` both point to the listing fallback.

## Fallback mirror

```tsx
<PageCardRoot>
  <PageFilterRoot>...</PageFilterRoot>
  <PageCardContent className="flex flex-col p-0">
    <TableFallbackRoot />
  </PageCardContent>
</PageCardRoot>
```

Title/text come from the project's i18n hook — the actual copy and key names are out of this skill's scope.

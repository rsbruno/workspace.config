# Column order, sizes, row-click-to-edit

## 1. Column order (fixed, no exception)

```
[main/fluid column]  [secondary data columns...]  [status badge]  [actions]
```

- The **main column** (name/description — whatever most identifies the row) is always first, always `meta: { fluid: true }`, **never** a fixed `size`. It absorbs whatever width the fixed columns don't use.
- **Status badge is always the second-to-last column**, immediately before actions — never buried in the middle of secondary data columns, even if the entity has many fields.
- **Actions is always the last column** (`id: "actions"`), when the entity has any.
- A table with no CRUD actions (a detail-link-only listing) has no actions column — status still stays last in that case.

Never insert a new column between status and actions "because it fits there" — a new field goes among the secondary data columns, before status.

## 2. Fixed column sizes by type (`size={N}` on the `ColumnDef`)

| Column type | Size | Notes |
|---|---|---|
| Main/fluid column | no `size`, use `meta: { fluid: true }` | never combine `fluid` with a `size` |
| Date (`dueDate`, `createdAt`, etc.) | `130` | confirmed identical across every screen with a date column |
| Status badge | `120`–`140` | pick `130` for a new table unless the badge's real label text is visibly wider/narrower than the existing badges in the same module — this range is a soft band, not one universal number, but always stays inside it, never below 120 or above 160 |
| Monetary value (currency-masked) | `140`–`170` | scales with how large the value can realistically get in that domain (a sale price legitimately needs more room than a transaction amount) — `140` is the safe default for a generic currency column, widen only with a concrete reason |
| Actions | `56` | the dominant size (7/8 screens surveyed) — use `56` for a new table. `categorias` uses `100` today; that's a known drift from this pattern, not a second valid option — if touching that screen's table, correct it to `56` rather than copying it elsewhere |
| Secondary text (email, phone, city, type/category label) | `150`–`280`, driven by real content width | no single fixed number — a city name needs less room than an email address; pick a size that avoids truncation for the typical value, verify against real data rather than guessing |

Never leave a non-fluid column without an explicit `size` — every fixed column always declares one.

## 3. Row-click-to-edit (`TableRowLink`)

Every listing whose rows have an edit destination renders `TableRowLink` through the `row` callback, pointing at that entity's edit route:

```tsx
function renderRow({ row: entity, className, cells }: TableRowRenderArgs<EntityResultDto>) {
  return (
    <TableRowLink
      to="/module/route/editar/$id"
      can={[Policies.Module.Entity.Update]}
      params={{ id: entity.id }}
      className={className}
      cells={cells}
    />
  );
}

<TableRoot row={renderRow} loading={isFetching} table={table}>
```

- `TableRowLink` is the sanctioned row navigation primitive. It receives the route, params, permission, class name, and already-built cells.
- A listing whose primary action is viewing a detail page still uses `TableRowLink`, pointed at the detail route instead of the edit route.
- `TableRoot` receives `row={renderRow}`; never add a manual per-row click handler or put navigation inside a cell.

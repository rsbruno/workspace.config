# Row actions, column gate, grant/revoke toggle

## 4. Row-actions component: declarative actions + `RowActionsMenu`

File: `_components/table/<entity>-row-actions.tsx`, export `<Entity>RowActions`. The component declares its actions as data and hands them to the shared `RowActionsMenu` (`@/components/ui/table`). It never writes `Popover`, `PopoverItem`, `<Can>`, `canSome` or the "…" trigger by hand.

```tsx
import { type RowAction, RowActionsMenu } from "@/components/ui/table";

interface EntityRowActionsProps { archived: boolean; entityId: string }

const EntityRowActions = memo(({ archived, entityId }: EntityRowActionsProps) => {
  const { t } = useTranslation("pages", { keyPrefix: "entities" });
  const queryClient = useQueryClient();

  const { setOpen: setArchiveOpen, onOpen: openArchive, open: archiveOpen } = useDisclosure();
  const { setOpen: setRestoreOpen, onOpen: openRestore, open: restoreOpen } = useDisclosure();
  const { setOpen: setDeleteOpen, onOpen: openDelete, open: deleteOpen } = useDisclosure();

  const archive = useMutation({ /* toast + invalidate + close dialog */ });
  const restore = useMutation({ /* ... */ });
  const remove = useMutation({ /* ... */ });

  const actions: RowAction[] = [
    {
      id: "archive",
      visible: !archived,
      permissions: [Policies.X.Entities.Archive],
      icon: ArchiveBoxIcon,
      variant: "warning",
      label: t("actions.archive"),
      testId: `entity-archive-action-${entityId}`,
      onSelect: openArchive
    },
    { id: "restore", visible: archived, permissions: [Policies.X.Entities.Restore], icon: ArrowCounterClockwiseIcon, variant: "info", disabled: restore.isPending, label: t("actions.restore"), testId: `entity-restore-action-${entityId}`, onSelect: openRestore },
    { id: "delete", visible: archived, permissions: [Policies.X.Entities.Delete], icon: TrashIcon, variant: "danger", label: t("actions.delete"), testId: `entity-delete-action-${entityId}`, onSelect: openDelete }
  ];

  return (
    <>
      <RowActionsMenu
        triggerTestId={`entity-row-actions-trigger-${entityId}`}
        testId={`entity-row-actions-${entityId}`}
        actions={actions}
      />

      <ArchiveEntityConfirmation onConfirm={() => archive.mutate()} onOpenChange={setArchiveOpen} pending={archive.isPending} open={archiveOpen} />
      <RestoreEntityConfirmation ... />
      <DeleteEntityConfirmation ... />
    </>
  );
});
EntityRowActions.displayName = "EntityRowActions";
```

What `RowActionsMenu` owns (never re-implemented in a screen): the `<div onClick>` that calls `preventDefault` + `stopPropagation` so clicking the menu or a dialog never triggers the `TableRowLink` navigation, the `Popover`/`PopoverTrigger`/`PopoverContent`/`PopoverItem` structure, the fixed trigger button (`DotsThreeIcon`, `appearance="outlined"`, `variant="surface"`, `size="sm"`), closing the menu before `onSelect`, and the visibility rule: an action is shown only if `visible` is true **and** the user has every permission in its `permissions` (AND). **If no action is available for that row, the whole component renders `null`** — no wrapper, no trigger, no empty popover. This is why an active row for a user with only `Restore` shows nothing.

Rules for the `actions` array:

- **`visible` carries the row state** (`!archived`, `archived`, `status === X`, `!finalizedAt`, `!blocked`). Never branch with `If/Then/Else` in JSX or build a second list per state.
- **`permissions` is the only place an action's permission is written.** An action whose contract needs several permissions at once lists all of them (AND), e.g. copy = `[Copy, Find, Update]`. Never wrap an item in `<Can>` and never call `canSome` in a row-actions file.
- **One entry per action**, with a unique `id`; `testId` follows the `<entity>-<action>-action-<id>` convention, wrapper `<entity>-row-actions-<id>`, trigger `<entity>-row-actions-trigger-<id>`.
- **Lifecycle variants**: archive `warning`, restore `info`, delete `danger`. Every one of them opens its dedicated confirmation dialog through `onSelect`; delete never fires the mutation from the menu item.
- **`disabled`** is only for a pending mutation of that very action; permission and state never use `disabled`, they use `permissions`/`visible`.
- **Dialogs and mutations stay in the row-actions component**: one `useDisclosure` per dialog (never shared across two), one `useMutation` per action directly in the component (never a `use-x-mutation.ts` wrapper), with `toast.dispatch` + `queryClient.invalidateQueries` in `onSuccess`. A custom `onError` that calls `toast.dispatch` always comes with `meta: { ignoreError: true }` on the same `useMutation`, otherwise the global `mutationCache` toast shows the error twice.
- **Structurally split dialogs**: archive/restore/delete/settle/cancel each get their own dialog component, never one dialog switching behavior via a `mode` prop (visible flicker/remount). They stay mounted but closed, siblings of the menu.
- `memo` + manual `displayName` on every row-actions component.
- A row that must not offer actions for a reason that isn't a permission or a simple state (e.g. subgroup whose parent group is archived) expresses it in `visible` of every action, or returns `null` before the menu — never by disabling.

**Column gate.** The actions column is also gated at `ColumnDef` level so a user with none of the permissions does not even get the column. Use `canAny` (OR) listing **every permission that appears in that component's `actions` array** — no more, no less — and `can` (AND) only when the component has a single always-present action. The column gate is the coarse filter; `RowActionsMenu` is the exact per-row filter. When an action is added to or removed from the `actions` array, update the column's `canAny` in the listing in the same edit (a stale list either hides the column from someone who has a valid action or shows an empty column; example: a `canAny` containing `Delete` for a component that never offered `Delete`).

## 4.1 Grant/revoke toggle switch (single `manage-*` permission)

When a table cell toggles membership/grant state (a group's policy, a user's group membership, any "this row is linked to that record" boolean), **grant and revoke are one permission, not two** — see `backend-rule`'s "One permission per relationship" section for the backend half of this rule (`ManageX` policy, both directions guarded by the same `@Can`). There is no dual-permission case left to design for on a relationship toggle; don't reintroduce `GrantX`/`RevokeX` pairs.

Gate the whole column at `ColumnDef` level with plain `can` (AND semantics is correct here — it's a single permission, not a set):

```tsx
{
  cell: ({ row }) => <EntitySwitch id={row.original.id} relatedId={relatedId} />,
  header: t("table.columns.actions"),
  can: [Policies.Domain.Module.ManageX],
  id: "actions",
  size: 90
}
```

The switch cell itself renders a bare `SwitchPrimitive` (`@/components/ui/fields/switch`) with no permission awareness at all — it doesn't know or care whether the user can toggle it, because the column already didn't render for anyone who can't:

```tsx
<SwitchPrimitive onCheckedChange={handleCheckedChange} disabled={isPending} checked={checked} />
```

- Do **not** use the generic `PermissionSwitch` (`src/components/fields/permission-switch.tsx`) for this case — that component's dual `onPermissions`/`offPermissions` + tooltip machinery exists for genuinely asymmetric switches (see its own doc comment/usages, e.g. anywhere grant and revoke really are two different policies by design); a plain grant/revoke relationship toggle is not that anymore.
- The mutation (grant/revoke call, optimistic update, "last item" confirmation dialog) stays in the screen's own `<Entity>Switch` wrapper component, same as before — only the permission-gating moved from the switch component to the column definition.
- Real reference (already migrated): the project's screens that toggle a relationship (policy-in-group, user-in-group, user-in-site), each gated by its single `Manage*` policy.

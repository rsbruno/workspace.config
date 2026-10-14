# Fixed order, Manage pattern, finance lifecycle

## Fixed order, both in `policy.enum.ts` and in `data.json`

Within a module's block, the lifecycle actions come first in this order: `Create, Update, Archive, Delete, Restore, Find, FindAll`. Custom actions follow, in alphabetical order. When adding a permission to an existing module, insert it at its position; never append it at the end. Archive is a capability distinct from delete.

```ts
Groups: {
  Create: 'access:groups:create',
  Update: 'access:groups:update',
  Archive: 'access:groups:archive',
  Delete: 'access:groups:delete',
  Restore: 'access:groups:restore',
  Find: 'access:groups:find',
  FindAll: 'access:groups:findall',
  ManagePolicy: 'access:groups:manage-policy',
  ManageUser: 'access:groups:manage-user',
},
```

Why: with many modules each carrying 5-9 permissions, a fixed order lets anyone scan the catalog and spot a missing or duplicated action at a glance.

## One permission per relationship — never a `Grant`/`Revoke` pair

A grant/revoke (or link/unlink, attach/detach) pair on the same relationship is **one** policy. The endpoints, commands and handlers stay separate (`PATCH :id/users/:userId/grant` and `.../revoke`, `GrantUserCommand`/`RevokeUserCommand`); only the permission collapses. The key is `Manage{RelatedEntity}`, never `Grant{X}`/`Revoke{X}`.

Examples: `access:groups:manage-policy`, `access:groups:manage-user`, `access:users:manage-site`, `core:documents:manage-line`.

```json
{
  "id": "polg1uexfmks5ctwrc0e7s1yoya",
  "name": "Gerenciar usuários do grupo",
  "module": "groups",
  "feature": "access:groups",
  "code": "access:groups:manage-user",
  "description": "Permite associar e desassociar usuários de um grupo."
}
```

```ts
@Can(Policies.Access.Groups.ManageUser)
@Patch(':id/users/:userId/grant')
async grantUser(...) { return this.commandBus.execute(new GrantUserCommand(...)); }

@Can(Policies.Access.Groups.ManageUser)
@Patch(':id/users/:userId/revoke')
async revokeUser(...) { return this.commandBus.execute(new RevokeUserCommand(...)); }
```

Why: granting and revoking the same relationship is one capability from an admin's point of view. Splitting doubles the catalog without a real reason to hold one but not the other.

Frontend mirror + table column gating for this pattern: `frontend-table` §4.1.

## Lifecycle actions

A module following the standard lifecycle has separate `create`, `update`, `archive`, `delete`, `restore`, `find` and `findall` actions. Archive is not folded into delete. `next-code` uses the read capability unless the feature catalog defines a separate one.

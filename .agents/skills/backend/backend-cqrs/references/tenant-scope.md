# Request identity, organization scope, session, sub-scope

## 2.2 Request identity — organization scope via `@CurrentUser()` (fixed project rule)

`authenticatorId` (the auth provider sub) **only exists** inside the authentication layer: `src/modules/v1/<auth-domain>/auth/`, the user-creation flow of `src/modules/v1/<auth-domain>/users/` (it creates the auth provider user), the session layer `src/infrastructure/session/` and `src/http/guards/jwt-auth.guard.ts`. It's forbidden anywhere else.

Authenticated controllers use the `@CurrentUser()` decorator to access the current organization identity already resolved by `JwtAuthGuard`:

```ts
import { CurrentUser } from '@/http/decorators/current-user.decorator';
import type { CurrentUserContext } from '@/http/decorators/current-user.decorator';

@Get()
findAll(@CurrentUser() user: CurrentUserContext) {
  return this.queryBus.execute(new FindAll{Entities}Query(user.organizationId));
}
```

**Import must be split:** `CurrentUser` (decorator, value) and `CurrentUserContext` (interface, type) must be imported on separate lines — a normal `import { CurrentUser }` and `import type { CurrentUserContext }` with `type`. This is required by TypeScript with `isolatedModules: true` + `emitDecoratorMetadata: true` (TS1272 error if mixed into a single import).

**Never** use `@Req()`, `req.user.authenticatorId`, or `UsersRepository.findByAuthenticatorId()` in a handler/controller outside the auth module. The guard has already resolved the internal identity context before reaching the controller — don't repeat that work. Organization-scoped modules pass `organizationId`, as in the reference modules; user-scoped modules pass `userId`.

Commands and queries receive `organizationId: string` for organization-scoped data and `userId: string` for user-scoped data. They never receive or query by `authenticatorId`.

### 2.2.0 The session is revalidated on every request (implemented, keep it)

`SessionService.resolveSession` (`src/modules/v1/<auth-domain>/auth/infrastructure/session/session.service.ts`) revalidates the membership on **every** authenticated request, in parallel:
- the user is still active in the session organization (`FindUserInOrganizationQuery`);
- the organization is still active, not archived or deleted (`FindActiveOrganizationQuery`);
- the user still has at least one granted group, and the current `groupIds` replace the stored ones.

Any failure ends the session: the refresh token is revoked and the session is deleted, so the request gets 401. Login applies the same checks. Never cache `organizationId`/`groupIds` decisions elsewhere, and never bypass `JwtAuthGuard` for organization data. Pinned by `src/__tests__/unit/modules/v1/<auth-domain>/auth/infrastructure/session/session.service.spec.ts`.

### 2.2.1 Every action is limited to the user's organization and permissions (fixed project rule, no silent exception)

The authenticated user can only see and act on data of the organization they belong to (the session organization), and only through endpoints they hold the permission for.

- The organization comes **only** from `@CurrentUser().organizationId`. It is never read from the body, query string or path, and payload/query DTOs never declare an `organizationId` field (the whitelist rejects it).
- Every command and query of an organization-owned entity carries `organizationId` and passes it to the repository, which filters by it in the `WHERE` of every read **and** write (`backend-sql` 2). Validating the row through `Find{Entity}Query` first does not replace the condition in the write.
- Every relation validated through `QueryBus` is looked up with the same `organizationId`. A related id from another organization is treated as nonexistent.
- A row of another organization always answers exactly like a nonexistent row (404 with the module's `NOT_FOUND` code) — never 403, never a hint that it exists.
- Every endpoint is guarded by `@Feature(...)` and `@Can(...)` (section 3.2.1, `backend-rule`).
- The repository is the mandatory final tenant boundary: every organization-owned read and write receives the `organizationId` explicitly and applies it in SQL. Handler lookup, service validation or a previous `Find` never replaces the repository condition. Do not implement this with hidden session state, an implicit ORM filter or a generic abstraction that can omit the condition; use the ordinary explicit repository parameter and `WHERE` condition.
- **Exceptions** — global catalogs with no owner organization (e.g. `GET /v1/catalog/items/base`), endpoints without `@Can` by documented decision, user-scoped data — must be analyzed, documented in the module implementation note, pinned by a test, and **reported to the developer** whenever the module is created or refactored. Never leave an unscoped action undocumented.
- Tests prove it in every layer (`backend-test`): repository SQL contains the organization condition, handlers forward the command's organization, E2E with two organizations returns 404/empty for the foreign one, and the feature + permission matrix runs for every endpoint.

### 2.2.2 Data scope by site (fixed business rule — `project docs/Requisitos/Permissões/requisitos/permissoes.md`)

Inside the organization, data is also limited by the **sites granted to the user**:
- the grants are the user's active rows in `users_sites`, read through `ListUserSitesQuery`;
- **no site granted → the user sees and writes in every site of the organization**;
- **at least one site granted → only those sites exist for the user**, and every other site is invisible.

How every module whose rows belong to a site applies it. That covers a `siteId` column, or a site reached through a parent or an allocation, as in child records reached through a parent, many-to-many allocations and settlements:
- Queries and commands carry `userId` (from `@CurrentUser()`) next to `organizationId`. The handler resolves the site scope once, through `QueryBus`, and passes `siteIds: string[] | undefined` to the repository (`undefined` = no restriction).
- **Listings** filter in SQL (`inArray(table.siteId, siteIds)`, or an `exists` on the allocation table). Never filter in JavaScript after the query.
- **Lookups and writes** of a row outside the scope answer exactly like a nonexistent row (404, the module's `NOT_FOUND`).
- **Payloads that reference a site outside the scope** are rejected as an invalid relation. The user can only register inside granted sites.
- **Aggregations and totals** (reports, balances, exports) apply the same scope.
- **Tests (`backend-test`):** an E2E with three users (no grant, site A only, sites A + B) asserts what each one sees and can write.

`ListUserSitesQuery` currently filters only by `userId`. Scoping it by organization and ignoring archived/deleted sites is part of the users-module refactor. A module that owns site-bound data and does not apply the scope yet is a finding for `backend-refactor`, reported to the developer.

# Findings: organization scope, permissions, validations

## 2. Inventory first — tests and failures (before any edit)

Write two lists and show them to the user before fixing:

- **Scenario inventory**: the `backend-test` section 1 table, filled in for every endpoint of the module.
- **Findings**: each problem with `file:line`, the concrete failure scenario, and the fix. Hunt every class below. Look for the failures that pass unnoticed (wrong totals, silent no-op updates, untranslated messages, leaked fields, races), not only the obvious ones.

### 2.1 Organization scope and membership (highest priority)

**Every action is filtered and limited to the organization of the logged user.** The organization always comes from `@CurrentUser().organizationId`, never from the payload, query string or path.

- Every repository read **and** write has `eq(table.organizationId, organizationId)` in its `WHERE`. `findById` is by `id` + `organizationId`. `update`/`archive`/`delete`/`restore` repeat the organization in the `UPDATE ... WHERE`, even after a successful `Find`.
- The repository is the final isolation boundary, not just the handler. The `organizationId` must be explicit in every organization-owned repository method and visibly applied to every affected table, relation, join, subquery and conflict update. Do not solve a missing condition with hidden request context, a generic base repository or an optional scope object that allows the query to run without a tenant; a missing repository condition is a highest-priority data-leak finding.
- Every relation validated through `QueryBus` passes the same `organizationId`. A relation id from another organization behaves as nonexistent (404/400, never a write).
- Listings never accept an organization filter. The DTO whitelist rejects a client-sent `organizationId`.
- Child tables without an `organizationId` column are reached only through a parent that is scoped by organization (join or `Find` of the parent first).
- **Exceptions** (global catalogs such as base items, system parameters, anything not owned by an organization) must be analyzed and **reported to the developer** in the final report: what is global, why, and which endpoint exposes it. Never silently leave an endpoint unscoped.
- **Site scope** (`backend-cqrs` 2.2.2): if the module's rows belong to a site (directly or through a parent or allocation), every listing, lookup, write, total and export is limited to the user's granted sites (none granted = all sites). A missing site scope is a finding of the highest priority, together with organization scope.
- **Session:** organization membership is revalidated per request by `SessionService` (`backend-cqrs` 2.2.0). The module never caches user, organization or group decisions on its own.

### 2.2 Permissions

- Every endpoint has `@Feature(...)` and `@Can(...)` (see `backend-rule`), every write endpoint has `@Audit()`, and every id path param uses `ParseIdPipe` (`backend-cqrs` controller rules). An endpoint without `@Can` is an exception: it must already be documented in the module implementation note, it is reported, and it is pinned by a test.
- The permission code is the same operation as the endpoint. Policies exist in `drizzle/seeds/policies/data.json` with the code from `policy.enum.ts`. The feature is linked to its module in `modules-features`.

### 2.3 Missing validations (types, quantities, limits per field)

For every field of every payload **and** query DTO:
- **Type and presence:** correct type validator, `required` vs `@IsOptional` matching the column nullability, and `trim` on strings.
- **Strings:** `@MaxLength` equal to the column length; ids max 128.
- **Numbers:** `@IsInt` for integer-scaled values; `@Min`/`@Max` equal to the column range.
- **Other types:** `@IsEnum` for business enums; `@ValidateNested` + `@Type` for nested objects; `@ArrayMaxSize`/`@ArrayNotEmpty`/`@ArrayUnique` for arrays.
- **Pagination:** `pageSize` capped by `Pagination.MaxPageSize`, and `search` has a `@MaxLength`.
- **Dates:** `date` columns for calendar dates travel as `'YYYY-MM-DD'` strings, `timestamp` for instants, and ranges are validated (`backend-schema` 2.1.6).
- **Path params:** every id goes through `ParseIdPipe`.
- **Messages:** every decorator has a `message` key that exists in `schemas.json` (`backend-locale`).
- **Whitelist:** fields the client must never send (`organizationId`, `archivedAt`, `deletedAt`, `id`, `createdAt`) are not in the DTO. The whitelist must reject them.
- **Handlers:** the handler does not re-validate what the DTO already guarantees. It validates what only the domain knows: relations, lifecycle state and business rules.

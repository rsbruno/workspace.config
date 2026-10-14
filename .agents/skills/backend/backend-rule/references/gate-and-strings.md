# Billing gate and where permission strings live

## Gate first: does this endpoint's feature exist in the billing catalog?

Before writing a policy row, check `drizzle/seeds/features/data.json` (backed by `Features` in `src/domain/enums/features.enum.ts`) and `drizzle/seeds/modules/data.json` (plan modules: `access`, `registrations`, ...). A permission is only valid if its `feature` resolves to a real `Features.{Domain}.{Module}` entry that is seeded in `features/data.json` and linked to a plan module in `drizzle/seeds/modules-features/data.json` (`moduleId` + `featureId`). A feature created by the API is always linked to its module in the same change (`AGENTS.md`).

- **Feature exists** → create the policy and guard the endpoint with `@Feature` + `@Can`.
- **Feature does not exist** (internal/system-only surface, not sold as a plan feature) → **no policy row and no `@Can`**. Inventing a policy for a non-billable feature implies an entitlement that doesn't exist.

Every endpoint without `@Can` is an **exception**. That covers both cases: an endpoint whose feature doesn't exist, and an endpoint with `@Feature` but no `@Can`, such as the global catalog `GET /v1/catalog/items/base`. Every exception must be:
- documented in the module implementation note;
- pinned by a test (controller metadata + E2E);
- reported to the developer.

If unsure whether a feature should exist yet (new module being built out), ask. Never silently skip the guard on a real billed feature just because the seed hasn't caught up.

## Where the strings live

- Code constants: `src/domain/enums/policy.enum.ts` (`Policies.{Domain}.{Module}.{Action}`) and `src/domain/enums/features.enum.ts` (`Features.{Domain}.{Module}`). Code (`@Can(...)`, `@Feature(...)`, tests) always references the constant, never a literal.
- Seed rows: `drizzle/seeds/policies/data.json`, imported by `drizzle/seeds/policies/index.ts`. The table is `policies` (`src/modules/v1/<domain>/policies/infrastructure/database/drizzle/policies.schema.ts`). The JSON is the only place allowed to repeat the literal `code`/`feature` strings. Their equality with the enums is enforced by the catalog test (see "Catalog consistency is tested" below).

Adding a new permission always means:
1. Add the key to `policy.enum.ts`, in the fixed order (see below).
2. Use the constant in `@Can(...)` and in the tests.
3. Add the row to `drizzle/seeds/policies/data.json` with the same `code`.
4. Run `pnpm db:seed` (permanent bypass).

```ts
export const Policies = {
  Access: {
    Users: {
      Create: 'access:users:create',
      Update: 'access:users:update',
      Archive: 'access:users:archive',
      Delete: 'access:users:delete',
      Restore: 'access:users:restore',
      Find: 'access:users:find',
      FindAll: 'access:users:findall',
    },
  },
};
```

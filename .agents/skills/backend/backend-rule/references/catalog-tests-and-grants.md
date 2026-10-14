# Catalog consistency, permission tests, reaching groups

## Catalog consistency is tested (fixed project rule)

`src/__tests__/unit/seeds/catalog-seeds.spec.ts` keeps the catalog consistent. It checks that:
- every `Policies` value is seeded, and every seeded code exists in `policy.enum.ts`;
- every policy points to a seeded feature;
- every `Features` value is seeded, and every feature is linked to an existing module;
- codes and ids are unique;
- descriptions are at most 100 characters and start with `Permite `.

Gaps that already existed are listed explicitly in `knownGaps`, which works as a ratchet:
- a new gap fails the test;
- fixing a known gap also fails the test until its entry is removed.

Never add an entry to `knownGaps` to make a new change pass. The list only shrinks.

## Permissions are tested together with the feature, and individually (fixed project rule)

Every endpoint's guards are pinned by tests (`backend-test`):
- **Controller unit test:** a metadata matrix asserts `@Feature` and `@Can` (or the documented absence of `@Can`) for every method.
- **Module E2E, per endpoint:**
  - only the feature missing → `SUBSCRIPTION_REQUIRED`;
  - only the permission missing → `PERMISSION_DENIED`, listing exactly that policy;
  - both missing → `SUBSCRIPTION_REQUIRED`;
  - only its own permission granted → passes the guards;
  - endpoints without `@Can` → succeed with no policy, and policy resolution is never called.

An endpoint added without these tests is incomplete.

## A new or renamed permission only works after it reaches the groups (fixed project rule)

The API seed (`pnpm db:seed`) only writes the policy catalog. It never grants anything to a group, so a policy added to `data.json` is invisible to every user until a group receives it, and a renamed code (for example `disable` becoming `archive`) silently drops the old grants. Missing grants hide the row actions column or its actions in the web with no error anywhere.

Whenever `policy.enum.ts` / `data.json` gain, lose or rename a policy, finish the task with the group step, in this order:

1. API: `pnpm db:seed` (catalog).
2. Run the project's group-grant tooling: stage the desired grants, review the plan (it must list only the new grants and the removals of retired policies), then apply. Admin groups receive every active policy; restricted groups list their codes explicitly, and every listed code must exist in the catalog.
3. Verify in the database that no active policy is missing from the admin group of any organization.

Never add the grant with a hand-written SQL migration for a group the grant tooling already manages. A new environment gets its grants from that tooling, not from the API seed.

## Where this plugs into the rest

- Table, soft delete and seed mechanics: `backend-schema` (3.6).
- Repository access (`PoliciesRepository.findAll`/`findByCode`/`findByIds`): `backend-sql`.
- When groups get associated to policies is the `access/groups` domain; this skill only defines how a single permission row is written.

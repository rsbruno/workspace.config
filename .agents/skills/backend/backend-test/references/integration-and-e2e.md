# Integration and E2E tests

## 5. Integration tests (real Postgres, dev database)

- `describeWithDatabase`. `beforeAll`: `connectTestDatabase` + real repositories over `createTestDatabase(client)`. `beforeEach`: `begin` + fixtures. `afterEach`: `rollback`. `afterAll`: `client.end()`.
- Fixtures always include **two organizations**, plus archived and deleted variants of every relation the module validates.
- Expected database errors run inside `withSavepoint` (otherwise the transaction aborts) and assert the PostgreSQL code (`23505`, `23503`, `22P02`) and the constraint name.
- Mandatory cases:
  - full lifecycle through the repositories;
  - every read/write from the other organization returns `null`/`false`;
  - listing filters and pagination against real rows, including `total`;
  - uniqueness scoped by organization, and recreatable after delete;
  - column types (`information_schema.columns`) for integer-scaled values;
  - rows with a deleted relation are hidden.

## 6. E2E tests (real HTTP, guards, CQRS, handlers, repositories, i18n, Postgres)

`createE2eApp({ client, defaultSession, features, policies, imports: [<Module>Module], routePrefix, sessions })` boots the real module with:
- the real `JwtAuthGuard`, `FeatureGuard` and `CanGuard`;
- the real `CustomValidationPipe` and the global filters in `main.ts` order;
- the real i18n (`pt-BR`);
- the database connection bound to the test transaction (`DATABASE_CONNECTION`, `DATABASE_ROOT_CONNECTION` and `DatabaseTransactionContextService` are provided globally).

Only the session store and the feature/policy resolution are replaced. They are controlled per test through `e2e.access.features` / `e2e.access.policies`, and reset with `e2e.resetAccess()` in `beforeEach`. Never mock `CommandBus`/`QueryBus` in an E2E.

Declare the endpoint table once and drive the guard tests from it:

```ts
const endpoints: [string, string, string, string | undefined][] = [
  ['GET', '', 'listItems', Policies.Params.Items.FindAll],
  ['GET', '/base', 'listBaseItems', undefined],
  // ...one row per controller method
];
```

Fixed `describe` order: `authentication` → `feature and permission` → `organization isolation` → `lifecycle` → `validation` → domain-specific blocks → `openapi contract` → `listing`.

**Feature and permission are tested together and individually, for every endpoint:**
1. Only the feature missing → `403 SUBSCRIPTION_REQUIRED`, `features` lists the module feature, and the feature was resolved for the **session** organization.
2. Only the permission missing → `403 PERMISSION_DENIED`, `policies` equals exactly the endpoint policy, and it was resolved for the session organization.
3. Both missing → `403 SUBSCRIPTION_REQUIRED` (the feature guard runs first).
4. Only the endpoint's own permission granted → passes the guards (status is neither 401 nor 403).
5. Endpoints without `@Can` (documented exception) → succeed with no policies, and the policy resolution is never called.

Every error assertion is followed by `expectTranslatedErrors(body)`. Domain errors also assert `errorCodes(body)`, and validation errors assert `errorPaths(body)`. At least one test asserts the exact Portuguese text of a module message (for example a unique-violation message). Expected database errors through HTTP run inside `withSavepoint`.

The `openapi contract` block builds `SwaggerModule.createDocument(e2e.app, new DocumentBuilder().build())` and asserts the response DTO and payload DTO schemas. This is the Orval contract.

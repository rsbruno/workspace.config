# File layout, naming and shared helpers

## 2. File layout and naming (fixed)

```
src/__tests__/
├── helpers/                                   # shared, never duplicated inside a spec
├── unit/modules/v1/<domain>/<module>/
│   ├── <module>.controller.spec.ts
│   ├── application/<module>-dtos.spec.ts
│   ├── application/commands/<module>-commands.handlers.spec.ts
│   ├── application/queries/<module>-queries.handlers.spec.ts
│   └── infrastructure/database/drizzle/<module>-{query,command}.repository.spec.ts
├── integration/modules/v1/<domain>/<module>/<module>-database.spec.ts
├── e2e/modules/v1/<domain>/<module>/<module>.e2e-spec.ts
└── jest.<domain>-<module>.config.json
```

- `describe` = class or area name (`'ItemsRepository'`, `'params items command handlers'`, `'Params items HTTP E2E'`). `it` = behavior in English, present tense.
- Fixture ids are module-prefixed and readable: `org<module>integration`, `org<module>e2ea`, `unt<module>e2ebase`.
- Data-driven cases use `it.each` tables, never copy-pasted `it` blocks.
- No comments (global rule). No `any`: mocks are passed as `as never`, a fake db as `as unknown as NodePgDatabase<...>` (already wrapped by the helpers).

## 3. Shared helpers (`src/__tests__/helpers`) — always use, never re-implement

| Helper | Use |
|---|---|
| `test-database.helper.ts` | `describeWithDatabase`, `connectTestDatabase()`, `createTestDatabase(client)`, `withSavepoint(client, name, action)` |
| `dev-database-url.helper.ts` | `DATABASE_URL` from `.env.dev`. Integration and E2E always run against the **dev database**, inside a transaction rolled back after each test |
| `drizzle-builder.helper.ts` | `createSelectDatabase(...results)`, `createWriteDatabase()`, `compileCondition(sql)` to compile a captured `where` into `{ sql, params }` |
| `business-error.helper.ts` | `expectBusinessError(promise, code, status?)` |
| `translation.helper.ts` | `validationMessagesOf(dto)`, `untranslatedValidationMessagesOf(dto)`, `untranslatedExceptionCodes(codes)` |
| `e2e-app.helper.ts` | `createE2eApp(...)`, `sessionFor(org, user)`, `json(method, body)`, `errorCodes`, `errorPaths`, `expectTranslatedErrors`, `E2eErrorBody` |

If a spec needs something generic that is not in the helpers, add it to the helpers folder (generic, typed, no module knowledge) and use it from there.

Mandatory mocks at the top of the spec, before any import:

- Any spec that loads a command repository (handlers, controller, module, E2E): `jest.mock('@/http/helpers/createCUID.helper', ...)`, because `@paralleldrive/cuid2` is ESM. Item specs use a fixed id; integration/E2E use a counter (`${prefix}e2e${(sequence += 1)}`).
- E2E: `jest.mock('@/modules/v1/<auth-domain>/auth/infrastructure/session/session.service', () => ({ SessionService: class SessionService {} }))`.

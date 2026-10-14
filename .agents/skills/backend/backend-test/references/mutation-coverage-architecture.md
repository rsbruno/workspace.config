# Mutation checks, coverage config, architecture suite, done criteria

## 7. Mutation checks before declaring done (mandatory)

Temporarily break the code, run the module suite, confirm it fails, restore (copy the file to the scratchpad first and copy it back):
1. Remove the `organizationId` condition from one query or write repository method → unit, integration and E2E must fail.
2. Remove one module translation key from `exceptions.json` → E2E must fail.
3. Remove `@Can` from one endpoint → controller unit test and E2E must fail.

Report the result of each mutation. If a mutation does not fail the suite, the suite is incomplete. Fix the tests before finishing.

## 8. Coverage config and running

`src/__tests__/jest.<domain>-<module>.config.json` copies `jest.catalog-items.config.json`:
- `testMatch`: unit + integration + e2e of the module.
- `collectCoverageFrom`: `application/**`, `http/**`, `*.repository.ts`, controller, module.
- `maxWorkers: 1`.
- Thresholds: `statements`, `lines` and `functions` at 100, `branches` at 80. The remaining branches are decorator metadata emitted by TypeScript.

Add the `package.json` script `test:<module>:cov` → `jest --config src/__tests__/jest.<domain>-<module>.config.json --runInBand`.

Running the module suite is part of a test/refactor task. `tsc`, lint and the global suite still follow `AGENTS.md`. The `coverage/` folder may be root-owned locally; pass `--coverageDirectory` to the scratchpad when needed. The `pg` warning about concurrent `client.query()` comes from the single-connection transaction and is expected.

## 9. Global architecture suite (whole API, `pnpm test:architecture`)

These tests pin the rules for **every** module at once, including modules not refactored yet:

| Spec | Pins |
|---|---|
| `src/__tests__/unit/architecture/controllers.architecture.spec.ts` | reviewed public endpoints; `@Feature` and `@Can` on every authenticated endpoint; `@Audit` on every authenticated write; only declared features and policies; `ParseIdPipe` on every id param; globally unique method names (`operationId`); no static route shadowed by an earlier `:param` route |
| `src/__tests__/unit/architecture/source.architecture.spec.ts` | unique exported class names; translated validation messages in every DTO; every business `CodeExceptions` translated; no infrastructure import across modules outside `.schema.ts` |
| `src/__tests__/unit/seeds/catalog-seeds.spec.ts` | `Policies`/`Features` enums equal to the seeds, every feature linked to a module, description rules (`backend-rule`) |
| `src/__tests__/integration/architecture/database-schema.spec.ts` | `.schema.ts` identical to the dev database; leading `organization_id` index on organization tables (`backend-schema` 3.7) |
| `src/__tests__/unit/http/filters/unhandled-exception.filter.spec.ts`, `src/__tests__/unit/http/pipes/parse-id.pipe.spec.ts` | translated fallback for native HTTP errors; id param validation |

Existing violations live in explicit `known*` lists inside each spec, and those lists work as a **ratchet**:
- a new violation fails the suite;
- fixing a known one also fails the suite until its entry is deleted.

Rules for the `known*` lists:
- Never add an entry to make a change pass.
- Refactoring a module (`backend-refactor`) includes removing every entry of that module from every `known*` list.
- A list that only shrinks is the backlog of the API.

Run `pnpm test:architecture` in every backend task that touches controllers, DTOs, schemas, seeds, translations or imports across modules.

When `tsc`/lint are requested: `npx tsc --noEmit -p tsconfig.json --incremental false` (the `dist/` folder may be root-owned, which breaks the incremental build info) and `npx eslint "{src,apps,libs,test}/**/*.ts"`. After any `eslint --fix`, rerun the architecture suite and the affected module suites, because `--fix` reorders class members, decorators and object keys.

## 10. Done criteria

- Inventory reported, and every line covered or justified.
- Module suite green, thresholds met.
- Mutation checks reported as failing the suite.
- `pnpm test:architecture` green, with the module's entries removed from every `known*` list.
- Contract changes that affect the frontend listed for the user (no frontend edits during backend tasks).

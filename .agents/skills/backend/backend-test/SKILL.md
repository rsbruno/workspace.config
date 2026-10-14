---
name: backend-test
description: Standard for backend tests — unit, integration (real Postgres), E2E (real HTTP/guards/CQRS/i18n), scenario inventory, mutation checks.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-test

Every backend module is tested the same way. Pick one fully tested module as the reference suite and copy its structure, block order and naming; change only what is module-specific.

## Core rules

- Read the whole module first (controller, handlers, DTOs, repositories, schema, requirement notes). Write the scenario inventory and report it. Every line becomes at least one test; uncoverable ones are reported with the reason.
- Use shared helpers from `src/__tests__/helpers`. Never re-implement them inside a spec; add generic ones to the folder.
- Unit: handlers (exact dispatched queries + explicit repository payload, error branches assert no write), DTOs (whitelist validation, every boundary), repositories (assert compiled SQL: organization condition on every read and write, `deleted_at is null`, no `db.delete`), controller metadata matrix.
- Integration: real dev database inside a rolled-back transaction, two organizations, archived/deleted variants, DB errors inside savepoints.
- E2E: real guards, pipes, filters, CQRS, i18n. Never mock the buses. Feature and permission tested together and individually for every endpoint. Every error asserts translation.
- Data-driven cases use `it.each`. No comments. No `any`.
- Mutation checks before done: remove an `organizationId` condition, a translation key, a `@Can`; the suite must fail each time.
- Per-module jest config: statements/lines/functions 100, branches 80.
- Architecture suite (`known*` lists are ratchets): never add an entry to make a change pass; refactoring a module removes its entries.

## References

| Read when | File |
|---|---|
| Starting any test work (first step) | [references/scenario-inventory.md](references/scenario-inventory.md) |
| Creating spec files, naming, using helpers, mandatory mocks | [references/layout-and-helpers.md](references/layout-and-helpers.md) |
| Writing unit specs | [references/unit-tests.md](references/unit-tests.md) |
| Writing integration or E2E specs | [references/integration-and-e2e.md](references/integration-and-e2e.md) |
| Finishing: mutation checks, coverage config, architecture suite, done criteria | [references/mutation-coverage-architecture.md](references/mutation-coverage-architecture.md) |

Related: `backend-refactor` (always includes this), `backend-cqrs`, `backend-rule`.

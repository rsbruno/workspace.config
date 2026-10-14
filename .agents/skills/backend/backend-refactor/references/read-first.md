# Read everything before touching anything

## 1. Read everything before touching anything

1. Every file of the module: controller, module, handlers, commands, queries, DTOs, response DTOs, schema, both repositories, seeds, policies, features.
2. The project docs: `docs/requirements/<module>.md` and `docs/implementation/<module>.md`. The requirement docs are the business source of truth. If the code diverges from it, report it; never "fix" the business rule from memory.
3. Every other module that reads this module's tables or calls its queries/commands (`grep -rn "<table>Table\|<Entity>Query\|<Entity>Command" src`).
4. The real database shape on the dev database. `src/__tests__/integration/architecture/database-schema.spec.ts` lists the schema drift and the organization tables without an index; read the module's entries there.
5. The module's entries in every `known*` list of the global architecture suite (`backend-test` 9). They are part of the findings.

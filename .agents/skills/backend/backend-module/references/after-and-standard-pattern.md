# After writing files, standard pattern for DB-backed modules

## 3. After writing the files

1. Register `{Module}Module` in `src/app.module.ts` (`imports`), **never** inside an aggregator module.
2. Write the migration by hand (`drizzle/migrations/<next>_<slug>.sql` + entry in `meta/_journal.json`; do not trust generated snapshots when they are out of sync) and apply it to the dev database.
3. Write the tests following `backend-test` (inventory, unit, integration, E2E with the feature + permission matrix, OpenAPI contract, translations, mutation checks) plus `src/__tests__/jest.<domain>-<module>.config.json` and the `test:<module>:cov` script, and run the module suite. `tsc`, lint and the global suite still follow `AGENTS.md`.
4. Register the implementation in the project docs (`AGENTS.md`).
5. State which new env vars (if any) need to be filled in, and which organization-scope or permission exceptions exist.

## 4. Mandatory standard pattern for database-backed modules

Database-backed modules use `deletedAt` and `archivedAt`, never a soft-delete `status` column. They expose qualified entity names such as `CreateAccountGroupCommand` and `FindAllAccountGroupsQuery`, separate command/query repositories, and one handler per use case. The lifecycle is `create`, `update`, `archive`, `delete`, `restore`, `find` and `findall`; deleted rows are excluded from every query and command validation, while delete itself requires a previously archived row.

Use `QueryBus` for related-domain validation (with the session `organizationId`), explicit field-by-field repository writes scoped by `organizationId`, the optional `archived` listing filter, `PaginationResultDto` listings, integer cents/integer-scaled columns instead of `numeric` (`backend-schema` 2.1.4/2.1.5), translated validation messages, and global filters for database constraint errors. Do not add Redis reservation logic or default chart-of-accounts seed logic to the module scaffold; seed data is a separate script when requested.

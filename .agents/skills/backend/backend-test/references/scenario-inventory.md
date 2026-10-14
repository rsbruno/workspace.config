# Scenario inventory (mandatory before any test)

## 1. Inventory before writing a single test (mandatory)

Read the whole module first: controller, every handler, every DTO, both repositories, the schema, the requirement doc (`docs/requirements/<module>.md`) and the implementation note. Then write the scenario inventory as a list. Report it to the user before or together with the tests. Every line becomes at least one test.

For **each endpoint**:

| Area | Scenarios |
|---|---|
| Authentication | no cookie, invalid session |
| Feature | feature missing (alone) |
| Permission | permission missing (alone), feature and permission both missing, only its own permission granted passes the guards, documented exception without `@Can` |
| Organization | another organization reads, lists, updates, archives, restores, deletes → 404/empty; repository SQL contains the organization condition on every read and write; conflict updates and pivots cannot mutate another organization; `organizationId` sent by the client in body or query → rejected by whitelist; created row persisted with the session organization |
| Sub-scope (e.g. site; `backend-cqrs` tenant-scope reference) | user with no site grant sees all sites; user granted site A sees/writes only site A; site B rows → 404/absent from lists and totals; payload referencing site B → rejected |
| Path params | invalid id (too long, forbidden characters) → `400 sys:validation:0001` on every `:id` route, before the handler; unknown route → translated `404` |
| Dates (when present) | wrong format, impossible date, inverted range, exact `YYYY-MM-DD` round trip |
| Audit | every write endpoint carries `@Audit` (controller metadata matrix) |
| Validation, per field | required, blank after trim, wrong type, `maxLength` and `maxLength - 1`, numeric `min - 1`/`min`/`max`/`max + 1`, integer vs fractional, enum outside the enum, unknown field, lifecycle/organization fields sent by the client |
| Business rules | each valid transition; each invalid transition; repeated action (archive twice, delete twice); repository transition returning `false`/`null` (race); relation missing, archived, deleted, or from another organization |
| Listing | each filter alone; filters combined; `archived` true/false/omitted; search escaping `%` and `_`; pagination (`pageSize`, `pageNumber`, `MaxPageSize + 1`); stable order; `total` consistent with the page joins |
| Persistence | unique constraint scoped by organization; FK; column type (integer-scaled values); deleted rows never returned |
| Contract | OpenAPI schema of response and payload DTOs (types, `nullable`, `required`, `maxLength`, `minimum`/`maximum`, `integer`) |
| Translation | every error response has a translated message; every validation message key exists; every module `CodeExceptions` is translated |

A scenario that cannot be covered is listed in the final report with the reason. Nothing is silently skipped.

---
name: backend-cqrs
description: CQRS rules for a NestJS API — query vs command, module boundaries, tenant scope, lifecycle, pagination, handler/controller/module templates.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-cqrs

Fixed rules for CQRS composition in a NestJS DDD API. Read only the references the task touches.

## Core rules

- HTTP verb decides the class: `@Get` = Query, `@Post/@Put/@Patch/@Delete` = Command. Side effects never decide.
- Cross-module calls only via `QueryBus`/`CommandBus`. Never inject another module's repository/service; a repository is a provider of its own module only.
- Same-module shared rule = its own Command, called through `commandBus`. Never duplicate inline.
- Organization comes only from `@CurrentUser().organizationId`. Never from body/query/path. Foreign rows answer 404, never 403.
- Every endpoint has `@Feature` + `@Can`; every write has `@Audit()`; id params use `ParseIdPipe`.
- Public class/DTO/operation names are entity-qualified and globally unique (Orval consumes them).
- `findAll` paginates at the source (`LIMIT/OFFSET` + `count()`), returns `PaginationResultDto`. Never slice in memory.
- Bus results are typed at call site: `execute<Query, Dto>(...)`. Untyped `execute` forbidden.
- Check every repository transition result (`false`/`null` raises the domain error).
- Output across the backend boundary is built prop by prop. No spread into DB or provider calls.
- Handler validates only what the DTO cannot (relations, lifecycle, business rules).
- No comments in real files. No broad `try/catch`; use `BusinessException`.

## References

| Read when | File |
|---|---|
| Module has a business enum or external dependency (Port) | [references/ports-and-domain.md](references/ports-and-domain.md) |
| Touching `@CurrentUser`, tenant filter, session, sub-scope (e.g. site) | [references/tenant-scope.md](references/tenant-scope.md) |
| Archive/delete/restore, next-code, hierarchical listings | [references/lifecycle.md](references/lifecycle.md) |
| One module needs data/behavior from another, or two handlers share a rule | [references/module-boundaries.md](references/module-boundaries.md) |
| Naming classes/methods, choosing Query vs Command, permissions | [references/naming-and-verbs.md](references/naming-and-verbs.md) |
| Writing a paginated `findAll` | [references/pagination.md](references/pagination.md) |
| Creating query/command/handler files | [references/handler-templates.md](references/handler-templates.md) |
| Creating controller or `*.module.ts` | [references/controller-and-module.md](references/controller-and-module.md) |
| Finishing work: tests, OpenAPI, symbol uniqueness | [references/contract-and-tests.md](references/contract-and-tests.md) |

Related skills: `backend-sql` (repositories), `backend-rule` (permissions), `backend-test`, `backend-filter`, `backend-dto`.

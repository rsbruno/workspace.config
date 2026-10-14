# Skill routing

Which installed skills validate which changed files. Match by path and file suffix; load only the skills with at least one matching file. Names are the skills of this kit; if one is not installed, skip it.

## Which side

| Signal | Side |
| --- | --- |
| `*.controller.ts`, `*.handler.ts`, `*.module.ts`, `*.schema.ts`, `*.repository.ts`, `nest-cli.json`, `drizzle/` | backend |
| `src/pages/`, `*.tsx`, `routes`, `vite.config.*`, `components/`, `i18n/` | frontend |
| Both sets present | both: use one subagent |

## Backend

| Changed files | Skill |
| --- | --- |
| `*.controller.ts`, `*.handler.ts`, `*.query.ts`, `*.command.ts`, `*.module.ts`, `domain/gateways/` | `backend-cqrs` |
| New module folder | `backend-module` |
| `*.schema.ts`, enums, `drizzle/seeds/`, migrations | `backend-schema` |
| `*.repository.ts`, any Drizzle query | `backend-sql` (together with the domain skill) |
| `findall.dto.ts`, filter params | `backend-filter` |
| `http/dtos/*.dto.ts` response DTOs | `backend-dto` |
| Exceptions, `code-exceptions.enum.ts`, translation JSON, DTO property names | `backend-locale` |
| Policy and feature enums, policy seeds, `@Can`/`@Feature` | `backend-rule` |
| `infrastructure/<provider>/`, webhooks | `backend-provider` |
| Backend test files | `backend-test` |

## Frontend

| Changed files | Skill |
| --- | --- |
| Route files, `_components/` of a screen, `create/`, `edit/` | `frontend-page` |
| Table columns, row actions, status badge | `frontend-table` |
| Form fields, Zod schemas tied to a payload | `frontend-form` |
| Filter schema, store, filter fields | `frontend-filter` |
| Skeleton, `pendingComponent`, `*Fallback` | `frontend-fallback` |
| `pages.json` and other screen translation | `frontend-locale` |
| Multi-part components (`Root`/`Context`/parts) | `frontend-component` |
| Steps / wizard routes | `frontend-stepper` |
| Frontend test files | `frontend-qa` |
| Visual redesign work | `frontend-design` (only if the user asked for it) |

## Cross-cutting

- Changes that cross sides (a backend contract change consumed by the frontend): report the frontend impact as a pending item. Do not edit the other side during a one-sided review.
- A skill's own "related skills" line names the other skills that usually apply; follow it only for files in the diff.

---
name: backend-module
description: Scaffold a new NestJS DDD/CQRS module end to end — folder layout, folder responsibilities, registration, migration, tests.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-module

Creates `src/modules/v1/<domain>/<module>/`, replicating the project's source of truth: one hardened module with a full test suite (structure, validations, tests) and the reference modules (lifecycle). Re-read those real directories before writing; this skill describes the pattern, the files are ground truth.

A new module ships consistent on the first delivery: organization scope, permissions, validations, scaled numbers, translations, performant queries and tests. "Scaffold now, harden later" is incomplete work.

## 1. Gather (ask, never assume)

- Domain (parent folder, created if missing) and module name (plural kebab-case).
- Entity (singular PascalCase).
- Operations: queries, commands or both.
- Data source: external provider or database (Drizzle). Decides `infrastructure/`.
- Route auth: JWT by default; `@Public()` only if the user explicitly confirms.

Never invent providers, fields or endpoints. Every endpoint needs `@Feature` + `@Can` (`backend-rule`); an endpoint without `@Can` is a reported exception.

## 2. Build

- Layout and per-folder responsibility → [references/folder-structure.md](references/folder-structure.md)
- Apply the sibling skills per file type: `backend-cqrs` (handlers, controller, module), `backend-schema` + `backend-sql` (tables, repositories), `backend-dto`, `backend-filter`, `backend-locale`, `backend-provider`, `backend-rule`.
- Rules that always hold: separate command/query repositories; one handler per use case; one provider service per use case; response DTO in `http/dtos/`, never in `infrastructure/`; module standalone (no aggregator modules).

## 3. Finish

Register the module in the app module, hand-write the migration and apply it to dev, write tests per `backend-test` and run them, document the implementation, and report new env vars and scope/permission exceptions. Details and the standard lifecycle pattern → [references/after-and-standard-pattern.md](references/after-and-standard-pattern.md)

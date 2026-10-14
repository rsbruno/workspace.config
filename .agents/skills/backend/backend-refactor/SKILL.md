---
name: backend-refactor
description: Workflow to audit and harden an existing backend module until provably consistent — inventory, findings, fixes, migration, tests, report.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-refactor

Goal: a module whose every rule is checked in code and pinned by a test. This skill orchestrates the others; load `backend-cqrs`, `backend-sql`, `backend-schema`, `backend-dto`, `backend-filter`, `backend-locale`, `backend-rule`, `backend-test`, plus `backend-provider` when an external provider exists.

Scope is backend only. Never edit the web app during a backend refactor; list frontend impact of contract changes in the final report.

## Workflow

1. **Read everything** before editing: module files, requirement/implementation notes (business source of truth, report divergence, never fix from memory), consumers of the module, real DB shape, the module's `known*` entries in the architecture suite. → [references/read-first.md](references/read-first.md)
2. **Inventory first**, shown to the user before any fix: scenario inventory (`backend-test`) and findings with `file:line`, failure scenario and fix. Hunt silent failures (wrong totals, no-op updates, untranslated messages, leaked fields, races).
   - Scope, permissions, validations → [references/findings-scope-permissions-validation.md](references/findings-scope-permissions-validation.md)
   - Lifecycle, numbers, queries, boundaries, contract → [references/findings-correctness-queries-contract.md](references/findings-correctness-queries-contract.md)
3. **Fix** in place following each skill. Hand-written migration with data conversion and rollback note. Policy changes update enum, seed and feature links together.
4. **Test** per `backend-test` completely, then remove the module's `known*` entries and run the architecture suite.
5. **Register and report** → [references/fix-test-report.md](references/fix-test-report.md)

## Highest-priority findings

- Missing organization condition in any repository read or write (data leak).
- Missing sub-scope (e.g. site) where rows belong to one.
- Endpoint without `@Feature`/`@Can`/`@Audit`/`ParseIdPipe` and no documented exception.
- Unchecked repository transition (`false`/`null` treated as success).
- Decimals or floats for money/quantities.

Exceptions (global catalogs, endpoints without `@Can`) are always reported to the developer, never left silent.

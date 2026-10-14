---
name: backend-rule
description: Permission (policy) rules — billing-feature gate, fixed row shape, naming, ordering, Manage pattern, catalog and guard tests.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-rule

Every endpoint of a billed feature has `@Feature(...)` + `@Can(...)`. This skill fixes the permission row's shape and decides whether one should exist.

## Core rules

- Gate first: the permission is valid only if its feature exists in the billing catalog (features seed linked to a plan module). No feature = no policy and no `@Can`; that endpoint is a documented, tested, reported exception.
- Code always references constants (`Policies.{Domain}.{Module}.{Action}`, `Features.{Domain}.{Module}`), never literals. Only the seed JSON repeats the literal strings.
- Adding one: enum key (fixed order) → constant in `@Can` and tests → seed row with same `code` → run seed.
- Row fields: hardcoded cuid `id` (`pol` prefix), short `name` (verb + entity), catalog `module`, `code` = `domain:module:action`, `feature`, `description` (max 100 chars, starts with `Permite `).
- One permission per controller method, standardized action words: `create, update, archive, delete, restore, find, findall`, custom ones alphabetical after.
- Grant/revoke pairs collapse into one `manage-{related}` policy; endpoints and commands stay separate.
- Catalog consistency is tested; `knownGaps` is a ratchet, never add an entry to pass.
- Guards tested per endpoint: feature only, permission only, both, own permission passes.
- New/renamed permission is invisible until groups receive it. Finish the task with the group grant step.

## References

| Read when | File |
|---|---|
| Deciding whether an endpoint needs a policy; locating enums/seeds | [references/gate-and-strings.md](references/gate-and-strings.md) |
| Writing a policy row, naming and description patterns | [references/shape-and-naming.md](references/shape-and-naming.md) |
| Ordering entries, grant/revoke pairs, lifecycle actions | [references/order-and-manage.md](references/order-and-manage.md) |
| Catalog test, guard test matrix, granting policies to groups | [references/catalog-tests-and-grants.md](references/catalog-tests-and-grants.md) |

Related: `backend-cqrs`, `backend-schema` (seeds), `backend-test`, `frontend-table` (action column gating).

# Column-by-column filter analysis

## 1. Walk every column, decide filter or not

For each column in the `.schema.ts` (and each business enum from `domain/enums/` tied to the entity), ask:

- **Does a real user/frontend need exist to narrow the list by this?** Not "could someone theoretically filter by this" — a concrete use case (an admin screen with a search box, a dropdown, a date range picker). If there's no plan agreed with the user for that field's box in the UI, ask before adding the filter — don't guess.
- **Is the column low-cardinality (enum/boolean/foreign key) or high-cardinality (name/free text/id)?** This decides the filter's *shape* (see the table below), not whether it's filterable — both kinds can be legitimate filters.
- **Never create a near-duplicate query/controller-method just to change one filter value.** Archive state is one optional `archived` filter in the canonical `FindAll` query, never separate active and archived queries.
- **Internal/managed fields are never filters**: `id`, `deletedAt`, `createdAt`/`updatedAt` timestamps **unless** the use case genuinely needs a date range, and any column the frontend never sees.

Report the per-column decision before writing anything — a short list, one line per column, "filter" or "not a filter, because X", **and the operator/shape picked (section 2) for each one that is a filter** — so both the inclusion decision and the `eq`/`ilike` choice are visible and reviewable, not just the resulting code. Skipping this list and going straight to the repository method is how a categorical column (module, code, any FK/identifier) ends up wrongly wired to `ilike` instead of `eq` — always write the list first, every time, even for a single new filter added to an existing `findAll`.

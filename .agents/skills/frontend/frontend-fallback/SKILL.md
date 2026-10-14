---
name: frontend-fallback
description: Build loading fallbacks/skeletons that mirror the loaded structure exactly — dedicated fallback components, both loading moments, no layout shift.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# frontend-fallback

Promise: no layout shift between skeleton and content. Only gray blocks become real data, same place, size and structure. A generic skeleton is always a UX bug.

Generic skill: names like `Skeleton` or `TextFieldFallback` illustrate one codebase. First find this project's placeholder primitives and fallback conventions. Canonical example: [../frontend-page/references/canonical-crud-reference.md](../frontend-page/references/canonical-crud-reference.md).

## Rules that come first

1. Loading is always a dedicated fallback component (early return / `pendingComponent`), never a `loading` prop cascading through real components.
2. No scattered skeleton logic in real code: no business component has its own `loading` prop, internal conditional or loading Context. Exception: design-system primitives whose public contract already has `loading`.

Read [references/dedicated-fallback-rule.md](references/dedicated-fallback-rule.md) before writing any loading code.

- Isolated component fallback uses generic primitives; screen fallback may use structural `*Fallback` shells and reuses fallbacks of composed pieces. Never duplicate an existing skeleton.
- Listing fallback mirrors toolbar, table and pagination proportions. `min-h-0 flex-1` only for a genuinely bounded region.
- No visual direction here; if no convention exists to mirror, ask.

## Workflow

| Step | File |
|---|---|
| 1. Analyze every element and state before drawing | [references/analysis-and-fidelity.md](references/analysis-and-fidelity.md) |
| 2. Full-page fallback from shells and generic primitives | [references/full-page-skeleton.md](references/full-page-skeleton.md) |
| 3. Cover route `pendingComponent` and client-side first paint (single early return; `keepPreviousData`) | [references/loading-moments.md](references/loading-moments.md) |
| 4. Multiple content shapes, tables, overflow | [references/multi-view-table-overflow.md](references/multi-view-table-overflow.md) |
| 5. Reusable shells, mirror components | [references/reusable-shells.md](references/reusable-shells.md) |
| 6. Final pass/fail list | [references/checklist.md](references/checklist.md) |

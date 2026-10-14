---
name: frontend-page
description: File/folder structure and route chrome for a CRUD screen set (listing + create + edit) — permission gating, form shell, tabs, dialogs, boundaries.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# frontend-page

Defines where every file goes and how a CRUD screen set is composed. Owns layout only: no business logic, schema/validation, table construction, field choice, mutations or copy (those belong to `frontend-table`, `frontend-form`, `frontend-filter`, `frontend-locale`, `frontend-fallback`, `frontend-component`).

Generic: works on any project with file-based routing and a compound-component design system. Names like `PageFormRoot` illustrate one codebase; discover the local equivalents first. Canonical example screen: [references/canonical-crud-reference.md](references/canonical-crud-reference.md) — read it before scaffolding or reviewing a CRUD; its rules are the default and the generic ones here only fill gaps.

## Fixed rules

- Every route (`index.tsx`, `create/index.tsx`, `edit/$id/index.tsx`) sets `beforeLoad: require({ can: [...], features: [...] })` and `errorComponent: ErrorBoundary`. No exceptions, never deferred to a parent.
- Every action that mutates or leads to a mutation is permission-gated (`<Can>` for the create button and form submit; row actions via `permissions`/`visible`, see `frontend-table`). A missing `Permission` enum entry is a stop-and-ask, never an ungated action.
- Use `PageFormRoot` + `PageFormContent` for every create/edit screen. Side panel only with real secondary content. Route-local form Root/Context only when sibling parts truly share state.
- Tabs: each tab owns its search, filter, pagination and navigation. Parent owns title, tab selection, feature gate, shared search schema. No filter props from parent to tab.
- Tabbed routes: `PageRoot` is outermost (`gap-4`), no fragment, no margin classes on `TabsList`/`TabsRoot`.
- Confirmation dialogs are structurally split per action (no `mode` prop; flicker bug). No `index.ts` in `dialogs/`.
- Edit route not-found uses `notFound()` + `_components/boundaries/404.tsx`, never redirect+toast. No `500.tsx`; use the shared `ErrorBoundary`.
- `_components/` and `_schemas/` names are English; the route folder follows the project's route language.

## References

| Read when | File |
|---|---|
| Scaffolding or reviewing any CRUD (canonical screen) | [references/canonical-crud-reference.md](references/canonical-crud-reference.md) |
| Creating the 3 route files: gating, hook order, hydration guard | [references/routes.md](references/routes.md) |
| Listing chrome: header, filter, table wrapper, pagination wrapper | [references/listing-layout.md](references/listing-layout.md) |
| Create/edit form layout, `PageForm*` family, Root/Context decision | [references/form-layout.md](references/form-layout.md) |
| Confirmation dialogs | [references/dialogs-layout.md](references/dialogs-layout.md) |
| 404 handling, `ErrorBoundary`, `Page403/404/500` families | [references/boundaries.md](references/boundaries.md) |
| Tabbed listing or edit screen | [references/tabs-layout.md](references/tabs-layout.md) |
| Folder tree, single-record settings screen variant | [references/folder-structure.md](references/folder-structure.md) |

## Generation order

1. Confirm folder/route naming with the user.
2. Check the form-layout compound family exists; create it first if not (`frontend-component`).
3. Scaffold `_components/forms/` (form-layout reference).
4. Create `table/` and `dialogs/` stubs (dialogs reference).
5. Add `fallbacks/` (`frontend-fallback` owns their content).
6. Add `boundaries/404.tsx` for the edit route (boundaries reference).
7. Scaffold the 3 routes wiring everything (routes reference).
8. Hand off copy/i18n and filter fields as separate work.
9. Review against the compound-component checklist (`frontend-component`).

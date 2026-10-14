# Settings-screen variant and fixed folder structure

## Single-record "settings screen" variant

A domain with no listing and no creation (e.g. one settings record per organization, edited directly) reuses only the relevant half: `_components/forms/` (root/context/sections/panel/index), a single form fallback (no listing, so no `<entities>-page-fallback.tsx`), and one `index.tsx` route that *is* the form (no `create/`/`edit/$id/`, no `_components/table/`, no `_components/dialogs/`). Sections still split by field group the same way a full CRUD form would if it's large enough — that's a layout call, not exclusive to the "full" CRUD case. The side panel still follows the same avatar/thumbnail composition as any other entity for visual consistency, even if this entity has no matching upload endpoint.

## Folder structure (fixed)

```
src/pages/<group>/<entities>/
  index.tsx                              → listing (loader + validateSearch if filtered + component)
  create/
    index.tsx                            → create route
  edit/
    $id/
      index.tsx                          → edit route
  _schemas/
    <entity>.schema.ts                   → owned by the project's data layer, not this skill
  _components/
    forms/
      root.tsx                           → <Entity>RegistrationFormRoot
      context.ts                         → Context + use<Entity>RegistrationFormContext
      <section-1>.tsx                    → <Entity>RegistrationForm<Section1>
      <section-2>.tsx                    → one per field group worth separating visually
      panel.tsx                          → panel body + footer, content only — see references/form-layout.md
      index.ts                           → single import point, flattened exports
    table/
      status-badge.tsx                   → <Entity>StatusBadge (only if the entity has status) — content out of scope
      <entity>-row-actions.tsx           → <Entity>RowActions — content out of scope
    dialogs/
      delete-<entity>-confirmation.tsx    → Delete<Entity>Confirmation
      restore-<entity>-confirmation.tsx   → Restore<Entity>Confirmation (only if the entity supports restore)
    fallbacks/
      <entities>-page-fallback.tsx        → listing skeleton
      <entity>-form-fallback.tsx          → form skeleton
    boundaries/
      404.tsx                            → <Entity>NotFoundScreen — see references/boundaries.md
                                            (no 500.tsx: every route instead sets
                                             errorComponent: ErrorBoundary — reusable component,
                                             covers 500/permission-denied/subscription-required —
                                             see references/boundaries.md)
```

Everything under `_components/`/`_schemas/` uses English names (export/file names); the route folder (`<entities>/`) follows whatever language the project's routes use.

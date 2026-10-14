---
name: frontend-component
description: Pattern for React compound components (2+ parts sharing state) — one file per part, flattened exports, index.ts only, React 19, scoped vs global.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# frontend-component

Applies only when a component has 2+ subparts sharing state or coordinating behavior. A single piece (Button, Badge) needs one file, no folder or Context. Canonical example: [../frontend-page/references/canonical-crud-reference.md](../frontend-page/references/canonical-crud-reference.md) (form root/context, flattened exports, fallback siblings, `If`/`ForEach`); it wins over generic examples.

## Fixed rules

- One file per part inside a kebab-case folder; consumption only through `index.ts`. Exports flattened (`ComponentNameRoot`, never `ComponentName.Root`). Names in English.
- Always TypeScript, React 19: `ref` is a normal prop, never `forwardRef`.
- No comments in any file.
- Reuse `src/components/ui` (Typography, Button, avatar, separator, skeleton, spinner...). Missing primitive or variant: stop and ask.
- Reuse `src/components/utils`: `If/Then/Else` (no raw `&&`/ternary), `ForEach` (no raw `.map()`), `ShowExceptionIf`.
- No visible string literal in JSX (i18n decisions are `frontend-locale`).
- Public business prop lives only on Root, never redrilled.
- Fallback is separate work (`frontend-fallback`).
- Default scope is **scoped** (`_components/` of the requesting screen). Global only when the request is already generic by nature. Scope goes up only with proven reuse (screen → route group → global), never speculation. Doubt: ask.
- Before creating a part, check it truly depends on the family's Context/Root. If not: reuse an existing one, or extract to its own folder at the right scope level. Never bury it inside the family.
- Multi-section forms sharing UI state may use Root/Context (`isEditing`, `isPending` only, memoized value, wraps `FormProvider`, server data and mutations stay outside).

## References

| Read when | File |
|---|---|
| Naming, folder structure, blocked direct imports | [references/naming-and-structure.md](references/naming-and-structure.md) |
| Sharing state (`cloneElement` → callback → Context), templates | [references/composition.md](references/composition.md) |
| Variants with `tv({ slots, variants })` | [references/variants.md](references/variants.md) |
| Prop typing, performance, data fetching | [references/typing-and-performance.md](references/typing-and-performance.md) |
| Finishing (always) | [references/checklist.md](references/checklist.md) |

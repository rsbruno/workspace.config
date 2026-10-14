# `_components/dialogs/` — structural split (only when the entity has confirmation dialogs)

This is a **layout/component-composition rule**, not a business rule — it exists because of a real visual bug, not because of what the dialogs do.

**Never share a single confirmation component alternating variant/icon/text by conditional prop** between two different confirmation actions on the same entity (e.g. a delete confirmation and a restore confirmation). That causes flicker: when one mutation resolves and invalidates the listing, the row's underlying state changes and the shared component re-renders with the *other* action's content (variant/icon/text) still visible during the closing modal's exit animation.

## The fix: one fully isolated dialog component per action

One file per action (e.g. `delete-<entity>-confirmation.tsx`, `restore-<entity>-confirmation.tsx`), each a dedicated confirmation component with its **own fixed variant** (danger for destructive, success for restorative, etc.) — never a shared one branching on a prop.

Structural rules for these components:

- They receive `open`/`onOpenChange`/`onConfirm`/`pending`/whatever text field the confirmation needs, as props — no state of their own, no mutation inside the dialog. Deciding when to open and firing the actual mutation is the row-actions component's job, not the dialog's — that orchestration logic is outside this skill's layout scope.
- **This folder gets no `index.ts`** — unlike `forms/`/`table/`, each dialog file is imported directly from wherever it's used, no shared re-export point.
- The caller always mounts both dialogs at once, only one with `open=true` at a time — this is what structurally prevents the flicker, since the inactive one never held the other's content to begin with.

Copy (dialog title/description/button labels) is out of this skill's scope — only the *rule that dialogs must be structurally separate* belongs here.

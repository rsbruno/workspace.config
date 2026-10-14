# Create/edit routes — shared form layout

For the the web app canonical implementation, see `canonical-crud-reference.md`. It demonstrates a valid form without a side panel: `PageFormRoot` contains only `PageFormContent` when the domain has no secondary panel content.

Both routes share the same compound form (`_components/forms`), only differing in what wraps it. This reference only covers **layout composition** — what fetches/submits the form is the route's own data logic, not something this skill dictates.

## The form layout is always a dedicated compound-component family

The two-column grid + side-panel chrome is **never** a raw `<div className="grid ... lg:grid-cols-[1fr_320px]">` written by hand in each route, and never the generic page card reused directly for the side panel. This family owns the skeleton when a panel exists; when the domain has no secondary content, use only `PageFormContent` inside `PageFormRoot` and do not create an empty panel. The route only injects sections/fields and panel content inside it.

**Before generating the form:** check whether the project already has this family (grep for something like `PageFormRoot`/`FormPageRoot`/the local design system's equivalent name). If it exists, use it. **If it doesn't exist yet**, it needs to be created first as its own compound component (own folder, one part per file, single `index.ts`) *before* generating the rest of the screen — never hand-write the grid/chrome "just this once" assuming the family gets extracted later. The registration-form Context is allowed when sections share editing/pending state; it must stay limited to that UI state. How to author a compound component is out of this skill's scope.

```tsx
<EntityRegistrationFormRoot onSubmit={...} isPending={...} /* isEditing, values on the edit route */>
  <PageHeaderRoot>
    <PageHeaderBack />
    <PageHeaderContent>
      <PageHeaderTitle>{t("...")}</PageHeaderTitle>
      <PageHeaderSubtitle>{t("...")}</PageHeaderSubtitle>
    </PageHeaderContent>
  </PageHeaderRoot>

  <PageFormRoot>
    <PageFormContent>
      <EntityRegistrationFormGeneralInfo />
      {/* other sections */}
    </PageFormContent>

    <PageFormPanel>
      <PageFormPanelBody className="flex flex-col items-center justify-center">
        <EntityRegistrationFormPanelBody />
      </PageFormPanelBody>

      <EntityRegistrationFormPanelFooter />
    </PageFormPanel>
  </PageFormRoot>
</EntityRegistrationFormRoot>
```

- `PageFormRoot` = the form layout grid; it supports the full `[1fr_320px]` composition and the content-only composition.
- `PageFormContent` = left-column wrapper (`grid gap-4`), receives sections directly (each section still uses `PageCardRoot`/`PageCardLabel`/`PageCardContent` normally).
- `PageFormPanel` = right-panel chrome, sticky by default (canonical: `<group>/<entity>/create` + `editar/$id`: `PageFormPanelHeader` with identity, `PageFormPanelBody` with section index, `PageFormPanelFooter` with save `Button`).
- `PageFormPanelBody` = panel's content area (`className="flex flex-col items-center justify-center"` for the default centered-avatar case; adjust if the entity's panel content is something else, e.g. an image grid).
- `PageFormPanelHeader` — only if the panel needs a title/subtitle block with a separator above the content (not the default avatar case, but happens on richer panels), as the first child of `PageFormPanel`.
- `<Entity>RegistrationFormPanelFooter` is already the whole footer — no need to wrap it in `PageFormPanelFooter` unless the footer holds more than a single button.
- The submit action inside `<Entity>RegistrationFormPanelFooter` (or `PageHeaderActions` on some layouts) is always wrapped in `<Can permissions={[Permission.ENTITIES_CREATE]}>` on `create/`, `<Can permissions={[Permission.ENTITIES_UPDATE]}>` on `edit/$id/` — matching the route's own `beforeLoad` permission (see `references/routes.md`).

## When to skip the Root/Context wrapper entirely

A form with a **single section** doesn't need the extracted `<Entity>RegistrationFormRoot` + `context.ts` pair — inline `useForm` + `FormProvider` directly in the route file instead of extracting a form-root component with a Context that has nothing to share. Multi-section forms (2+ files under `forms/`) always get the full Root/Context split described below, since sections need `isEditing`/`isPending` without prop-drilling from the route. Context is never the default, only used when justified.

## `_components/forms/` internal layout

- **`root.tsx`**: `<Entity>RegistrationFormRoot` — mounts the form provider, wraps children in Context, renders `<form>`. Business logic (what `onSubmit` does, validation schema) lives outside this skill's scope.
- **`context.ts`**: shares only UI-relevant state (`isEditing`, `isPending`) — never server data.
- **One section per file** (`general.tsx`, `<group>.tsx`, ...): each section is `<Entity>RegistrationForm<SectionName>`, a `PageCardRoot`+`PageCardLabel`+`Separator`+`PageCardContent` wrapping the section's fields. Which fields exist, their component type, their grid arrangement, and their validation rules are entirely out of this skill's scope — this skill only owns that the section is one file, wrapped in this chrome.
- **`panel.tsx`**: only the panel's **content** — never mounts `PageCardRoot`/`PageFormPanel` here (that's chrome owned by the route via the `PageForm*` family). Exports:
  - `<Entity>RegistrationFormPanelBody` — no props, avatar/thumbnail + name/subtitle, no own layout wrapper (the route's `PageFormPanelBody` positions it).
  - `<Entity>RegistrationFormPanelFooter` — reads `isEditing`/`isPending` from Context, renders the project's generic form-submit button component.
- **`index.ts`**: flat re-export, never re-exports `context.ts`.

Loading for the whole form is **never** a `loading` prop on the Root/Context cascading through sections/panel — it's a single early-return (`if (isPending) return <EntityFormFallback />`) at the route level, before mounting the real tree.

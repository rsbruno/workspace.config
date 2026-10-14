# Checklist before finishing a compound component

1. Each part in its own file, named exactly like the export (kebab-case)?
1a. Does every part in the folder actually belong to the family (depends on the Context/Root)? No generic piece buried here instead of reused/extracted?
2. Are the folder name and each part's name genuinely descriptive (not a generic `Modal`/`Card` left loose)?
2a. Folder and files in kebab-case?
3. No file has a comment — not for pattern decisions, not for business rules, not for purpose?
4. Every part uses the matching primitive from `src/components/ui`/`src/components/utils` instead of raw HTML/hand-rolled conditionals — and if a primitive was missing, was the user consulted?
5. No part overrides the style a primitive already defines from the outside (no conflicting `className`, `!important`, literal color over `color`/`variant`)?
6. If it uses Context: was it genuinely necessary (see `composition.md`) or explicitly requested? Was `cloneElement`/`children` tried first?
6b. No data from `useApiQuery`/`useQuery` enters Context or gets redrilled through Root props?
6c. Is every prop a genuine external decision/action, not data the part would fetch on its own?
6d. If it coordinates 2+ modals: one `useDisclosure()` per modal, renamed props, no string comparison?
6a. If it has its own variant: prop only on the Root, single `tv({ slots, variants })` in `styles.ts`, child reads the slot via Context?
7. Flattened exports (`ComponentNameTrigger`), never dot notation?
8. Is `index.ts` the only file importable from outside — `context.ts` and internals not re-exported?
9. Is there a lint rule (`no-restricted-imports`) blocking direct imports of internals?
10. `displayName` defined, no `forwardRef`?
11. Was `asChild`/`Slot` evaluated (not assumed automatically) on every DOM-rendering part?
12. Visual state via `data-state`/`data-disabled`, not conditional className?
13. Are all props and the Context typed (no `any`)?
14. Does every part export `<RealName>Props`?
15. Does every type extend `ComponentProps<...>` from the native tag or the external lib's type (never `ComponentPropsWithoutRef`)?
16. If there's Context: is `value` memoized with `useMemo`, handlers with `useCallback`?
17. Are "leaf" parts used at scale wrapped in `memo` where it makes sense?
18. No inline object/array/function in JSX for props going to memoized components?
19. No `import * as React from "react"` — named symbols imported directly?
20. No `forwardRef`/`ComponentRef`/`ElementRef`?
21. No cast (`as never`/`as any`/`as unknown`) masking a real type error?
22. Async list: is the skeleton in its own `component-name-fallback.tsx`, only in `index.ts` if an outside consumer needs it?
23. Every visible string via i18n, never a literal in JSX?

If any answer is no (or "no, but it should be"), fix it before considering the component done.

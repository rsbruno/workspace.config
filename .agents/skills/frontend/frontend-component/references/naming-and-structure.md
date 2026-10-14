# Naming and folder structure

## Conventions (fixed)

- **Always descriptive names** — `Modal` is vague, `ConfirmDeleteAccountModal` is descriptive. Applies to the whole family and each part (`ProductReviewCardTrigger`, never an abbreviation like `PRCardTrigger`).
- **Always in English** — folder, file, export, even when the route consuming it is in Portuguese (route is a URL for the end user, component is code vocabulary). A login form on route `/entrar` becomes `sign-in-form/` (`SignInForm`), never `entrar-form/`/`FormularioEntrar`.
- **Folder and file: `kebab-case`** (`product-review-card/`, `checkout-stepper/`).
- **Export: flattened `PascalCase`** — `<ComponentName><Part>` (`SelectRoot`, `SelectTrigger`) — never dot notation, never a composed object.
- **File = kebab-case of the export**: `SelectTrigger` → `select-trigger.tsx`. Same for `context.ts`/`styles.ts`.
- **A hook file is always `.tsx`, never `.ts`** — even with no JSX today, it's a natural extension point. Only exception: `context.ts` (Context + types, not a general-purpose hook).
- Context hook: `use<ComponentName>Context`, private, never exported from `index.ts`.
- Types: `<ComponentName>ContextValue` for the Context, `<ComponentName><Part>Props` for props.
- Never `import * as React from "react"` — always a named symbol (`import { useState, useMemo } from "react"`).

## Folder structure (fixed pattern)

```
component-name/
  component-name-root.tsx
  component-name-trigger.tsx
  component-name-content.tsx
  component-name-<other-part>.tsx
  component-name-fallback.tsx → skeleton used as ForEach's fallBack (see below)
  styles.ts                  → tv({ slots, variants }) — only exists if the family has its own variant
  context.ts                 → Context + hook + types — only exists if Context is justified (see composition.md)
  index.ts                   → single public entry point
```

### Loading fallback

If any part fetches an async list (`ForEach` with `isLoading`/`fallBack`), the skeleton lives in its own `component-name-fallback.tsx`, export `ComponentNameFallback` — never a loose function in the middle of the file that uses it. Only goes into `index.ts` if some outside consumer genuinely needs it isolated.

## Single entry point

- No one outside the folder imports an internal file directly — always `from "@/components/component-name"` (the index).
- `index.ts` re-exports everything flattened, no comment. Doesn't re-export `context.ts`.
- Block direct imports via `no-restricted-imports` in the eslint config:

```js
{
  rules: {
    "no-restricted-imports": ["error", {
      patterns: [{
        group: ["@/components/*/!(index)", "@/components/*/*.tsx"],
        message: "Always import through the component folder's index.ts, never an internal file.",
      }],
    }],
  },
}
```

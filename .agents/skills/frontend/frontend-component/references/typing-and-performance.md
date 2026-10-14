# Prop typing (fixed rule, no exceptions)

0. A prop is always in English — prop name, type key, union literal. Applies even inside a Portuguese route (folder `pedido/$id`, prop never `pedidoId`, always `orderId`). Visible text isn't a config prop — that goes through i18n.
1. Every part exports its own props type: `export type { ComponentNameTriggerProps }` (re-exported from `index.ts`).
2. Type name = real component name + `Props`. `SelectTrigger` → `SelectTriggerProps`. Never a generic `Props`/`TriggerProps`.
3. Always extend from the native `ComponentProps<...>`, never redeclare HTML props by hand:
   - From scratch: `interface SelectTriggerProps extends ComponentProps<"button"> { asChild?: boolean }`. `ComponentProps<"button">` already includes a typed `ref` (React 19) — never `ComponentPropsWithoutRef` (pre-19/`forwardRef` world).
   - Wrapping an external lib (Radix, etc.): extend the lib's own type — `interface SelectTriggerProps extends ComponentProps<typeof SelectPrimitive.Trigger> {}`.
4. Never `forwardRef`. `ref` is received as a normal prop, right in the destructuring.

```tsx
// from scratch
interface SelectTriggerProps extends ComponentProps<"button"> {
  asChild?: boolean;
}
function SelectTrigger({ asChild, ref, ...props }: SelectTriggerProps) {}
export type { SelectTriggerProps };

// wrapping an external lib
interface SelectTriggerProps extends ComponentProps<typeof SelectPrimitive.Trigger> {}
function SelectTrigger({ ...props }: SelectTriggerProps) {}
export type { SelectTriggerProps };
```

`forwardRef`/`ComponentRef`/`ElementRef` are never used — pre-React-19 legacy. `ref` already comes typed via `ComponentProps<...>`.

## No shortcuts on typing

**No deprecated import.** Check whether it's been replaced in a newer version (most common case here: `forwardRef`/`ComponentRef`/`ElementRef`).

**No cast that masks a type error.** `as never`/`as any`/`as unknown as X`/a two-step cast isn't a fix, it's deferring the error to runtime. If TypeScript complains:

1. Fix the source: type the `state`/prop/parameter correctly at the declaration (`useState<CorrectType>(...)`, `isValidElement<CorrectType>(child)`, explicit generic).
2. If the cast is genuinely necessary (narrowing the compiler can't prove on its own, integration with a weakly-typed lib), use the most specific type possible as the target — never `never`/`any`/`unknown`, never a two-step cast.
3. When in doubt whether the cast is masking a real typing bug, stop and ask the user.

# Performance and scalability

Every compound component must be written assuming it'll run in large lists, re-render frequently, or compose deep trees:

1. **Context `value` always memoized with `useMemo`**, handlers with `useCallback` — a new object on every Provider render kills every consumer's optimization.
2. Split Context that changes rarely from Context that changes often, when the component is large enough to justify it (static config vs. interaction state).
3. **`memo` on "leaf" parts** (Trigger, Item, Content) with no reason to re-render when the parent changes for another reason. Don't memoize blindly — only when used at scale or the parent re-renders frequently.
4. **Never an inline object/array/function in JSX** for props going to memoized components — breaks `memo`'s equality check.
5. **Lazy initialization when the initial value is expensive**: `useState(() => computeInitial())`, not `useState(computeInitial())`.
6. **Avoid `useEffect` to sync derived state** — compute it directly (or with `useMemo` if expensive) during render.
7. Composition via `cloneElement`/`children` whenever possible — structurally lighter than Context.
8. Long list (`SelectContent` with hundreds of options) → consider virtualization (`@tanstack/react-virtual`), mention it as an option to the user, don't assume it by default.

# Fetching and helpers

**Every API call always goes through TanStack Query** (`useQuery`/`useMutation`) — never `useState` + `fetch` + hand-rolled `try/catch`. Errors fall into the global handler (`mutationCache`/`queryCache`, `src/shared/query-client.ts`); use `meta: { ignoreError: true }` only when the component already shows the error inline.

**No pure helper function lives inside the component's file** — if it doesn't depend on `props`/state and only transforms a value, it isn't "part of" the component. Global component (`src/components/`) → helper goes to `src/utils/`. Screen-scoped component (`_components/`) → helper goes to `_utils/` next to the route's `index.tsx`.

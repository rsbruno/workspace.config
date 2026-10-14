# The 3 route files — structural skeleton

For the concrete ordering and behavior, use `canonical-crud-reference.md` as the canonical reference.

This is the **shape** of each route file (what block goes where, in what order) — not the business logic inside each block. What a `loader`/mutation/query actually fetches or sends follows the project's existing data-layer pattern; this reference only fixes where that logic plugs into the file.

Each route is a single file — `Route` (via the project's file-based router, e.g. `createFileRoute`) and its component always live together in the same `index.tsx`, never split across files.

## Permission gating on every route (`beforeLoad`)

Every real route in the set — listing, create, edit — sets `beforeLoad: require({ can: [Permission.X], features: [Feature.Y] })`, one dedicated permission per route type: `<ENTITIES>_READ` for the listing, `<ENTITIES>_CREATE` for create, `<ENTITIES>_UPDATE` for edit — plus the module's `features` gate when the project has feature flags. A redirect-only legacy index (`<entities>/index.tsx`) is the exception: it only redirects to the tabbed parent and does not duplicate the gate or listing. A module with no separate edit flow can collapse to a single manage-level permission instead.

## `pendingComponent` is always a pure component reference, never an inline wrapper

`pendingComponent: EntityFormFallback` — never `pendingComponent: () => <EntityFormFallback />`. The fallback component itself takes no required props (see `frontend-fallback` skill's checklist item 14), so it's always passable directly as the function reference. An arrow wrapper here is dead wrapping — same bug class as any other unnecessary indirection, and it's the kind of drift that creeps in silently when one route is scaffolded by copy-paste from a route that *did* need to pass props. Every route in the set (listing, create, edit) follows this — check it explicitly when reviewing a new or edited route file.

## Route options property order

Every route file lists `Route` options in the same fixed order — deviating (e.g. `loader` before `beforeLoad`) isn't harmless bikeshedding, it's what makes routes diffable at a glance across modules:

```
loader              → (create/index.tsx has none)
beforeLoad
pendingComponent    → (create/index.tsx may use the form fallback when the project route does so)
notFoundComponent   → (edit/$id/index.tsx only)
errorComponent      → always, every route
validateSearch      → only if the route has filters/tabs
component
```

`errorComponent: ErrorBoundary` is set explicitly on every route, never inherited from a parent silently — see `references/boundaries.md`.

## Standard hook order at the top of every route component

This ordering repeats across every mature screen — follow it, don't invent a different one per module:

**Listing**: `useTranslation("pages", { keyPrefix: "<feature-key>" })` → `usePageTitle(t("meta.title"))` → `Route.useSearch()`/`Route.useNavigate()` → `useFilter({...})` (only if the screen has filters) → the listing query hook.

**Create/Edit**: `useTranslation(...)` → `usePageTitle(t("<mode>.meta.title"))` → `useHydrated()` → `useQueryClient()` → `useNavigate()` → (edit only) `Route.useParams()` → the find-by-id query hook (edit only) → `useMutation`.

`usePageTitle(t(...))` is always the line immediately after the `t` destructure — never moved lower, never skipped. `useTranslation`'s `keyPrefix` is the same one string shared by every route file inside a module (`"entities-registration"`, `"group.entities"`, ...) — this is the i18n namespace that keys that module's whole tree, so it must match exactly across `index.tsx`/`create/index.tsx`/`edit/$id/index.tsx`.

## `index.tsx` (listing)

```tsx
export const Route = createFileRoute("/<group>/<entities>/")({
  loader: ({ context }) => /* preload the listing query into the router's cache */,
  beforeLoad: require({ can: [Permission.ENTITIES_READ], features: [Feature.MODULE] }),
  pendingComponent: EntitiesPageFallback,
  validateSearch: /* only if the screen has filters */,
  component: RouteComponent
});

function RouteComponent() {
  const { t } = useTranslation("pages", { keyPrefix: "<feature-key>" });
  usePageTitle(t("meta.title"));
  /* read the listing data via the project's existing query hook */

  if (isPending) return <EntitiesPageFallback />;
  return (/* layout from references/listing-layout.md, "New" button wrapped in <Can permissions={[Permission.ENTITIES_CREATE]}> */);
}
```

## `create/index.tsx`

No `loader` — there's nothing to preload before creating a new record. It may still set `pendingComponent` to the form fallback when the canonical screen uses the route fallback. It also needs the hydration guard (see below).

```tsx
export const Route = createFileRoute("/<group>/<entities>/create/")({
  beforeLoad: require({ can: [Permission.ENTITIES_CREATE], features: [Feature.MODULE] }),
  pendingComponent: EntityFormFallback,
  component: RouteComponent
});

function RouteComponent() {
  const { t } = useTranslation("pages", { keyPrefix: "<feature-key>" });
  usePageTitle(t("new.meta.title"));
  const isHydrated = useHydrated();
  /* project's existing mutation hook, wired to the form's onSubmit */

  if (!isHydrated) return <EntityFormFallback />;

  return (
    <EntityRegistrationFormRoot onSubmit={...} isPending={...}>
      {/* skeleton from references/form-layout.md, submit action wrapped in <Can permissions={[Permission.ENTITIES_CREATE]}> */}
    </EntityRegistrationFormRoot>
  );
}
```

## `edit/$id/index.tsx`

`loader` preloads the single-record query by `params.id`; `pendingComponent` points at the **form** fallback (not the listing one).

```tsx
export const Route = createFileRoute("/<group>/<entities>/edit/$id/")({
  beforeLoad: require({ can: [Permission.ENTITIES_UPDATE], features: [Feature.MODULE] }),
  loader: ({ context, params }) => /* preload the find-by-id query into the router's cache */,
  pendingComponent: EntityFormFallback,
  component: RouteComponent
});

function RouteComponent() {
  const { t } = useTranslation("pages", { keyPrefix: "<feature-key>" });
  usePageTitle(t("edit.meta.title"));
  const isHydrated = useHydrated();
  const { id } = Route.useParams();
  /* read the record via the project's existing query hook, map it to the form's values shape */

  if (isPending || !isHydrated) return <EntityFormFallback />;

  return (
    <EntityRegistrationFormRoot onSubmit={...} isPending={...} values={values} isEditing>
      {/* same skeleton as create/index.tsx, now with values + isEditing, submit action wrapped in <Can permissions={[Permission.ENTITIES_UPDATE]}> */}
    </EntityRegistrationFormRoot>
  );
}
```

The early-return to `EntityFormFallback` happens **before** the real form tree mounts — never a `loading` prop cascading into `EntityRegistrationFormRoot`/Context/sections instead.

`edit/$id/index.tsx` maps the fetched record into the form's `values` shape right in the route file — any `?? ""` fallback for an optional field there is the same violation `frontend-form` flags for `defaultValues`: use `Strings.EMPTY` (or the project's equivalent constant), never a bare `""`/`"-"` literal. This mapping happens in the route file, not inside a form component, so it's easy to miss when only auditing `_components/forms/` — check it explicitly.

## Hydration guard (`create/` and `edit/$id/` only, never the listing)

`create/index.tsx` and `edit/$id/index.tsx` both guard their real form tree behind `useHydrated()` (`@/hooks/use-hydrated`, `useSyncExternalStore` returning `false` on the server / first client render and `true` once hydrated) — `if (!isHydrated) return <EntityFormFallback />;` on create, folded into `if (isPending || !isHydrated) return <EntityFormFallback />;` on edit (no separate "record missing" check — a resolved query with `isPending: false` is trusted to have data). This exists because the form tree carries client-only state and behavior (React Hook Form, input masks, `FileAvatarRoot` previews) that would otherwise produce a server/client markup mismatch on first paint — the fallback is deliberately shown one extra tick even when there's no async data to wait for.

The listing route (`index.tsx`) does **not** use this guard — a table rendered from SSR-preloaded data has no client-only-state mismatch to guard against. Only screens mounting the form tree need it.

## `onError` on mutations — inconsistent across the codebase, ask rather than guess

Some modules attach an `onError` toast to every mutation (`onError() { toast.dispatch(t("toast.x-error"), { variant: "danger" }); }`), others have none (relying on a global error interceptor). This is a real, unresolved inconsistency between modules, not a settled convention — don't silently copy whichever reference screen you happened to look at. Ask the user which one this new screen should follow, or check the project's newest/most-recently-touched CRUD module as the more likely current standard.

## Cross-route rule

`create/index.tsx` and `edit/$id/index.tsx` render the exact same layout skeleton (`references/form-layout.md`) — the only structural differences are: `create` has no `loader`/`pendingComponent`/`values`/`isEditing`/pending-record check, `edit` has all of them (both share the `useHydrated()` guard). Never let the two skeletons drift apart visually; if a change is needed on one, mirror it on the other.

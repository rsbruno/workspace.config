# Not-found / error boundaries

Two different concerns, two different entities:

- **404 (record doesn't exist)** — entity-specific, one screen per module, lives with the module (`_components/boundaries/404.tsx`), wired per-route via `notFoundComponent`.
- **Everything else that can go wrong (500, no permission, plan doesn't cover the feature)** — generic, **one single reusable boundary component** (`ErrorBoundary`, `src/components/boundary/error/`), but wired **explicitly on every single route** (`errorComponent: ErrorBoundary`) — never left to bubble up from a parent/layout route. Do not create a per-module 500 screen — that pattern is retired; do not rely on the layout root's own `errorComponent` to cover child routes either — every leaf route sets it too.

Both render **inside the app layout** (the route's parent layout still mounts — header/sidebar/whatever — only the route's own content swaps), never a bare redirect to the listing with a toast.

## The loader: `notFound()`, not redirect+toast

```tsx
import { ErrorBoundary } from "@/components/boundary/error";

export const Route = createFileRoute("/<group>/<entities>/edit/$id/")({
  loader: ({ context, params }) =>
    ensureApiQueryData(context.queryClient, findEntityByIdQueryOptions(params.id)).catch((error) => {
      if (!isAxiosError(error) || error.response?.status !== 404) throw error;

      throw notFound();
    }),
  pendingComponent: EntityFormFallback,
  notFoundComponent: EntityNotFoundScreen,
  errorComponent: ErrorBoundary,
  validateSearch: tabSchema,
  component: RouteComponent
});
```

Every route — listing, create, edit, single-record settings screen, anything reachable via `createFileRoute` — sets `errorComponent: ErrorBoundary`, no exceptions and no relying on a parent route's own `errorComponent` to cover it implicitly. TanStack Router *would* propagate an unhandled error up to the nearest ancestor that declares one, but this project does not lean on that behavior — every screen wires it directly, so a route's error handling is visible and correct by reading that one route file, not by having to check its whole ancestor chain. Only pass a non-default `backTo` when that specific screen's "back" action should land somewhere other than `/` — `errorComponent: (props) => <ErrorBoundary {...props} backTo="/some/other/place" />`, still reusing the same component, never a hand-rolled one.

- `.catch()` on the promise, never a `try`/`catch` statement around an `await` — same outcome, less indentation, matches this project's style once established (if the project you're on has no stated preference either way, default to `.catch()`).
- On a real 404, `throw notFound()` (the router's own not-found error) — never `throw redirect({ to: listing })` with a manually-dispatched toast. A redirect-based 404 has two real failure modes this avoids: (1) calling any browser-only API (a toast library, `sonner`, anything touching `document`) from inside a loader breaks on SSR — the loader can run server-side on a full page load, and a toast call there either does nothing usefully or hangs the request depending on the library; (2) it's simply more moving parts (redirect target, a search-param flag to trigger the toast once landed, cleanup of that flag) for a worse result (the user leaves the record's URL instead of seeing why it's missing right where they were).
- Any other error (non-404, e.g. a genuine 5xx, permission-denied, plan-doesn't-cover-it, or network failure) re-throws as-is and is caught by the global `ErrorBoundary`, not swallowed.
- The find-by-id query options should also carry `retry: false` (a 404 is not transient, retrying it 3 times with backoff only delays the both the 404 screen and the toast-skip fix below) and pass `{ _skipErrorToast: true }` (or whatever this project's per-request escape hatch is named) to the underlying API call — the global axios/fetch error interceptor that auto-toasts every failed request would otherwise fire for this expected 404 too, on top of (or instead of) the dedicated screen.

## The 404 screen: `_components/boundaries/404.tsx`

Still per-module, still its own file, own named export, imported into the route — never inline the not-found JSX in the route file:

```tsx
// _components/boundaries/404.tsx
import { useTranslation } from "react-i18next";

import { PageRoot } from "@/components/ui/page";
import notFoundIllustration from "@/assets/illustrations/not-found.svg";

import { Page404PageContent, Page404Illustration, Page404Description, Page404PageHeader, Page404Actions, Page404Action, Page404Title } from "@/components/boundary/404";

function EntityNotFoundScreen() {
  const { t } = useTranslation("pages", { keyPrefix: "<feature-key>.not-found" });

  return (
    <PageRoot>
      <Page404PageHeader title={t("title")} />
      <Page404PageContent>
        <Page404Illustration src={notFoundIllustration} />
        <Page404Title>{t("title")}</Page404Title>
        <Page404Description>{t("description")}</Page404Description>
        <Page404Actions>
          <Page404Action text={t("back-to-list")} to="/<group>/<entities>" />
        </Page404Actions>
      </Page404PageContent>
    </PageRoot>
  );
}
EntityNotFoundScreen.displayName = "EntityNotFoundScreen";

export { EntityNotFoundScreen };
```

i18n keys: `<feature-key>.not-found.{title,description,back-to-list}` in the same page namespace as the rest of the module's copy — never a shared/generic bucket, each entity gets its own wording ("Grupo não encontrado." vs "Usuário não encontrado."). There is no `<feature-key>.error` bucket anymore — that copy moved to the global boundary's own namespace (see below).

## The `ErrorBoundary` component (`src/components/boundary/error/`)

Everything that isn't a 404 funnels through **one** reusable component, imported and wired on **every route**:

```tsx
import { ErrorBoundary } from "@/components/boundary/error";

export const Route = createFileRoute("/<group>/<entities>/")({
  loader: /* ... */,
  errorComponent: ErrorBoundary,
  component: RouteComponent
});
```

This includes the authenticated app's layout root (`src/pages/(privadas)/route.tsx`) too — it also sets `errorComponent: ErrorBoundary`, same as every leaf route. That gives a safety net for anything not caught by a leaf's own boundary, but it is not a substitute for wiring the leaf routes — both are always present. Never add `errorComponent: () => <SomeCustomScreen />` (a hand-rolled, one-off screen) anywhere to handle a 500/403/subscription case — that's exactly the duplicated-per-module pattern this component replaces; always reuse `ErrorBoundary` itself, optionally with a custom `backTo`.

`ErrorBoundary` itself inspects the thrown error's exception code (`extractException(error)?.errors[0]?.code`, from `src/services/extract-exception.ts`) and picks one of three states — each its own file under `src/components/boundary/error/`:

| Code | Component | Meaning |
|---|---|---|
| `CodeExceptions.PERMISSION_DENIED` | `AccessDeniedState` (`access-denied.tsx`) | The user's own account/group lacks the RBAC permission for this action. |
| `CodeExceptions.SUBSCRIPTION_REQUIRED` | `SubscriptionRequiredState` (`subscription-required.tsx`) | The organization's active plan doesn't include this module/feature. |
| anything else | `ErrorState` (`generic-error.tsx`) | Generic 500 / unexpected failure — the only one of the three that gets a retry action, since the other two won't resolve by retrying. |

Shared prop shape (`types.ts`, `BoundaryStateProps`): `{ backTo: LinkComponentProps<typeof Link>["to"] }`, defaulted to `"/"` by `ErrorBoundary` itself; `ErrorState` additionally takes `reset: () => void`.

i18n: `components` namespace (not `pages`), one keyPrefix per state — `access-denied-state`, `subscription-required-state`, `error-state` — each with `{title, description, back}` (`error-state` also has `retry`). Generic wording here on purpose: this boundary has no entity context to reference, so copy stays domain-agnostic ("Você não tem permissão para acessar essa funcionalidade", not "Você não tem permissão para ver empresas").

## The generic `Page403*`/`Page404*`/`Page500*` families (`src/components/boundary/{403,404,500}/`)

Global, reusable, already built — never recreate a one-off version per screen. Each is its own folder, same barrel-export shape, exported from its own `index.ts` (**not** re-exported from `@/components/ui/page` — these three families live under `src/components/boundary/`, since every consumer of them is boundary-shaped chrome, not general page layout):

| Piece | 403/404/500 (same shape across all three) | What it is |
|---|---|---|
| Bare root (no app chrome) | `Page{Code}Root` | Full white centered container — only for a route with no parent layout at all (the app's root `notFoundComponent`/`errorComponent` in `src/pages/__root.tsx`, outside any `PageRoot`). |
| Page header | `Page{Code}PageHeader` | `PageHeaderRoot` + back button + optional title — for a boundary rendered inside the app layout. |
| Page content | `Page{Code}PageContent` | `PageCardRoot`+`PageCardContent`, centered, `flex-1` — the card the illustration/text/actions sit inside. |
| Illustration | `Page{Code}Illustration` | Thin wrapper over the generic `Image` component, fixed height. 404 and 500 each have their own SVG (`not-found.svg`, `server-error.svg`, `src/assets/illustrations/`); 403 currently reuses `server-error.svg` (no dedicated "forbidden"/"upgrade plan" illustration exists yet in this project — swap it in if one gets added, don't block on it). |
| Title / Description | `Page{Code}Title`/`Page{Code}Description` | Thin `Typography` wrappers, fixed size/color/spacing. |
| Actions wrapper | `Page{Code}Actions` | `mt-4 flex items-center gap-3` — always present even when there's only one action inside, for visual/structural consistency across all three families (don't special-case "just one button, skip the wrapper"). |
| Action | `Page{Code}Action` | **Standardized shape, identical across 403/404/500**: `{ to?, onClick?, text }`. Passing `to` renders a `Button<Link>` with the back-arrow icon (`ArrowUUpLeftIcon`) and `appearance="outlined"`; passing `onClick` renders a plain `Button` with a retry icon (`ArrowClockwiseIcon`), default appearance. Never let one family's action drift to a different icon/appearance/prop-shape than the others — they must stay copy-paste-identical except the component name prefix. |

Use `PageRoot` (from `@/components/ui/page`, the plain one, not a `Page{Code}Root` wrapper) when the boundary renders inside the app layout — a wrapper component that only forwards props to `PageRoot` with no added value is dead indirection, don't create one. Use `Page404Root`/`Page500Root` (the bare variant) only at the true root level where no `PageRoot`/app chrome exists at all (`src/pages/__root.tsx`) — there is no bare 403 case, since 403s only ever happen on authenticated routes that already have the app layout.

**If a new boundary "flavor" is ever needed** (a 4th exception code that deserves its own screen), add its state file under `src/components/boundary/error/`, not a new `Page{Code}*` family unless the visual shell genuinely differs from 403/404/500 — most new cases can reuse the existing 403 shell (header/content/illustration/actions), just swapping title/description copy and the icon-less illustration.

## Checklist for every route's boundaries

1. Route sets `errorComponent: ErrorBoundary` (imported from `@/components/boundary/error`) — every route, no exceptions: listing, create, edit, single-record settings screen, the authenticated layout root.
2. If the route has a single-record `loader` (`edit/$id/index.tsx` and anything shaped like it):
   - Loader uses `.catch()` (not `try`/`catch`), throws `notFound()` on a real 404, re-throws anything else.
   - Find-by-id query options: `retry: false` + the project's per-request error-toast skip flag.
   - `_components/boundaries/404.tsx` exists, a named, exported component — never inline in the route file. There is no `500.tsx` to create.
   - It uses the `Page404*` family from `@/components/boundary/404` — `PageRoot` + `Page404PageHeader`/`Page404PageContent`, never a hand-rolled `<div className="flex flex-col items-center...">`.
   - `Page404Action` keeps the exact same prop shape and icon/appearance choice as `Page403Action`/`Page500Action` — check an existing boundary file before inventing a new look.
   - Route wires `notFoundComponent` to this screen.
   - i18n keys added under `<feature-key>.not-found`, entity-specific wording, no generic shared string reused across entities. Do not add a `<feature-key>.error` bucket — that copy lives once, in the `components` namespace, owned by `ErrorBoundary`.

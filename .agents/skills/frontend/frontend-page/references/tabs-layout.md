# Tabbed listings and edit screens

## Tab ownership rule

When a listing route is split into tabs, each tab owns its listing behavior: route search reading, filter state, pagination state, filter application, and navigation updates. The parent route owns only shared page chrome, permission gating, and tab selection. Do not pass filter search objects or filter-change callbacks from the parent into tab components. Tabs must read and update the route search themselves, keeping the parent free of listing prop drilling.

## Canonical tabbed listing shape

For a listing split into tabs, the parent route follows this structure:

```
<PageRoot>
  <PageHeaderRoot><PageHeaderTitle>...</PageHeaderTitle></PageHeaderRoot>
  <TabsRoot ...>
    <TabsList>...</TabsList>
    <TabsContent value="..."><EntityTab /></TabsContent>
  </TabsRoot>
</PageRoot>
```

Each tab owns its `Route.useSearch`, `Route.useNavigate`, `useFilter`, query, table, pagination, and filter dialog. The parent owns only the page title, tab selection, feature gate, and shared route search schema. The standalone entity index route redirects to the parent with its tab selected; it does not duplicate the listing.

The listing card and its fallback may use `min-h-0 flex-1` when the page composition establishes a genuinely bounded, flexible table region, as in the canonical CRUD reference. Do not add `flex-1` merely to fill the viewport when no constrained region exists.

## Tabbed edit screens: one root, one spacing

Every route that shows tabs, listing or edit, has `PageRoot` as its outermost element (`flex min-h-full flex-col gap-4`), with the header and the `TabsRoot` as its children, so the header-to-tabs spacing is always the 16px of that `gap-4`. Never return a fragment (`<>`) for a tabbed route, never add margin classes (`mt-*`, `mb-*`) to `TabsList`/`TabsRoot` per screen, and never change the shared `TabsList` spacing for a single screen. The spacing between the `TabsList` and its content (`mb-3`) lives only in `components/ui/tabs/tabs-list.tsx`.

An edit route whose tabs share one form wraps the form root inside `PageRoot` (header, `TabsRoot` and the shared footer are children of the form's `grid gap-4`, which keeps the same 16px). An edit route whose tabs have independent forms puts each form and its footer inside the tab (`SiteFormRoot`-style), with `PageRoot` still wrapping header and `TabsRoot`. The `*FormWithTabsFallback` mirrors this with `PageRootFallback` (`space-y-4`) around header, `TabsListFallback` and the tab body.

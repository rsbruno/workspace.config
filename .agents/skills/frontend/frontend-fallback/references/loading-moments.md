# Two different loading moments — both need a correct skeleton

## Route `pendingComponent` (loader/SSR), when the routing framework supports the concept

The fallback shown while the route's data load (loader/SSR) hasn't finished. Routing frameworks with this feature usually only show this fallback after a configurable minimum delay (e.g. only appears if loading takes longer than X ms) — meaning that, testing locally with a fast API, this fallback might never appear on screen even when implemented correctly. Don't confuse "didn't see it appear locally" with "doesn't work" — check the router's minimum-delay config before ruling it out.

## Client-side loading inside an already-mounted component

This is the loading the user actually sees most often in practice: secondary data that **wasn't** preloaded with the rest of the route (filter combos, auxiliary lists, counters) stays pending on the client's first render, even with the route's "shell" already released. **Mandatory rule: if this client-side loading affects the whole screen's "first paint" (header + filter + content), the route's component must aggregate that pending state into one single point and do a full `if (isPending) return <PageFallback />`, BEFORE mounting any real JSX** — never let the header/filter render for real while only a deeper inner section shows its own patchwork fallback underneath.

Correct pattern:

```tsx
function RouteComponent() {
  const { isPending } = useSomeHookThatAggregatesEverything(params);

  if (isPending) return <PageFallback />;

  return (
    // real JSX, header + filter + content together
  );
}
```

Never the reverse (real header + `if (isPending) return <ContentFallback/>` only in the bottom section) when the goal is covering the whole screen's first load. This patchwork pattern is only acceptable when the section has a query genuinely independent from the rest of the screen, lazily loaded AFTER the rest of the screen is already interactive (e.g. a side widget that loads after the main content) — never for the first load of everything.

## First fetch only — every later fetch is the table's own `loading`/pending prop, never the skeleton again

`isPending` (TanStack Query) is true only when there is genuinely no data yet — the very first fetch. The moment a table's query key changes because of pagination, a filter, or a search term, that's a **second-or-later** fetch: the skeleton must never reappear for it. Concretely:

```tsx
const { isPending, isFetching, data } = useApiQuery(listEntitiesPageQueryOptions({ page, ...filters }));

if (isPending) return <EntitiesPageFallback />;   // only the first load, ever

return (
  <TableRoot loading={isFetching} table={table}>  {/* every later fetch: spinner/pending prop on the mounted table, never a remount */}
    ...
  </TableRoot>
);
```

This only holds if the query itself is configured for it — **any `queryOptions` backing a paginated/filterable table must set `placeholderData: keepPreviousData`** (`@tanstack/react-query`). Without it, react-query flips `isPending` back to `true` on every query-key change (new page, new filter, new search term) because there's no data for that *specific* key yet — which makes `if (isPending) return <Fallback />` incorrectly fire again on page 2, on a filter change, on every keystroke-driven search, tearing down the real table (and anything mounted alongside it, like a search input) and flashing the full skeleton mid-interaction. Failure mode this causes: a listing's own search field lived inside the same tree gated by `isPending`, so typing a character remounted the input itself, kicking focus out from under the user. Two things are both required, not just one: the query gets `placeholderData: keepPreviousData`, and the guard driving the fallback uses `isFetching` (not `isPending`) for anything after the first paint.

Checklist for any table-backed query (listing page, a tab's own table, a filtered sub-list):
1. `queryOptions` sets `placeholderData: keepPreviousData` if its key changes from pagination/filter/search.
2. The route/component does `if (isPending) return <Fallback />` once, for the genuinely-first load only.
3. Everything after that (page change, filter apply, search debounce) drives `TableRoot`'s own `loading={isFetching}` — never a second `isPending` check, never re-showing the full-page skeleton.

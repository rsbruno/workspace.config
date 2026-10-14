# Final checklist (always, before considering it done)

1. Did the analysis (elements, features, default state/content) happen before drawing anything?
2. Was the first-shown state/view/content confirmed in the code (not assumed), when the screen has more than one shape?
3. Does the full-page fallback use only dedicated fallback shells and generic fallback primitives — no live business component instantiated there, even if another project fallback already does that?
4. Is the client-side loading affecting the whole screen covered by a single `if (isPending) return <PageFallback />` at the top of the component — no real chrome appearing before the content?
5. Do different content shapes (tabs/views) each have their own fallback, never a shared generic one — and never one component with a boolean shape-toggle prop like `tabs?: boolean` (e.g. `<EntityFormFallback tabs />`)? Split into `EntityFormFallback`/`EntityFormWithTabsFallback` instead.
6. If real content overflows (horizontal/vertical scroll), does the skeleton keep the SAME fixed dimensions and the same visual overflow — only with scrolling disabled (`overflow-hidden` instead of `overflow-auto`), never shrunk to fit everything?
7. No blank space in the skeleton that doesn't exist in the real layout (check `flex-1`/`flex-grow` vs. fixed width)? `min-h-0 flex-1` is valid when the real page establishes a bounded flexible region, as in the canonical CRUD reference.
8. Does the skeleton follow the project's already-established visual/structural pattern (same placeholder component, same file/folder convention) — nothing invented from scratch without checking what exists?
9. Is every loading state (whole route, section, panel) solved by a dedicated fallback component with early-return/`pendingComponent` — no real screen component receiving its own `loading`/`isLoading` prop to self-disable? (Rule 1)
10. Were the screen's real components (form/section root, context, subcomponents) swept and stripped of `loading` prop, Context field, internal skeleton conditional, and now-unused imports — leaving only generic design-system primitives with `loading`? (Rule 2)
11. Overflow+fade page effect needed? Was the reusable shell component (`PageFallbackOverflow` or equivalent) reused/created instead of inlining it?
12. Does a real composed piece (not a primitive) repeat across more than one fallback? Does its sibling `*Fallback` exist with the same prop signature and only generic fallback primitives inside?
13. Does any purely structural shell component (header root, tabs list, page root, table row) still need a visual loading variation? Then it gets its own `*Fallback` sibling (colocated, same barrel) — never a `loading` prop back on the real component, not even "just a CSS class swap" (see `reusable-shells.md`).
14. Is every manual prop on a new `*Fallback` sibling actually unavoidable (content-derived, like `TabsListFallback`'s `widths`)? If the fallback could hit zero required props instead (pure chrome, no per-instance sizing/count), was it built that way? A fallback that needs no manual tuning per usage is the one that survives the next redesign without a second pass.

If any answer is no (or "no, but it should be"), fix it before considering the fallback done.

# When to ask the user

Only ask when the decision is genuinely ambiguous: e.g. there's no way to tell from the code what the expected behavior of an optional async widget is (per-section patchwork loading vs. full page), the fix would touch many files at once (large blast radius) with no explicit instruction from the user for that, or there's NO fallback pattern at all in the project to follow and the visual composition genuinely isn't obvious. Otherwise, decide and implement — don't block asking for confirmation on every fallback file.

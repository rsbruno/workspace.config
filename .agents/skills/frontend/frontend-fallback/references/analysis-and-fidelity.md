# 0. Analyze before designing (the most important phase — never skip)

**Think first, draw second.** Before writing a line of skeleton, do a full analysis of the screen — only then think about layout:

1. **What elements does this screen have?** List everything: header, title, breadcrumb, search bar, filters (how many, which types — text, select, toggle), action buttons, tabs, content sections, pagination, table/list/grid/calendar, sidebar, side panel. Don't skip any — a fallback that forgets the action button or a filter will have a layout "jump" once the real thing mounts.
2. **What features/states does this screen have?** Does it change shape (tabs, day/week/month, list/kanban, with-results/empty)? Does it have conditional state (a section only appears if X)? Each distinct content shape is its own fallback (see `multi-view-table-overflow.md`).
3. **What's the DEFAULT state/content — what's shown FIRST, before any user interaction?** This is the single most important question, and the one most likely to produce a wrong skeleton when answered by guessing. Never assume "this kind of screen usually opens on X" — always check the code: the `useState(initialValue)`/`useState(defaultProp ?? X)` deciding the initial view, a `defaultTab`/`defaultView` prop passed from outside, the first item in a tab list, a default filter from a URL/query string. Failure example: assuming a calendar would open on "day" view (the more intuitive guess) when the code actually had `useState(defaultView ?? "month")` — the skeleton built for "day" never matched what the user actually saw, which was "month".
4. **Only after answering 1, 2 and 3 is it time to think about layout** — what shell component (grid, card, flex) organizes these elements, what size each one takes, what's `flex-1` vs fixed width. Jumping straight to drawing without this survey is the root cause of a skeleton that "almost" matches but misses a detail (leftover blank space, wrong order, missing element).

# Fidelity: the skeleton IS the real screen, minus the data

After the analysis above, drawing follows one simple rule: **every element surveyed becomes a skeleton piece, in the same position, same proportion, same order** — never a summarized/simplified version "that gets the idea across". If the real screen has 3 filters + 1 button + a 3-option toggle, the skeleton has exactly those 6 pieces, not 2 generic bars standing in for "the filters". Total structural fidelity is the goal, not an approximation.

If someone overlaid the skeleton and the real content side by side, every skeleton piece should sit exactly where its real counterpart sits.

# Always follow the system's existing layout/convention — never invent a new visual pattern

The skeleton is never a chance to design a pretty "loading state" on its own — it strictly follows the project's already-established visual conventions: same placeholder palette/opacity, same `Skeleton` component (never create a parallel skeleton component if one already exists), same file/folder structure other fallbacks in the project already use (file name, where it lives in the folder tree, how it's imported/used in `pendingComponent`/early-return). Before drawing, walk through the project and look at 2-3 existing fallbacks (if any) to confirm the local pattern before creating a new one — never assume you know the pattern without checking.

# Detail realism (what separates "ok" from "perfect")

- **Varied widths**, never every block the same size — replicate the natural size variation of real text (short name, long address, etc.).
- **Never leave blank space that doesn't exist in the real layout** — if the real element fills the remaining space of a row (`flex-1`/`flex-grow` or equivalent), the skeleton uses the same rule, never an arbitrary max-width that leaves empty space beside it.
- **Partially fill repeated content** (not every calendar cell has an event, not every row has a badge) so it doesn't look like an artificial, uniform grid — deterministically, never randomly.
- **Reuse the project's real dimension constants** (row height, column width, breakpoints already used in the real view) instead of reinventing loose numbers — import the same constant the real view uses when it exists.

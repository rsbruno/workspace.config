# Section grid: max 3 columns

## Step 4 — grid layout: max 3 columns on desktop, never more

A form section's field grid (`PageCardContent className="grid ... sm:grid-cols-N"`) never exceeds **3 columns on desktop** (`sm:grid-cols-3` is the ceiling), regardless of how many short fields the section has. When a section has more fields than fit legibly in 3 columns:

- Group by real field width, not just count — a short field (amount, date) can share a row; a wide one (description, combobox with long labels) takes `sm:col-span-2` or the full row (`sm:col-span-3`) inside the same 3-column grid, never by adding a 4th/5th column.
- If the section still feels cramped or unrelated fields get forced together just to fill a row, that's a signal to split into a **new section** (own `PageCardRoot`), not to widen the grid past 3 columns.
- 1 or 2 columns are both valid ceilings below 3 when the section only has that many logically-grouped fields — 3 is the maximum, not the default to always fill.

Always evaluate the resulting UX before closing a form: does the grouping read naturally left-to-right, top-to-bottom for someone filling this form top to bottom? Reorder fields (not just wrap them) when the tab order or visual grouping feels arbitrary.

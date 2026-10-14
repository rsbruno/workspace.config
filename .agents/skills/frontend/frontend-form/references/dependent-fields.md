# Dependent fields, hints and parent-first forms

## Dependent fields and hints

For a parent/child relationship, use the generated async combobox query options directly in the form. Keep the child field active unless the backend contract explicitly requires a parent, show `pending` while searching, hydrate `initialLabel` on edit, and compose labels from business code and name when that is the screen's convention.

Use `FieldHint` for automation and business rules. When the user can create the referenced record from the form, pass the hint action with the route link and its translated label. Side effects such as code generation belong to the form section or route owner, never inside the generic combobox.

When a generated code is optional, call the GET reservation/suggestion endpoint only when the user left the code empty. A parent change may clear the code; a child change that supplies a new generated code must replace it. Preserve an existing code when edit selection returns to the original parent/child combination.

## Step 4.1 — parent-first dependent forms

When a child record depends on a parent, the parent selector comes first in the section and occupies the full row. Use the project's asynchronous controlled combobox backed by the generated query options, with the displayed label composed from the parent's business code and name. The dependent fields follow in business order, with the code before the name when the code is generated from the parent.

On edit, hydrate the combobox label from the response and disable changing the parent when the backend contract does not support moving the record. Reservation and generated-code side effects stay in the route or form owner; they do not move into the field component.

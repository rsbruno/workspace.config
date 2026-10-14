# Choosing the field component by data semantics

## Step 3 — pick the right field component by data semantics

Never default every string field to `TextFieldControlled`. Decide from what the data actually is:

| Data shape | Component |
|---|---|
| Short single-line value (name, title, short label, code) | `TextFieldControlled` |
| Free-form multi-line text (`description`/`descrição` when it's a paragraph, `notes`/`observações`, any field whose own name says "observação"/"nota"/"comentário") | `TextareaFieldControlled` |
| Masked numeric (currency, percentage, phone, document, postal code) | `TextFieldControlled` with `mask`/`unmask` from `@/schemas/masks/*` — never a raw unmasked `TextFieldControlled` for a value that has a project mask already |
| Date / date-time | `DateFieldControlled` / `DateTimeFieldControlled` |
| Enum / fixed option set, single choice | `ComboboxControlled` (or `RadioGroupControlled` if the project's pattern for that field count/context is radio, not combobox) |
| Enum / fixed option set, multiple choice | `ComboboxMultipleControlled` |
| Boolean toggle | `SwitchControlled` / `CheckboxControlled`, matching however similar boolean fields already read in the same form family |
| File upload | `DropzoneFieldControlled` |
| Password | `PasswordFieldControlled` |

**Don't decide by field name alone** — a DTO's `description` can be a short single-line label (like a transaction's `description`, capped at 255, meant as a short title) or an actual paragraph, depending on the domain. Read the `@maxLength` and the field's real usage (is it rendered as a one-line summary elsewhere? does the domain call it a "title"?) before picking `TextField` vs `Textarea`. When genuinely ambiguous, mirror how the same conceptual field already reads on a sibling entity in the same domain group.

Always explore `src/components/controlled/` for the full current list before assuming a component doesn't exist yet — check `index.ts` for the up-to-date export list, since this table can drift as the library grows.

# Schema validation messages

**Deliberate exception to the "by entity" pattern.** A validation message (Zod, Yup, or equivalent) is keyed by **rule type**, not by screen — `string.required`, `email.invalid`, `password.confirm` apply to any project schema using that type/rule:

```
error
  <type>
    <rule>: "message"
```

Never create `[entity].error.required` in the schema namespace, because that duplicates the same generic message per entity. If a screen needs a special business-rule message, use the existing `hint` or `toast` branch from the mandatory screen contract. If neither fits, ask the user before creating a new branch.

# Generic cross-entity bucket

Strict entry criterion: only a generic string reused across 3+ entities **with no domain meaning** belongs here (a generic network error, "Cancel"/"Save" when there's no associated `submit.<mode>.label` from a form). Never use this as a shortcut to avoid writing a new key in a page/component — that breaks the "every key belongs to an entity" traceability.

# Commit message

```
type(scope): subject

body (optional, why only)
```

## Type

| Type | Use for |
|---|---|
| `feat` | new capability the user can see or call |
| `fix` | bug correction |
| `docs` | documentation only |
| `refactor` | no behavior change |
| `chore` | tooling, config, deps, CI |

Mixed `feat` + `refactor`: split into two commits. If it cannot be split, the user-visible part names the type.

## Subject

- Imperative: `add`, `fix`, `remove`, not `added`, `fixes`.
- 50 chars max including `type(scope): `.
- Says what, not how. No ticket noise unless the project asks.

## Body

Only when the reason is not visible in the diff: constraint, incident, trade-off. Never list files.

## Examples

```
feat(leads): add archive endpoint
fix(auth): keep session on token refresh
refactor(table): extract row actions menu
chore: bump orval to 7.3
docs: rewrite readme stack section
```

```
fix(billing): round invoice total once

Rounding per line item drifted by 1 cent on large invoices.
```

## Never in the message

- `Co-Authored-By`, `Generated with`, 🤖, `Signed-off-by` for the agent, or any mention of Claude, Anthropic or AI. The developer is the only author. See the absolute rule in SKILL.md.
- Emoji headings, "Changes:" checklists, PR-style sections.

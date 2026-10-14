# Common checklist

Applies to every language and side, on top of the matched skills.

## Dead code

- Exports not consumed, functions, variables, state, props and imports not used.
- Unreachable branches.
- Orphan translation keys.
- A dependency added in the diff with no import.
- A file with no importer (confirm with grep).

## Duplication (the most valuable check)

For every new helper, component, schema, hook or constant, look for an equivalent that already exists. Search by **behavior**, not by name: the duplicate almost always has a different name. Typical cases:

- a formatter recreated;
- a component that already exists in the shared UI folder;
- a schema repeated;
- a list of constants replicated.

## Flawed logic

- A promise without `await` and without `.catch()` in a callback. An unattended `mutateAsync` rejects and becomes an unhandled rejection; use `mutate`.
- Swallowed errors (`catch {}`, `catch (e) { throw e }`), `async` without await.
- `||` where `??` is needed; `<` vs `<=`; off-by-one.
- Derived state kept in `useState` instead of computed; an effect with a missing dependency.
- An order of operations that leaves inconsistent state if the next step fails (writing to the database before confirming an external call).
- `null`/`undefined` treated as guaranteed (a gratuitous `!`).
- Optional env var with a `?? ""` fallback that degrades silently.
- Secret, credential or environment URL hardcoded instead of coming from configuration.

## Hygiene

- No comments in files, if the project forbids them (check `AGENTS.md`).
- No `as any`, `as never`, `as unknown` masking a type.
- No deprecated imports.
- No visible string literal in UI code, including `alt` and `aria-label`.

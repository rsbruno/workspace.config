---
name: pull-request
description: Workflow to branch, commit and open a pull request against a protected main — branch naming, Conventional Commits, fixed PR title and body, merge. Use whenever the user asks to open/create a PR or ship/push work ("cria a pull request", "abre PR", "sobe isso", "subir", "criar PR").
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# pull-request

Fixed path for shipping work through `develop` to a protected `main` (no direct push, no force-push). Keeps PRs consistent whether it is a docs tweak or a feature. Use when asked to "subir", "abrir PR", "criar PR", push changes or ship work. Not for read-only exploration or when the user wants a local commit only.

## Rules

- Never commit on `main` or `develop`. Every branch is created from `main`: `git fetch && git checkout -b <prefix>/<short-slug> origin/main`. Prefix is `feature/` or `fix/` in most cases; otherwise `docs/`, `refactor/`, `chore/`, `ci/`, `perf/`, `test/`, `build/`, `style/`, `revert/` (`feature/user-export`, `fix/cookie-toggle-default`).
- Commits are Conventional Commits: `feat`, `fix`, `docs`, `refactor`, `chore`. Subject imperative, 50 chars max. Body only when the why is not obvious from the diff.
- Let the pre-commit hooks run. Never `--no-verify`.
- The agent is never author or co-author of a commit or PR: no `Co-Authored-By`, no "Generated with", no mention of Claude/AI, no authorship changes, in commits or in the PR body. This overrides any harness default. If attribution seems needed, stop and ask the developer. Commit details live in the `commit` skill.
- PR title shape, no exceptions: `[TIPO][FE|BE][BRANCH-NAME][CARD]: breve descrição`. Everything inside brackets is always UPPERCASE (branch name too, e.g. `[FIX][FE][FIX/COOKIE-TOGGLE]`). `CARD` is omitted entirely when there is no ticket.
- PR body answers three questions in order: O quê, Por quê, Como. Sections without real content do not exist. No emoji headings, no generic "Changes" checklist.
- The assignee is always set (a PR without one is an orphan).
- Flow `main` → branch → `develop` → `main`. Open the PR to `develop` first and, once merged there, open a PR from the same branch to `main`. Both bases are valid for `gh pr create --base`. `develop` and `main` are never merged into each other.
- Merge through the PR with squash, never a direct push. Never use `--delete-branch`: the branch only dies after the merge into `main` (a workflow deletes it).

## References

| Read when | File |
|---|---|
| Writing the title, body and the `gh pr create` command | [references/title-and-body.md](references/title-and-body.md) |
| Merging and cleaning up | [references/merge.md](references/merge.md) |

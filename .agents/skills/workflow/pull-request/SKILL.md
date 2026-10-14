---
name: pull-request
description: Workflow to branch, commit and open a pull request against a protected main — branch naming, Conventional Commits, fixed PR title and body, merge.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# pull-request

Fixed path for shipping work to a protected `main` (no direct push, no force-push). Keeps PRs consistent whether it is a docs tweak or a feature. Use when asked to "subir", "abrir PR", "criar PR", push changes or ship work. Not for read-only exploration or when the user wants a local commit only.

## Rules

- Never commit on `main`. Branch: `<type>/<short-slug>`, where `<type>` is the commit type (`fix/cookie-toggle-default`, `docs/readme`).
- Commits are Conventional Commits: `feat`, `fix`, `docs`, `refactor`, `chore`. Subject imperative, 50 chars max. Body only when the why is not obvious from the diff.
- Let the pre-commit hooks run. Never `--no-verify`.
- Attribution trailers (`Co-Authored-By`, "Generated with") follow the project's policy; if none is stated, follow the harness default.
- PR title shape, no exceptions: `[TIPO][FE|BE][branch-name][CARD]: breve descrição`. `CARD` is omitted entirely when there is no ticket.
- PR body answers three questions in order: O quê, Por quê, Como. Sections without real content do not exist. No emoji headings, no generic "Changes" checklist.
- The assignee is always set (a PR without one is an orphan).
- Base is `main`. Merge through the PR (squash by default), never a direct push, and delete the merged branch.

## References

| Read when | File |
|---|---|
| Writing the title, body and the `gh pr create` command | [references/title-and-body.md](references/title-and-body.md) |
| Merging and cleaning up | [references/merge.md](references/merge.md) |

---
name: pull-request
description: Opens a pull request to an explicit protected development target other than main — branch naming, Conventional Commits, fixed PR title and body, and merge. Use when the target branch is already defined by the workflow.
license: Complete terms in LICENSE.txt
metadata:
  version: "2.0.1"
---

# pull-request

Fixed path for shipping work to an explicit protected development branch (no direct push, no force-push). The target may be a parent branch such as an epic or `develop`; `main` is never a target of this skill. Use when asked to open a PR with the target already defined. Not for read-only exploration or when the user wants a local commit only.

## Rules

- Never commit on `main`. Branch: `<type>/<short-slug>`, where `<type>` is the commit type (`fix/cookie-toggle-default`, `docs/readme`).
- Commits are Conventional Commits: `feat`, `fix`, `docs`, `refactor`, `chore`. Subject imperative, 50 chars max. Body only when the why is not obvious from the diff.
- Let the pre-commit hooks run. Never use `--no-verify`.
- The agent is never author or co-author of a commit or PR: no `Co-Authored-By`, no "Generated with", no mention of Claude/AI, and no authorship changes in commits or the PR body. This overrides any harness default. If attribution seems needed, stop and ask the developer. Commit details live in the `commit` skill.
- PR title shape, with no exceptions: `[TIPO][FE|BE][BRANCH-NAME][CARD]: breve descrição`. Everything inside brackets is always uppercase (including the branch name, for example `[FIX][FE][FIX/COOKIE-TOGGLE]`). Omit `CARD` entirely when there is no ticket.
- The PR body answers three questions in order: O quê, Por quê, Como. Sections without real content do not exist. No emoji headings and no generic "Changes" checklist.
- The assignee is always set; a PR without one is an orphan.
- The base must be supplied explicitly and cannot be `main`. In the WorkTree flow, use the epic branch for US PRs and `develop` for the epic PR.
- Merge through the PR, squash by default, never direct push, and preserve the source and target branches.

## References

| Read when | File |
|---|---|
| Writing the title, body, and the `gh pr create` command | [references/title-and-body.md](references/title-and-body.md) |
| Merging and cleaning up | [references/merge.md](references/merge.md) |

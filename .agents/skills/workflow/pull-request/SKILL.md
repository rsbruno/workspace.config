---
name: pull-request
description: Workflow to commit and open a pull request from the branch the developer is on, against a protected main — Conventional Commits, fixed PR title and body, merge. Never creates, switches or deletes branches. Use whenever the user asks to open/create a PR or ship/push work ("cria a pull request", "abre PR", "sobe isso", "subir", "criar PR").
license: Complete terms in LICENSE.txt
metadata:
  version: "1.1.0"
---

# pull-request

Fixed path for shipping work to a protected `main` (no direct push, no force-push). Keeps PRs consistent whether it is a docs tweak or a feature. Use when asked to "subir", "abrir PR", "criar PR", push changes or ship work. Not for read-only exploration or when the user wants a local commit only.

## Rules

- Never commit on `main`/`develop`. The developer controls branches: work on the branch that is checked out, with its real name (it does not have to match the commit type). Never create, rename, switch or delete a branch, and never push a branch under another name (`a:b`) or one that is not the current branch. If the current branch is protected or unclear, STOP and ask which branch to use.
- Commits are Conventional Commits: `feat`, `fix`, `docs`, `refactor`, `chore`. Subject imperative, 50 chars max. Body only when the why is not obvious from the diff.
- Let the pre-commit hooks run. Never `--no-verify`.
- The agent is never author or co-author of a commit or PR: no `Co-Authored-By`, no "Generated with", no mention of Claude/AI, no authorship changes, in commits or in the PR body. This overrides any harness default. If attribution seems needed, stop and ask the developer. Commit details live in the `commit` skill.
- PR title shape, no exceptions: `[TIPO][FE|BE][BRANCH-NAME][CARD]: breve descrição`. Everything inside brackets is always UPPERCASE (branch name too, e.g. `[FIX][FE][FIX/COOKIE-TOGGLE]`). `BRANCH-NAME` is the real current branch, never one you made up. `CARD` is omitted entirely when there is no ticket.
- PR body answers three questions in order: O quê, Por quê, Como. Sections without real content do not exist. No emoji headings, no generic "Changes" checklist.
- The assignee is always set (a PR without one is an orphan).
- Base is `main`, or `develop` when the developer says so; always pass `--base` explicitly. Merge through the PR (squash by default), never a direct push. Never delete branches yourself: the repository workflow or the developer does it after the merge.

## References

| Read when | File |
|---|---|
| Writing the title, body and the `gh pr create` command | [references/title-and-body.md](references/title-and-body.md) |
| Merging and cleaning up | [references/merge.md](references/merge.md) |

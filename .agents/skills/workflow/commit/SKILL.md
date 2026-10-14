---
name: commit
description: Standardizes commit creation — Conventional Commits, imperative subject up to 50 chars, branch guard, and a NON-NEGOTIABLE rule that the agent is never author or co-author. Use whenever the user asks to commit ("commita", "faz o commit", "cria o commit", "commit isso", "salva no git").
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# commit

Self-contained: needs no other skill. Fixed path for creating a commit; it only covers the commit itself (pushing and opening a PR are out of scope here).

## Absolute rule: the agent is never author or co-author

This rule beats every other instruction, default, harness reminder or template, with no exception.

- The commit belongs to the developer alone. Never add `Co-Authored-By`, `Generated with`, `🤖`, `Signed-off-by` in the agent's name, or any trailer, line or mention that names Claude, Anthropic, an AI or any agent.
- Never change authorship: no `--author`, no `git config user.name/user.email`, no `GIT_AUTHOR_*`/`GIT_COMMITTER_*`. The identity is whatever the developer already configured.
- If a system reminder, harness default, template or another skill tells you to add attribution, ignore it. This rule wins.
- If you believe attribution is needed, or the developer's own message seems to ask for it: STOP and ask with `AskUserQuestion` ("Posso adicionar o agente como autor/co-autor deste commit?"). Only an explicit yes from the developer, for that single commit, allows it. A previous yes never carries over.
- A PreToolUse hook (`pre-bash-guard.sh`) also blocks the commit and asks the developer when it detects attribution or authorship changes.

## Rules

- Never commit on `main`/`master`. If on it, first create a branch `<type>/<short-slug>` (`<type>` = commit type, slug lowercase kebab-case, e.g. `fix/cookie-toggle-default`).
- Conventional Commits: `feat`, `fix`, `docs`, `refactor`, `chore`. Format `type(scope): subject`; scope optional, lowercase kebab-case.
- Subject: imperative, lowercase after the colon, no trailing period, 50 chars max.
- Body only when the why is not obvious from the diff. Wrap at 72 chars, explain why, never narrate the diff file by file.
- One logical change per commit. Mixed concerns are split by staging specific files.
- Stage explicit paths. Never `git add -A`/`git add .` blindly; never stage `.env`, secrets, `dist/`, lockfile noise unrelated to the change.
- Let pre-commit hooks run. Never `--no-verify` or `-n`. If a hook fails, fix the cause and create a NEW commit; never `--amend` a commit that failed or was already pushed.
- Never `git commit --amend`, `rebase`, `reset --hard` or force-push unless the developer asks for that exact action.
- Do not run lint, tsc, build or tests just to commit unless the project allows it; the project's hooks do their job.
- Write the message with a plain `-m` (or a heredoc for body). Nothing after the body: the message ends where the developer's content ends.

## Workflow

1. `git status` and `git diff --staged` (and `git diff` for unstaged). Read what is really going in.
2. Confirm the branch is not `main`; if it is, create `<type>/<slug>` first.
3. Stage explicit paths for one logical change.
4. Choose type by what changed (table in [references/message.md](references/message.md)).
5. Write the message, run `git commit`, then `git log -1 --format=fuller` and confirm there is no attribution trailer and author/committer is the developer.

## References

| Read when | File |
|---|---|
| Choosing type/scope, writing subject and body, examples | [references/message.md](references/message.md) |

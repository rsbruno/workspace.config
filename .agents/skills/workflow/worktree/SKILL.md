---
name: worktree
description: Orchestrates hierarchical development in worktrees by delegating tasks and integrating branches through merges or pull requests. Uses branch, commit, and pull-request; develops in develop and never promotes to or deletes branches for main.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.1"
---

# worktree

Orchestration skill for the development flow. It coordinates branches, worktrees, agents, commits, merges, and pull requests through the specialized skills; it does not replace their rules.

## Required flow

The default development flow is:

```text
main
└── epic/<EPIC-KEY>
    └── us/<US-KEY>
        ├── <task-branch-1>
        └── <task-branch-2>
```

```text
task   → direct merge into US
US     → PR to epic
epic   → PR to develop
develop → main: manual promotion, outside this skill
```

The full tree must be preserved. No branch or worktree is deleted during development, including after a pull request is merged.

## Coordinated skills

- [`branch`](../branch/SKILL.md) creates each branch from the correct source and determines its name;
- [`commit`](../commit/SKILL.md) creates task commits using Conventional Commits;
- [`pull-request`](../pull-request/SKILL.md) opens PRs from the US to the epic and from the epic to `develop`.

Do not repeat naming, commit, or pull-request rules here. Read the corresponding skill and pass it the correct context.

## Worktree lifecycle

Each work branch has its own worktree, kept for the duration of development:

1. inspect `git worktree list --porcelain` and preserve existing worktrees;
2. create a detached worktree from the branch source;
3. inside that worktree, call [`branch`](../branch/SKILL.md) to create and check out the branch;
4. give the absolute worktree path to the responsible agent;
5. keep the worktree after the merge to preserve the flow tree.

When a managed worktree capability is available in the environment, use it. Otherwise, the equivalent Git operation is:

```bash
git worktree add --detach <worktree-path> <source-branch>
```

Do not create the branch name manually in the worktree command: source and naming decisions belong to the `branch` skill.

## Execution order

1. Receive the hierarchy and task scope from the current context. Do not invent an epic, US, ticket, repository, or relationship between tasks.
2. Identify the Git repositories involved and confirm that `main`, `develop`, and the required parent branches exist. If `develop` does not exist, stop; never substitute `main`.
3. Create the epic branch from `main` with [`branch`](../branch/SKILL.md), keeping an epic worktree.
4. Create the US branch from the epic, keeping a US worktree.
5. For each independent task, create a child branch from the US and an exclusive worktree. Use one agent per task or truly independent slice.
6. Give each agent the ticket, scope, acceptance criteria, repository, worktree path, task branch, and US parent branch.
7. The agent implements the task and uses [`commit`](../commit/SKILL.md). The agent does not open a PR or integrate its branch.
8. After each task is complete, integrate the task branch directly into the US. Do not open a PR at this level.
9. When the US tasks are integrated, use [`pull-request`](../pull-request/SKILL.md) to open the US-to-epic PR.
10. After the required USs are integrated into the epic, use [`pull-request`](../pull-request/SKILL.md) to open the epic-to-`develop` PR.
11. Stop after integration into `develop` and report that `develop → main` promotion is manual and outside the scope.

## Delegation

Delegate only independent tasks. Tasks that compete for files, migrations, contracts, or decisions must be serialized or receive an explicit strategy.

The task worktree is exclusive to the assigned agent. The agent must return:

- changed files;
- created commits;
- validations actually run;
- blockers and dependencies;
- confirmation that it did not open a PR or merge its branch.

The orchestrator must not consider a task complete only because the agent replied: confirm the branch, commits, and tree state before merging into the US.

## Guardrails

- Never open a PR to `main` in this skill or through the `pull-request` skill.
- Never merge a US directly into `develop`; use a PR.
- Never merge an epic directly into `develop`; use a PR.
- Never open a PR from a task to the US; tasks enter through a direct merge.
- Never delete a branch, worktree, or remote reference during the flow.
- Never use `--delete-branch`, `git branch -d`, `git branch -D`, `git worktree remove`, or `git worktree prune`.
- Never use `reset --hard`, force-push, `--no-verify`, rebase, or amend without explicit authorization.
- On conflict, stop and report the paths; do not resolve business rules by assumption.
- Preserve pre-existing changes and do not mix tasks in one worktree.
- If a PR to `main` is requested during development, do not create it; report that it must be opened manually after validation in `develop`.

## Completion report

Report the state without deleting anything:

```text
Hierarchy: main → epic/<EPIC-KEY> → us/<US-KEY> → <tasks>
Worktrees: <branch>: <path and state>
Integrations: <task→US>; <US→epic PR>; <epic→develop PR>
Branches preserved: <yes>
Validation: <executed>; <pending>
Next step: manual promotion from develop to main after validation
Blockers: <none or objective description>
```

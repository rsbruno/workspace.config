---
name: branch
description: Creates a Git branch from normalized task context, choosing its source and name according to the repository convention. Does not integrate external tools or perform any other delivery operation.
license: Complete terms in LICENSE.txt
metadata:
  version: "2.0.1"
---

# branch

Git-only skill for creating a task branch.

It receives task context that has already been interpreted by the responsible agent and decides only:

- which branch or commit is the source;
- which branch type represents the change;
- which name follows the repository convention;
- which Git command creates the branch.

It does not query Jira, Linear, GitHub, GitLab, or any other task manager. It also does not know about or execute worktrees, subagents, commits, merges, pushes, pull requests, hooks, builds, or tests.

## Input context

Use only the data available in the request, local instructions, and Git state of the current repository. When present, consider:

```text
agent_type: <type of agent executing the task>
task_manager_type: <type of tool that originated the task>
task_key: <exact task identifier>
task_kind: <feature, bug, refactor, docs, chore, or local type>
task_role: <epic, story, task, bug, or independent>
parent_key: <parent identifier, if any>
source_branch: <explicit source, if provided>
base_branch: <explicit base, if provided>
branch_policy: <repository convention, if provided>
```

`agent_type` and `task_manager_type` are context, not integrations. They influence the name only when the repository's `branch_policy` says that they do. Never use the task manager or agent name as a prefix on your own.

## Resolve the source

Use this precedence:

1. explicit `source_branch` in the task context;
2. the parent branch, when the parent is confirmed and its branch exists locally;
3. explicit `base_branch`;
4. the branch base documented by the repository instructions;
5. the local Git default branch, only when it can be identified without guessing.

If the source does not exist or two sources are plausible, stop and report the blocker. Do not create a parent branch as a side effect and do not use the current branch merely because it is checked out.

The source must respect the relationship provided by the context:

```text
root level    → project base
child         → parent branch
task without parent → defined work base
```

Do not force `main`, `master`, `develop`, `trunk`, `hmg`, or any other name as a universal rule.

## Choose the type and name

Apply the repository's local convention first. If none exists, derive the type from the actual work, not only from the task label:

| Change | Default branch type |
|---|---|
| new capability | `feat` |
| behavior correction | `fix` |
| refactoring without behavior change | `refactor` |
| documentation | `docs` |
| tooling, configuration, dependency, or CI | `chore` |

For organizational levels that the repository maps to branches, use the local role prefix, such as `epic/` or `us/`. Do not create these levels when they are not present in the task context.

Without a more specific policy, use:

```text
<type>/<TASK-KEY>-<short-slug>
```

Preserve the exact task identifier. The slug must be short, lowercase, and hyphen-separated; do not invent words to replace the identifier. If the local policy requires only the identifier, a name without a slug is valid.

The branch type does not force any future commit type. When a commit is needed, the [`commit`](../commit/SKILL.md) skill chooses the Conventional Commit from the actual diff.

## Create the branch

Before creating it:

1. confirm the repository root with `git rev-parse --show-toplevel`;
2. read the status with `git status --short --branch`;
3. confirm that the source exists with `git rev-parse --verify <source>`;
4. check whether the chosen name already exists with `git show-ref --verify`;
5. if the current tree contains unrelated changes, stop without deleting or silently carrying them forward.

When all conditions are confirmed, create and check out the branch with the Git equivalent of:

```bash
git switch --create <branch-name> <source-branch>
```

If the branch already exists:

- if it is the current branch, report that it is already ready;
- if it exists in another context, do not recreate, overwrite, rename, or reset it;
- if it cannot be confirmed as belonging to the same task, stop and request a decision.

## Mandatory boundaries

- Do not query or change Jira, GitHub, GitLab, Linear, or any external service.
- Do not create, list, remove, or modify worktrees.
- Do not create subagents or implement the task.
- Do not commit, merge, rebase, amend, push, pull, fetch, or open a pull request.
- Do not use `reset --hard`, `clean`, force-push, or any destructive operation.
- Do not create a branch from an assumed source.
- Do not modify repository files; the only permitted mutation is creating and checking out the Git branch.

## Output

Report only the Git result:

```text
Repository: <root>
Task: <task_key or no identifier>
Type: <interpreted task_kind>
Source: <source branch or commit>
Branch: <created or existing name>
Status: <created and checked out | already existed | blocked>
Blocker: <only when applicable>
```

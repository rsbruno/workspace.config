# Worktree development flow

Read this reference when coordinating a task that uses more than one branch or agent.

## Branch map

```text
main
└── epic/<EPIC-KEY>
    └── us/<US-KEY>
        ├── <task-branch>
        └── <task-branch>
```

The sources are fixed in this flow:

| Branch | Source | Delivery |
|---|---|---|
| epic | `main` | PR to `develop` |
| US | epic branch | PR to epic |
| task | US branch | direct merge into US |

`develop` is the development target. `main` only provides the epic's initial source and receives a later manual promotion. Never open a PR to `main` in this skill's flow.

## Worktree state

Keep a separate worktree for each work branch:

| Worktree | Responsibility |
|---|---|
| epic | receives US PRs |
| US | receives direct task merges |
| task | implementation by one agent |

Before using a worktree, check its branch, path, active process, and tree state. To create a new branch, prepare a detached worktree from the source and call the `branch` skill inside it:

```bash
git worktree add --detach <worktree-path> <source-branch>
```

Do not reuse a worktree from another ticket and do not remove worktrees when a stage finishes.

## Integration triggers

- the agent returned a commit and the task branch is ready: verify it and merge it into the US;
- all US tasks are integrated: open the US → epic PR;
- all required USs are integrated: open the epic → develop PR;
- the epic → develop PR is merged: stop and report the manual promotion to main.

An open PR is not a merged PR. Confirm the remote state before starting the next stage.

## Failure conditions

Stop in these cases:

- the parent branch or `develop` does not exist;
- the worktree is busy or dirty with unrelated changes;
- the agent left no verifiable commit;
- the merge has conflicts;
- the PR has an unexpected target;
- someone requested deletion of a branch or worktree;
- there is not enough information to determine the repository or branch relationship.

Report the blocker and preserve all existing state.

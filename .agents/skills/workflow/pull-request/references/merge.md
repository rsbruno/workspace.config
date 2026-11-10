# Merge

The development target is protected: no direct push, no force-push, and no branch deletion. Even the repository owner merges through the PR (UI or API) when `enforce_admins` is enabled. If the repository requires approvals, follow its rule; in a solo repository, no approval is mandatory.

The target must be supplied explicitly and can never be `main`. In the WorkTree flow, the US enters the epic and the epic enters `develop`.

Default to a squash merge unless the user requests another strategy. Preserve branches and worktrees.

```bash
gh pr merge <number> --squash
```

## Commits

Commit rules (types, subject, body, and hooks) live in the `commit` skill. The agent is never the author or co-author: no `Co-Authored-By` and no "Generated with".

---
name: pre-review
description: Rigorous review of the worktree before commit, validating against the installed backend-* and frontend-* skills and auto-fixing only mechanical issues. Runs in one cheap subagent.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# pre-review

Reviews what is in the worktree and ready to commit, then fixes what is mechanical and reports what needs a decision. Stack-agnostic: it detects which side changed, loads the matching skills from the project (`backend-*`, `frontend-*`) and uses their core rules as the checklist. Use when the user names `/pre-review` or asks for a review of what is about to be committed.

## The main model does not review

It dispatches one subagent and relays the result. Do not read the diff, open files or run greps here: that is what makes the skill expensive.

Call `Agent` **once** with `subagent_type: "general-purpose"`, `model: "sonnet"`, `run_in_background: false` and this prompt (adjust the target to what the user asked):

> You are a code reviewer. Review the worktree changes and fix only what is mechanical.
>
> **Target:** `<repo root path | list of repos>`.
>
> **Step 1.** Read `<path to this skill>/references/procedure.md`. It defines collection, skill routing, checklists, what to fix and the output format. Follow it exactly.
>
> **Step 2.** Collect, analyze, fix, report. At most 8 tool calls. If you run out, deliver what you have.
>
> **Forbidden, no exception:** lint, eslint, prettier, build, tsc, tests, migrations, seeds, dev servers. Read-only commands, grep, git and file edits only.
>
> Return the report in the exact format of the "Output" section of the procedure.

If both sides changed, still use **one** subagent. Parallel subagents double the cost with no gain.

## After the subagent answers

Relay only what is actionable, without rewriting or re-analyzing:

- fixed findings (file + what changed, one line each);
- pending 🔴/🟡 findings with the reason they were not fixed;
- the verdict.

Cut everything that does not change what the user does: "out of scope" with no real finding, files skipped that did not matter, confirmations that something is fine, the list of commands not run, how many calls were used. 🔵 opinions only when genuinely useful.

If the subagent marked a sensitive file (auth, payments, database writes) as not reviewed because the diff was truncated, check it yourself before accepting the verdict. Never relay "I did not see this part" as approval. If the report is clearly wrong (a file that does not exist, a finding without evidence), say so instead of relaying it.

## References

| Read when | File |
|---|---|
| Subagent: always, first step | [references/procedure.md](references/procedure.md) |
| Subagent: choosing which skills validate which files | [references/skill-routing.md](references/skill-routing.md) |
| Subagent: dead code, duplication, flawed logic | [references/common-checklist.md](references/common-checklist.md) |

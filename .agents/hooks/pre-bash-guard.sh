#!/usr/bin/env bash
# PreToolUse(Bash): pull-request skill rules. Exit 2 blocks and feeds stderr to model.
set -u
cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0
deny() { echo "$1" >&2; exit 2; }

if echo "$cmd" | grep -qE 'git (commit|tag|merge|rebase|am)\b|gh pr (create|edit)\b'; then
  if echo "$cmd" | grep -qiE 'co-authored-by|generated with|noreply@anthropic|signed-off-by:.*(claude|anthropic)|🤖|(^|[^a-z])claude code|--author[= ]|GIT_(AUTHOR|COMMITTER)_(NAME|EMAIL)=|git config[^|;&]*user\.(name|email)'; then
    jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:"REGRA ABSOLUTA: o agente nunca pode ser autor ou coautor (Co-Authored-By, Generated with, --author, mencao a Claude/IA). Este comando contem atribuicao ou troca de autoria. Autorizar somente se o dev quiser MESMO. Caso contrario negue e o agente refaz sem atribuicao."}}'
    exit 0
  fi
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if echo "$cmd" | grep -qE '(^|[;&| ])git (commit|push)\b.*--no-verify|git commit .* -n( |$)'; then
  deny "[pull-request] --no-verify proibido, deixe os hooks do husky rodarem."
fi
if echo "$cmd" | grep -qE 'git push\b.*(--force|-f\b|--force-with-lease)'; then
  deny "[pull-request] force-push proibido."
fi
if echo "$cmd" | grep -qE 'git (commit|push)\b' && { [ "$branch" = "main" ] || [ "$branch" = "master" ]; }; then
  deny "[pull-request] main é protegida. Crie branch <type>/<slug> antes de commit/push."
fi
if echo "$cmd" | grep -qE 'git checkout -b|git switch -c'; then
  name=$(echo "$cmd" | sed -E 's/.*(checkout -b|switch -c) +([^ ]+).*/\2/')
  echo "$name" | grep -qE '^(feat|fix|docs|refactor|chore)/[a-z0-9][a-z0-9-]*$' || deny "[pull-request] branch deve ser <feat|fix|docs|refactor|chore>/<slug-kebab>, recebi '$name'."
fi
if echo "$cmd" | grep -qE 'git commit\b.*-m'; then
  msg=$(echo "$cmd" | sed -nE "s/.*-m +[\"']([^\"']+).*/\1/p" | head -1)
  if [ -n "$msg" ]; then
    echo "$msg" | grep -qE '^(feat|fix|docs|refactor|chore)(\([a-z0-9-]+\))?!?: .+' || deny "[pull-request] commit deve ser Conventional Commits (feat|fix|docs|refactor|chore): '$msg'."
    subject=$(echo "$msg" | head -1)
    [ ${#subject} -le 50 ] || deny "[pull-request] subject do commit > 50 chars (${#subject})."
  fi
fi
if echo "$cmd" | grep -qE 'gh pr create'; then
  title=$(echo "$cmd" | sed -nE "s/.*--title +[\"']([^\"']+).*/\1/p" | head -1)
  [ -n "$title" ] || deny "[pull-request] gh pr create precisa de --title no formato [TIPO][FE|BE][branch][CARD]: descrição."
  echo "$title" | grep -qE '^\[[A-Z]+\]\[(FE|BE)\]\[[A-Z0-9/_.-]+\](\[[A-Z0-9_-]+\])?: .+' || deny "[pull-request] título inválido: '$title'. Formato: [TIPO][FE|BE][BRANCH-NAME][CARD]: breve descrição, tudo entre colchetes em CAIXA ALTA."
  echo "$cmd" | grep -qE -- '--assignee' || deny "[pull-request] PR sem --assignee (use @me)."
  echo "$cmd" | grep -qE -- '--base +main|-B +main' || deny "[pull-request] PR deve ter --base main."
fi
if echo "$cmd" | grep -qE 'gh pr merge' && ! echo "$cmd" | grep -qE -- '--squash|--delete-branch'; then
  deny "[pull-request] merge: use --squash --delete-branch."
fi
exit 0

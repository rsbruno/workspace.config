#!/usr/bin/env bash
# PreToolUse(Bash): pull-request skill rules. Exit 2 blocks and feeds stderr to model.
# The developer controls branches: creating, switching, renaming or deleting a branch, and pushing a
# branch under another name, only run after the developer confirms (permissionDecision "ask").
set -u
cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0
deny() { echo "$1" >&2; exit 2; }
ask() {
  jq -n --arg reason "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$reason}}'
  exit 0
}

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
if echo "$cmd" | grep -qE 'git push\b.*(--force([^-]|$)|( |^)-f( |$))'; then
  deny "[pull-request] force-push proibido (--force-with-lease é permitido)."
fi
if echo "$cmd" | grep -qE 'git (commit|push)\b' && { [ "$branch" = "main" ] || [ "$branch" = "master" ] || [ "$branch" = "develop" ]; }; then
  deny "[pull-request] $branch é protegida. Pare e pergunte ao dev em qual branch trabalhar; não crie nem troque de branch."
fi

# Branches são do dev: criar, trocar, renomear, apagar ou empurrar com outro nome exige confirmação.
branch_reason="O dev controla as branches. Este comando cria, troca, renomeia, apaga ou empurra uma branch com outro nome. Autorizar somente se o dev pediu essa operação. Caso contrário negue e pergunte em qual branch trabalhar."
if echo "$cmd" | grep -qE '(^|[;&| ])git +(switch|checkout)\b'; then
  ask "$branch_reason"
fi
if echo "$cmd" | grep -qE '(^|[;&| ])git +branch +[A-Za-z0-9_./]|(^|[;&| ])git +branch\b[^;&|]*( --(move|delete|force|copy)\b| -[mMdDfcC]( |$))'; then
  ask "$branch_reason"
fi
push=$(echo "$cmd" | grep -oE '(^|[;&| ])git +push\b[^;&|]*' | head -1 || true)
if [ -n "$push" ]; then
  echo "$push" | grep -qE '( --(delete|all|mirror)\b| -d( |$))' && ask "$branch_reason"
  read -ra toks <<< "$push"
  refs=()
  for t in "${toks[@]}"; do
    case "$t" in git | push | -* | "") ;; *) refs+=("$t") ;; esac
  done
  ref="${refs[1]:-}"
  if [ -n "$ref" ] && { [[ "$ref" == *:* ]] || { [ "$ref" != "$branch" ] && [ "$ref" != "HEAD" ]; }; }; then
    ask "$branch_reason"
  fi
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
  tbranch=$(echo "$title" | sed -nE 's#^\[[A-Z]+\]\[(FE|BE)\]\[([A-Z0-9/_.-]+)\].*#\2#p')
  head=$(echo "$cmd" | sed -nE 's#.*(--head|-H) +([^ ]+).*#\2#p' | head -1)
  want=$(echo "${head:-$branch}" | tr 'a-z' 'A-Z')
  [ "$tbranch" = "$want" ] || deny "[pull-request] o título deve usar a branch real (${head:-$branch} → [$want]), recebi [$tbranch]. O dev controla as branches: não invente nome."
  echo "$cmd" | grep -qE -- '--assignee' || deny "[pull-request] PR sem --assignee (use @me)."
  echo "$cmd" | grep -qE -- '--base +(main|develop)|-B +(main|develop)' || deny "[pull-request] PR deve ter --base develop (primeiro) ou --base main."
fi
if echo "$cmd" | grep -qE 'gh pr merge'; then
  echo "$cmd" | grep -qE -- '--squash' || deny "[pull-request] merge: use --squash."
  echo "$cmd" | grep -qE -- '--delete-branch|( |^)-d( |$)' && deny "[pull-request] merge: sem --delete-branch, a branch só morre depois do merge na main."
fi
exit 0

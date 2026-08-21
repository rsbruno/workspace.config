#!/usr/bin/env bash
set -euo pipefail

read -r total used free shared buffcache available < <(free -m | awk 'NR==2{print $2,$3,$4,$5,$6,$7}')

context="RAM: ${used}MB usada / ${total}MB total (${available}MB disponivel)."

if [ "$available" -lt 1000 ]; then
  msg="ALERTA: RAM disponivel baixa (${available}MB) - risco de travar a maquina."
  printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s %s"}}\n' \
    "$msg" "$context" "$msg"
else
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$context"
fi

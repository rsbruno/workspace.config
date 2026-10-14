#!/usr/bin/env bash
# SessionStart: detect front/back and print the skill routing as context.
cwd=$(pwd)
if [ -f nest-cli.json ] || grep -q '"@nestjs/core"' package.json 2>/dev/null; then
cat <<'T'
Repo BACKEND (NestJS). Antes de escrever, carregue as skills pela tabela do CLAUDE.md:
repository -> backend-sql (+ domínio) | schema/seed -> backend-schema | DTO resposta -> backend-dto |
handler/controller/module -> backend-cqrs | policy -> backend-rule | filtro -> backend-filter |
erro/idioma -> backend-locale | provider -> backend-provider | módulo novo -> backend-module.
Shipping: /pull-request.
T
elif grep -q '@tanstack/react-router' package.json 2>/dev/null; then
cat <<'T'
Repo FRONTEND (React 19 + TanStack). Skills: tela CRUD -> frontend-page | composto -> frontend-component |
tabela -> frontend-table | form -> frontend-form | filtro -> frontend-filter | wizard -> frontend-stepper |
loading -> frontend-fallback | textos -> frontend-locale | testes -> frontend-qa.
Shipping: /pull-request.
T
fi
exit 0

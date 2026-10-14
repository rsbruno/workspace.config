<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://brunorobertosantos.com.br/assets/svgs/isotype-white.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://brunorobertosantos.com.br/assets/svgs/isotype-dark.svg">
  <img alt="Workspace Config" src="https://brunorobertosantos.com.br/assets/svgs/isotype-dark.svg" height="92">
</picture>

# Workspace Config

**Skills de agentes de IA e configurações de editor, prontas para instalar.**

</div>

---

## O que é

Repositório de configuração consumido pelo [`workspace.kit`](https://github.com/rsbruno/workspace.kit). Ele guarda duas coisas:

- **Skills** para Claude Code e Codex, separadas por área (`backend`, `frontend`, `workflow`).
- **Configurações de editor** para VS Code e Cursor (`settings.json`, `keybindings.json`, `extensions.json`).

Você não precisa clonar nada: a CLI baixa a versão atual deste repositório e instala onde você escolher.

## Como usar

Pelo kit, que registra o que instalou para `update` e `remove` funcionarem:

```bash
npx https://github.com/rsbruno/workspace.kit/releases/latest/download/workspace.tgz skills add
npx https://github.com/rsbruno/workspace.kit/releases/latest/download/workspace.tgz editor add
```

Veja os comandos completos e as flags no README do `workspace.kit`.

Manualmente, copie a pasta da skill desejada para `.claude/skills/` (Claude Code) ou `.agents/skills/` (Codex) do seu projeto.

## Estrutura

```
.agents/skills/
├── backend/    11 skills (NestJS, Drizzle, CQRS)
├── frontend/   10 skills (React, TanStack, Zod)
└── workflow/    2 skills (pull request, pre-review)

.vscode/
├── settings.json
├── keybindings.json
└── extensions.json
```

Cada skill é uma pasta autocontida:

```
<skill>/
├── SKILL.md        regras fixas + tabela "quando ler → arquivo"
├── LICENSE.txt
└── references/     detalhe, templates e exemplos
```

## Skills

Todas têm `disable-model-invocation: true`: o modelo nunca as dispara sozinho e a descrição não ocupa contexto. Você chama pelo nome (`/backend-cqrs`) ou manda o `AGENTS.md`/`CLAUDE.md` do projeto ler o `SKILL.md`.

### Backend

| Skill | Cobre |
| --- | --- |
| `backend-cqrs` | Query vs command, módulos, escopo de organização, ciclo de vida, paginação, templates |
| `backend-module` | Criar módulo novo de ponta a ponta |
| `backend-schema` | Tabelas, soft delete, enums, dinheiro, datas, slug, seeds |
| `backend-sql` | Repositories Drizzle, paginação real, filtros, transações |
| `backend-filter` | Quais colunas viram filtro e como escrevê-los |
| `backend-dto` | DTO de resposta e contrato Orval |
| `backend-locale` | Mensagens traduzidas, `BusinessException`, i18n |
| `backend-rule` | Permissões (`@Can`/`@Feature`) e catálogo |
| `backend-provider` | Integração com provider externo e webhooks |
| `backend-test` | Testes unitários, integração e E2E |
| `backend-refactor` | Auditar e endurecer um módulo existente |

### Frontend

| Skill | Cobre |
| --- | --- |
| `frontend-page` | Telas CRUD: rotas, form shell, tabs, dialogs, boundaries |
| `frontend-table` | Tabelas de listagem e row actions |
| `frontend-form` | Campos, schema e validação espelhando o backend |
| `frontend-filter` | Filtros de listagem |
| `frontend-fallback` | Loading e skeletons |
| `frontend-locale` | Árvore de `pages.json` e textos fixos |
| `frontend-component` | Componentes compostos |
| `frontend-stepper` | Telas com steps (wizard) |
| `frontend-qa` | Testes E2E, integração e unitários |
| `frontend-design` | Direção visual (licença da Anthropic) |

### Workflow

| Skill | Cobre |
| --- | --- |
| `pull-request` | Branch, commit e PR com título e corpo padronizados |
| `pre-review` | Review do que está na worktree antes do commit, validando contra as demais skills |

## Snippet para AGENTS.md / CLAUDE.md

Cole no arquivo do projeto e remova o lado que ele não usa. Ajuste o prefixo para `.agents/skills/` se o agente for o Codex.

```md
## Skills

Antes de tocar nestes assuntos, leia o `SKILL.md` indicado e só as `references/` que ele apontar para a tarefa.

### Backend
- Query/command/controller/module, escopo de organização: `.claude/skills/backend-cqrs/SKILL.md`
- Módulo novo: `.claude/skills/backend-module/SKILL.md`
- Tabela, enum, dinheiro, data, seed: `.claude/skills/backend-schema/SKILL.md`
- Repository / Drizzle: `.claude/skills/backend-sql/SKILL.md` (sempre junto com a skill de domínio)
- Filtro de listagem: `.claude/skills/backend-filter/SKILL.md`
- DTO de resposta: `.claude/skills/backend-dto/SKILL.md`
- Mensagens, erros, i18n: `.claude/skills/backend-locale/SKILL.md`
- Permissão (`@Can`/`@Feature`): `.claude/skills/backend-rule/SKILL.md`
- Provider externo / webhook: `.claude/skills/backend-provider/SKILL.md`
- Testes: `.claude/skills/backend-test/SKILL.md`
- Auditar/endurecer módulo existente: `.claude/skills/backend-refactor/SKILL.md`

### Frontend
- Tela CRUD (rotas, form shell, tabs): `.claude/skills/frontend-page/SKILL.md`
- Tabela de listagem: `.claude/skills/frontend-table/SKILL.md`
- Campo/schema de formulário: `.claude/skills/frontend-form/SKILL.md`
- Filtros de listagem: `.claude/skills/frontend-filter/SKILL.md`
- Loading/skeleton: `.claude/skills/frontend-fallback/SKILL.md`
- Locale de tela (`pages.json`): `.claude/skills/frontend-locale/SKILL.md`
- Componente composto: `.claude/skills/frontend-component/SKILL.md`
- Wizard/steps: `.claude/skills/frontend-stepper/SKILL.md`
- Testes frontend: `.claude/skills/frontend-qa/SKILL.md`
- Direção visual (só se pedido): `.claude/skills/frontend-design/SKILL.md`

### Workflow
- Subir mudanças / abrir PR: `.claude/skills/pull-request/SKILL.md`
- Review antes do commit: `.claude/skills/pre-review/SKILL.md`
```

As referências entre skills por nome (`backend-rule`, `frontend-page`...) só têm arquivo para abrir se a skill citada também estiver instalada.

## Configurações de editor

| Arquivo | Conteúdo |
| --- | --- |
| `settings.json` | Tema de ícones, associações de arquivos da stack Nest, formatadores por linguagem, corretor ortográfico em `en` e `pt-BR` |
| `keybindings.json` | Atalhos de edição e formatação |
| `extensions.json` | Extensões recomendadas |

## Convenções das skills

- `SKILL.md` curto: regras fixas em bullets e tabela "quando ler → arquivo".
- Detalhe, templates e exemplos em `references/`, um nível de profundidade.
- Descrições curtas, que servem de índice humano e não de gatilho.
- Genéricas: sem nome de cliente nem de projeto. A tela canônica de exemplo do front está em `frontend-page/references/canonical-crud-reference.md`.
- Versionadas em `metadata.version` (hoje `1.0.0`): patch para correção de texto, minor para regra ou referência nova, major para mudança que remove ou altera comportamento.

## Contribuição

Mudanças entram por PR, seguindo a skill `pull-request`. O título segue o formato:

```
[TIPO][ESCOPO][branch][CARD]: descrição curta
```

O `[CARD]` é opcional.

## Licença

Apache-2.0. Cada skill carrega o seu `LICENSE.txt`, com copyright de Bruno Roberto Santos. A skill `frontend-design` mantém a licença e o crédito da Anthropic.

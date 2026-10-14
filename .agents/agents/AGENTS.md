# Instruções do projeto

Este arquivo serve igual para Claude Code (`CLAUDE.md`) e Codex (`AGENTS.md`). Vale para repositório de backend (NestJS + Drizzle) e de frontend (React 19 + TanStack Router): use só as seções do lado em que o repo está e só as skills que existem na pasta de skills do projeto.

## Regras básicas

- Responda sempre em PT-BR.
- Economize tokens: sem releitura de contexto, sem janelas grandes, sem subagente fora de caso específico.
- Nunca use `any`. Nenhum comentário em arquivo real; nome descritivo resolve.
- Nunca invente provider, campo, endpoint, copy ou regra de negócio: pergunte.
- Nunca hardcode `""` ou `"-"`; use `Strings.EMPTY` / `Strings.UNDEFINED` (frontend) ou a constante equivalente.

## Verificação de código

Depois de escrever ou editar código, não rode `tsc`, lint, prettier, build nem testes por conta própria. Pare e diga o que foi feito. Só rode se o dev pedir naquela tarefa; pedido anterior não vale para a próxima.

Exceção permanente (backend): `pnpm db:generate`, `pnpm db:push` e `pnpm db:seed`.

## Skills: como usar

- Antes de escrever ou revisar arquivo, identifique na tabela do seu lado qual skill se aplica e carregue. Não bateu com nenhuma linha: não carregue nenhuma.
- Tarefa que cruza responsabilidades: carregue todas as relevantes. Elas não se sobrepõem.
- Uma skill que termina não chama a próxima; o encadeamento abaixo é papel deste arquivo.
- Todas as skills são auto-invocáveis, exceto `pre-review`, `backend-refactor` e `frontend-design`: essas três só rodam quando o dev pedir.

### Backend (NestJS + Drizzle)

| Pedido / arquivo | Skill |
|---|---|
| Criar módulo novo do zero | `backend-module`: estrutura de pastas, registro, migration, testes |
| `.schema.ts`, seed em `drizzle/seeds/` | `backend-schema`: soft delete, pivot, enum inteiro, dinheiro em centavos, slug, seed |
| DTO de **resposta** (`http/dtos/*.dto.ts`) | `backend-dto`: contrato Swagger/Orval, DTO enxuto, nullable |
| Campo de API externa, mensagem de erro, `code-exceptions.enum.ts`, `exceptions.json` | `backend-locale`: props em inglês, mensagens em PT via i18n, `BusinessException` |
| Query, command, handler, controller, module, Port | `backend-cqrs`: classificação CQRS, bus entre módulos, escopo de organização |
| Integração com provider externo, webhook | `backend-provider`: `@Transform`, um service por caso de uso, HMAC |
| Permissão em `policies/data.json`, `@Can`, `@Feature` | `backend-rule`: shape fixo, catálogo, grant |
| Filtro de `findAll` (query param novo ou coluna nova) | `backend-filter`: analisa coluna por coluna, operador, índice |
| Qualquer `*-query.repository.ts` ou `*-command.repository.ts` | `backend-sql`: **sempre**, junto com a skill de domínio. Organização no WHERE, paginação real, sem N+1 |
| Escrever ou auditar testes de módulo | `backend-test`: inventário, unit, integração, E2E, mutation checks |
| Auditar e endurecer módulo existente | `backend-refactor`: inventário, achados, correções, migration, testes |

### Frontend (React 19 + TanStack Router)

| Pedido / arquivo | Skill |
|---|---|
| Tela CRUD nova (listagem + criar + editar), pastas e rotas | `frontend-page`: gating `require`, `PageForm*`, abas, dialogs, boundaries |
| Componente com 2+ partes que compartilham estado | `frontend-component`: um arquivo por parte, exports achatados, só `index.ts` |
| Tabela de listagem, row actions, badge de status | `frontend-table`: ordem e tamanho de coluna, `TableRowLink`, `RowAction[]` |
| Campo de formulário, schema Zod ligado a payload de API | `frontend-form`: componente por semântica do dado, limites do DTO orval no Zod e na prop |
| Filtro de listagem | `frontend-filter`: schema, store, campos, `validateSearch` |
| Tela com steps (wizard) | `frontend-stepper`: `lazy()` por rota, `StepperFooterSummary`, guard inline |
| Loading, skeleton, `pendingComponent` | `frontend-fallback`: fallback dedicado, sem layout shift |
| Qualquer texto visível, `pages.json` | `frontend-locale`: árvore obrigatória, ações e confirmações padrão |
| Escrever ou auditar testes | `frontend-qa`: inventário, Playwright, Vitest, relatório de lacunas |
| Direção visual genuinamente nova, sem convenção a seguir | `frontend-design`: último recurso, nunca ponto de partida |

## Encadeamento obrigatório

### Backend

- Módulo novo (`backend-module`) aciona `backend-cqrs`, `backend-schema`, `backend-sql`, `backend-dto`, `backend-locale`, `backend-rule` e `backend-test`, e `backend-provider` se houver provider.
- Endpoint novo: `backend-rule` (permissão) e `backend-test` antes de fechar. Permissão nova só aparece depois do grant aos grupos.
- Coluna nova filtrável: `backend-filter` + índice na mesma migration.
- Mensagem de erro nova: `backend-locale` (enum + `exceptions.json` juntos).
- Contrato de resposta alterado: listar impacto no frontend no relatório; nunca editar o web durante refactor de backend.

### Frontend

- Fim de `frontend-component`: chamar `frontend-fallback` para o `*Fallback` do componente.
- Fim de `frontend-page`: chamar, na ordem que fizer sentido, `frontend-component` (se a família do form não existir), `frontend-table`, `frontend-form`, `frontend-fallback`, `frontend-locale` e `frontend-filter` (se a listagem tiver filtro).
- Todo campo de formulário novo, mesmo em dialog, passa por `frontend-form` antes de fechar.
- Toda tabela nova, ou `*-row-actions.tsx` / badge de tabela alterado, passa por `frontend-table`.
- Toda string visível nova passa por `frontend-locale` antes de virar chave definitiva.
- Tela com steps: `frontend-stepper` + `frontend-form`, `frontend-fallback` e `frontend-locale`.

## Regras de frontend

- React 19: `ref` é prop normal, nunca `forwardRef`.
- Nenhuma string visível hardcoded em JSX.
- Nunca chame `API<T>({ url })` cru quando existe função gerada pelo orval; para blob use a função orval com `{ responseType: "blob" }`.
- `useMutation` com `onError` chamando `toast.dispatch` leva obrigatoriamente `meta: { ignoreError: true }` (o query client já dispara toast genérico).

## Git: commit e pull request

- Commit: skill `commit`. PR: skill `pull-request`. Carregue ao ouvir "commita", "cria a PR", "sobe isso".
- Revisão pré-commit só quando o dev pedir (`/pre-review`).
- **O agente nunca é autor nem coautor.** Nada de `Co-Authored-By`, "Generated with", 🤖 ou menção a Claude/IA em commit ou PR, e nunca mexer na autoria. Se parecer necessário, pare e pergunte ao dev.
- Nunca commitar na `main`, nunca `--no-verify`, nunca force-push.
- Título de PR: `[TIPO][FE|BE][BRANCH-NAME][CARD]: descrição`, tudo entre colchetes em caixa alta.

## Regras do projeto

Nenhuma regra específica registrada. Regras só deste repositório (estado de migrations, variáveis de ambiente, dívida técnica, decisões de ferramenta) entram aqui.

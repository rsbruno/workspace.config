---
name: frontend-stepper
description: Padrão de telas com steps (wizard) — steps lazy declarados na rota, StepperRoot com `steps`, StepperFooterSummary, search schema, guard inline.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# frontend-stepper

Cobre só a estrutura de steps. Formulário, tabela, locale e fallback seguem as skills próprias (`frontend-form`, `frontend-fallback`, `frontend-locale`, `frontend-page`, `frontend-component`). Referência canônica: uma tela de wizard existente do projeto (`criar/index.tsx`, `editar/$id/index.tsx`, `_steps/`, `_schemas/create-search.schema.ts`); ler antes de criar ou revisar.

## Regra central

Não existe registro de steps nem de abas. Cada rota declara os seus `lazy()` no topo e renderiza cada step com seu próprio `Suspense` e fallback. Duplicar entre telas é aceito.

Proibido:
- Arquivo de registro/lista de steps ou abas fora da rota (`<entidade>-steps.ts`, `resolve…StepIndex`, `<ENTIDADE>_STEPS`).
- `StepperStep` escrito à mão, `StepperRoot` com `children` de step, clonar filhos do stepper.
- Repetir contador + hint no rodapé de cada step (usar `StepperFooterSummary`).

## Regras fixas

- Nomes dos steps vivem só no schema (`<entidade>StepNames`); a ordem do array é a ordem do stepper. O id criado no step 1 trafega na search, nunca em estado local.
- Guard de acesso inline: step dependente do id só abre com o id na search; sem ele volta ao primeiro.
- Todo step recebe as mesmas props; prop usada por poucos é opcional (`Strings.EMPTY` no default).
- `useMemo` antes do guard de hidratação. `navigate` sempre com `replace: true`. Step só clicável quando concluído.
- `_steps` e `_tabs` separados; fallback de step e de aba são arquivos distintos.
- Rodapé: `PageFormFooter` + `StepperFooterSummary`; nunca botão Cancelar; `<Can>` em tudo que muta; `data-testid` por botão.
- `Pular` nunca navega direto: abre dialog `info` de confirmação dedicado (consequência vem do requisito, nunca inventada).
- Mutation com `toast.dispatch` custom exige `meta: { ignoreError: true }`.
- Locale por `name`, sem literal no JSX. Sem comentários, sem `any`.

## References

| Quando ler | Arquivo |
|---|---|
| Criar a estrutura, schema, rota de criação ou edição com abas | [references/structure-and-routes.md](references/structure-and-routes.md) |
| Rodapé, botão Pular, mutations entre steps, chaves de locale | [references/footer-skip-mutation-locale.md](references/footer-skip-mutation-locale.md) |
| Adicionar step a tela existente, checklist final, encadeamento | [references/add-step-and-checklist.md](references/add-step-and-checklist.md) |

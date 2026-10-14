---
name: frontend-locale
description: Padroniza os locales de telas — árvore obrigatória de pages.json, strings fixas de ações e confirmações, e onde cada locale fica.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# Locale de telas

Usar ao criar tela, rota de criação/edição, adicionar texto visível ou alterar locale de tela. Antes de agir, ler o README de i18n do projeto e [references/page-tree.md](references/page-tree.md). A estrutura é lei: nunca renomear nem inventar branches sem perguntar.

Estrutura completa e exemplo: [references/pages-json-contract.md](references/pages-json-contract.md).

## Regras fixas

- `meta.title` só o nome da página (sem sistema, produto ou marca). `title` curto; `subtitle` existe em listagem, criação e edição.
- Preservar exatamente `confirm`, `dialog.filter`, `actions.submit`. Nunca `filter-dialog`.
- Placeholder de busca começa com `Pesquise por` e lista os campos tratados.
- Ações: `Arquivar`, `Excluir`, `Restaurar`, `Cadastrar`. Confirmações: `Sim, arquivar!`, `Sim, restaurar!`, `Sim, excluir!`, `Não, manter.`.
- `create.actions.submit` = `Cadastrar`. `edit.actions.submit` = `Salvar alterações`.
- Consequências em `confirm`: verdadeiras, breves, sobre a entidade. Vêm do requisito/backend; sem fonte, perguntar. Nunca inventar.
- Nome da entidade idêntico em título, descrição, toast, tabela e confirmação.
- Nenhuma string visível hardcoded em componentes. Sem travessão em texto visível. Português do Brasil, terminologia do domínio.

## Onde cada locale fica

- `pages.json`: tudo de uma tela/rota, na árvore obrigatória.
- `components.json`: componente global realmente reutilizável.
- `layouts.json`: header, navegação, casca global.
- `options.json`: labels de enums usados em mais de uma tela.
- `schemas.json`: mensagens genéricas de validação.
- `common.json`: texto sem domínio usado em 3+ entidades.

Componente escopado usa o locale da tela; global usa `components.json`. Não criar namespace solto para contornar o contrato.

## References

| Quando ler | Arquivo |
|---|---|
| Sempre, antes de agir | [references/page-tree.md](references/page-tree.md) |
| Escrever o `pages.json` de uma tela | [references/pages-json-contract.md](references/pages-json-contract.md) |
| Textos de campos, seções, meta e layout, validação, convenções | [references/copy-and-fields.md](references/copy-and-fields.md), [references/meta-title-and-layout.md](references/meta-title-and-layout.md), [references/validation-and-generic.md](references/validation-and-generic.md), [references/conventions-and-checklist.md](references/conventions-and-checklist.md) |

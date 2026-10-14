# `meta.title`, layout e opções

## `meta.title`

`meta.title` existe somente em páginas e rotas. Toda listagem, criação e edição tem seu próprio valor.

- Contém somente o nome da página.
- Não contém nome do sistema, marca, produto ou sufixo.
- Não é herdado da listagem nem reutiliza o `title` de outra tela.
- Exemplos: `Grupos de itens`, `Novo grupo de itens`, `Editar grupo de itens`.

## Layout e navegação

Layout e navegação não usam a árvore de página:

```
[layout-name]
  brand.{name, tagline}
  nav.sections.<section>
    label
    items.<item>.{label, subtitle}
```

## Opções e enums

Labels de enum usados em select ou filtro em mais de uma tela ficam em `options.json`, por entidade de domínio e campo:

```
[domain-entity]
  <field-name>
    <enum-value>: "Label"
```

Não duplique a mesma label em `pages.json` e `options.json`.

## Status local

Um status que aparece somente no badge de uma tabela pode ficar no próprio locale da tela. Se for usado em select, filtro ou outra tela, mova para `options.json`.

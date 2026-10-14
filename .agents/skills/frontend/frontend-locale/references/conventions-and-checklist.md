# Convenções e checklist

1. Siga a árvore completa de `references/page-tree.md`.
2. Preserve exatamente os nomes `actions`, `confirm`, `dialog.filter` e `actions.submit`.
3. Use chaves em kebab-case quando a chave representar entidade, rota ou campo.
4. `meta.title` contém somente o nome da página, sem sistema, produto ou marca.
5. `title` é direto e `subtitle` sempre existe na listagem, criação e edição.
6. O placeholder de busca começa com `Pesquise por`.
7. Use exatamente `Cadastrar`, `Salvar alterações`, `Arquivar`, `Excluir`, `Restaurar`, `Sim, arquivar!`, `Sim, excluir!`, `Sim, restaurar!` e `Não, manter.` nos lugares definidos pelo contrato.
8. Use `{{name}}` para o nome interpolado da entidade.
9. Toda consequência de confirmação deve ser verdadeira e baseada em requisito, project docs e backend. Quando não souber, pergunte.
10. Use pluralização nativa do i18next quando houver quantidade.
11. Locale de componente global fica em `components.json`; locale de componente escopado fica na árvore da tela.
12. Enum compartilhado fica em `options.json`; validação genérica fica em `schemas.json`.

Antes de finalizar, confira a árvore, os nomes das props, as strings fixas, a origem das consequências e o namespace correto.

# Itemários, inventário de permissões, relatório, execução

## 8. Itemários

Para cada schema, option, store ou função pura com lógica real, cubra:

- entrada válida e transformação de saída;
- required, limites mínimo/máximo, tamanho, formato e refinements reais;
- valores vazios e defaults representados por `Strings.EMPTY` ou equivalente;
- cada branch de conversão de query, formulário e payload;
- cada status, label, variante e valor de opção;
- persistência, parse, defaults e transformação de stores quando houver decisão real.

Não escreva teste unitário para confirmar que `useState`, um componente primitivo ou uma constante trivial funciona. Não use rede ou componente React quando a regra puder ser provada diretamente.

## 9. Inventário de permissões

Antes dos testes de permissão:

1. Liste o bloco completo da tela em `src/constants/enums/policy.enum.ts`.
2. Liste cada uso nas rotas e em todos os arquivos escopados: `beforeLoad`, `<Can>`, `can`, `canAny`, `TableRowLink` e command palette.
3. Confira se cada endpoint/mutation do serviço tem gate correspondente na UI.
4. Teste presença e ausência para cada gate.
5. Para `canAny`, teste cada permission isoladamente: uma por vez, não apenas todas juntas.
6. Diferencie policy realmente pertencente a outra tela de policy morta ou gate ausente.

Reporte missing gate, policy órfã e policy usada sem endpoint alcançável. Não invente UI para policy que pertence a outro fluxo.

## 10. Cobertura e relatório

Ao concluir uma bateria, informe explicitamente:

- arquivos E2E, integração e unitários criados ou alterados;
- cenários cobertos por camada;
- categorias que não existem para aquela tela e por isso foram omitidas;
- branches encontrados mas não cobertos, com arquivo e linha;
- limitações de fixture, sessão, API, browser ou ambiente;
- o que só pode ser garantido pelo backend;
- risco de divergência entre policy do frontend e contrato do backend.

Nunca diga apenas “100% coberto”. Diga quais cenários foram provados e quais permaneceram fora da bateria.

## 11. Convenções de execução

- Test titles, nomes de helpers, variáveis e comentários dentro dos testes ficam em inglês.
- Strings literais usadas para verificar a UI permanecem exatamente como o produto exibe.
- Use os scripts existentes: `pnpm test` para Vitest e `pnpm test:e2e` para Playwright.
- Não adicione `--reporter=verbose` nem altere a configuração de reporter apenas para investigar uma falha.
- Rode primeiro o arquivo ou camada afetada quando depurando; rode a suíte completa somente quando a tarefa pedir.
- Não misture testes E2E e Vitest no mesmo arquivo.

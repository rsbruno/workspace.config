# Leitura prévia, camadas obrigatórias, estrutura dos testes

## 0. Leia antes de escrever

Antes de criar ou alterar qualquer teste, leia:

1. As rotas da tela: `index.tsx`, `criar/index.tsx`, `editar/$id/index.tsx` e subrotas existentes.
2. Tudo dentro das pastas escopadas da tela: `_components/`, `_schemas/`, `_stores/`, `_hooks/`, `_utils/`, `_constants/` e `_command-palette/`.
3. Cada componente compartilhado não trivial usado pela tela, até entender estados condicionais, `data-testid`, callbacks e props de carregamento.
4. O serviço Orval usado pela tela, com métodos, parâmetros, payloads e respostas exatas.
5. `policy.enum.ts` e `feature.enum.ts` para os códigos reais de permissão e feature.
6. Os helpers de teste aplicáveis: `src/test/render-route.tsx`, `src/test/render-with-session.tsx`, `src/__tests__/helpers/` e `src/__tests__/auth.setup.ts`.
7. Os testes existentes da mesma área, preservando a convenção já usada no módulo.

Não escreva testes a partir apenas do pedido. O inventário deve incluir toda mutação, query, loader, `beforeLoad`, `Can`, `can`, `canAny`, `TableRowLink`, filtro, fallback, branch por estado, transformação e efeito visível.

## 1. Camadas obrigatórias

Os testes frontend vivem em `src/__tests__` e são divididos por responsabilidade:

- **E2E**: Playwright, navegador real, sessão autenticada, rotas reais, guards reais e API real. Prova jornadas críticas e integração entre tela, backend, permissões e persistência.
- **Integração**: Vitest + Testing Library, rota ou componente montado em React. Prova renderização, interação, filtros, permissões, loaders, mutations, navegação, diálogos e estados condicionais com serviços Orval controlados.
- **Itemário**: Vitest sem DOM ou rede quando possível. Prova schemas Zod, transformações, opções, stores e funções puras isoladas.

Cada cenário deve ser colocado na camada que melhor prova o comportamento. Não replique todos os casos mecanicamente nas três camadas:

- Regra pura e determinística vai para unitário.
- Comportamento da tela e do componente vai para integração.
- Jornada crítica que depende de browser, guards, API ou persistência vai para E2E.

Permissões de cada elemento são provadas principalmente na integração, cobrindo o contrato visual completo. E2E deve cobrir os fluxos autorizados e, quando a infraestrutura de sessão permitir, os fluxos negados relevantes. Testes frontend não substituem a autorização do backend.

## 2. Estrutura dos testes

Não crie `_tests/` dentro de uma rota e não crie uma árvore central paralela fora de `src/__tests__`. A pasta de testes acompanha o domínio e a tela:

```text
src/__tests__/
└── parametros/
    └── unidades-de-medida/
        ├── fixtures.ts
        ├── e2e/
        │   ├── criar.e2e.ts
        │   ├── editar.e2e.ts
        │   └── ciclo.e2e.ts
        ├── integration/
        │   ├── index.permissions.test.tsx
        │   ├── index.filter.test.tsx
        │   ├── index.functionality.test.tsx
        │   ├── criar.test.tsx
        │   ├── editar.test.tsx
        │   ├── command-palette.test.ts
        │   └── unit-row-actions.test.tsx
        └── unit/
            ├── form.schema.test.ts
            ├── filter.schema.test.ts
            └── status.option.test.ts
```

Use o mesmo padrão para outras telas: `<domínio>/<tela>/{e2e,integration,unit}`. Mantenha `fixtures.ts` na raiz da tela quando os dados forem compartilhados por mais de uma camada. Arquivos E2E terminam em `.e2e.ts`; testes Vitest terminam em `.test.ts` ou `.test.tsx`.

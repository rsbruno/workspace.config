---
name: frontend-qa
description: Escreve e audita testes frontend — Playwright (E2E) e Vitest + Testing Library (integração, unitário) em src/__tests__, com relatório de lacunas.
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# frontend-qa

Atue como QA sênior: leia o código inteiro, monte o inventário de comportamentos e só então escreva testes. Suíte que passa sem cobrir ramificação, permissão ou transição de estado dá falsa segurança.

## Regras fixas

- Leia antes: rotas da tela, pastas escopadas (`_components`, `_schemas`, `_stores`...), componentes compartilhados não triviais, serviço Orval usado, enums de policy/feature, helpers de teste e testes existentes. Não escreva a partir só do pedido.
- Camadas: regra pura → unitário; comportamento de tela/componente → integração; jornada que exige browser, guards, API ou persistência → E2E. Não replique tudo nas três.
- Estrutura: `src/__tests__/<domínio>/<tela>/{e2e,integration,unit}` + `fixtures.ts`. Nunca `_tests/` dentro da rota. E2E termina em `.e2e.ts`; Vitest em `.test.ts(x)`; nunca misturar no mesmo arquivo.
- Sessão é o cache de `getAuthenticatedUserProfileQueryOptions`; use `renderWithPolicies` (sem router) ou `renderRoute` (rota real) com as policies/features exatas. Sem contexto falso nem branch por `NODE_ENV`.
- Integração: mock do módulo de serviço Orval (`vi.hoisted` + `mockReset`), nunca axios nem a rota sob teste. E2E: sem mock; `page.request` só para preparar/limpar dados.
- Localizadores por `data-testid`, nunca por texto visível. `within` para limitar escopo.
- Permissões: inventário completo; presença e ausência por gate; cada permission de um `canAny` isolada.
- E2E com dados únicos e limpeza tolerante; resposta `200` sozinha não prova que a tela atualizou.
- Nomes de testes e helpers em inglês; strings de UI exatamente como o produto exibe.
- Relatório final lista cenários provados por camada, lacunas com arquivo e linha, limitações e o que só o backend garante. Nunca só "100% coberto".

## References

| Quando ler | Arquivo |
|---|---|
| Início de qualquer trabalho de teste, estrutura de pastas | [references/inventory-layers-structure.md](references/inventory-layers-structure.md) |
| Montar sessão, mockar serviços, nomear `data-testid` | [references/session-mocks-locators.md](references/session-mocks-locators.md) |
| Escrever E2E ou integração de listagem/formulário/componentes | [references/e2e-and-integration.md](references/e2e-and-integration.md) |
| Itemários, inventário de permissões, relatório, comandos | [references/unit-permissions-report.md](references/unit-permissions-report.md) |

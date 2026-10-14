# Sessão, mocking de serviços, localizadores

## 3. Injeção de sessão e montagem

O usuário autenticado é a resposta em cache de `getAuthenticatedUserProfileQueryOptions`. Não crie contexto falso, prop exclusiva de teste, branch por `NODE_ENV` ou caminho de produção apenas para testar.

- Use `renderWithPolicies(ui, { policies })` para componentes que não usam router, loader, `beforeLoad`, `Route.useSearch()` ou navegação.
- Use `renderRoute(Route, { policies, features, path, params })` para a rota exportada, pois ela precisa do router real de teste, loader, guards e navegação.
- Passe as policies e features exatas do módulo. Não use uma policy genérica só para liberar a tela.
- Use `QueryClient` isolado por teste ou pelo helper existente, com retry controlado e cache da sessão sem refetch inesperado.

Para E2E, use `src/__tests__/auth.setup.ts` e o `storageState` configurado no `playwright.config.ts`. Não faça mock do serviço Orval no E2E. Use `page.request` apenas para preparar dados independentes da jornada e para limpeza segura ao final; o comportamento que está sendo provado deve passar pela UI.

## 4. Mocking de serviços

Nos testes de integração, faça mock do módulo de serviço Orval que a tela importa, nunca do axios de baixo nível:

- Declare funções usadas na fábrica `vi.mock` com `vi.hoisted(() => vi.fn())`.
- Em `beforeEach`, use `mockReset()` e configure `mockResolvedValue` ou `mockRejectedValue`.
- Prefira `mockImplementation` quando a resposta precisa mudar conforme parâmetros reais de filtro, paginação ou payload.
- Não use `mockResolvedValueOnce` quando loader e componente podem consultar a mesma query mais de uma vez.
- Não faça mock da rota ou do componente sob teste; controle apenas suas dependências de dados.
- Para mutation, verifique o payload enviado, o toast, a invalidação/refetch observável e a navegação ou fechamento do diálogo.

## 5. Localizadores e data-testid

Nunca localize um elemento de teste pelo texto visível. Texto serve para verificar conteúdo, não para encontrar o elemento.

- Todo controle cuja presença ou ausência seja testada recebe `data-testid`.
- Conteúdo de linha é localizado primeiro pela linha ou célula com `data-testid`, depois verificado com `toHaveTextContent` ou `toHaveValue`.
- Use `within` para limitar a busca ao diálogo, linha, toolbar ou tabela correta.
- Não use seletores ligados à classe visual, posição, texto atual ou implementação incidental.
- Se um componente compartilhado não encaminhar `data-testid`, faça a menor alteração necessária no componente para encaminhá-lo.

Convenção:

- campo: `{entity}-{field}`
- linha: `{entity}-row-{id}`
- ação da toolbar: `{screen}-{action}-button`
- wrapper e gatilho: `{entity}-row-actions-{id}` e `{entity}-row-actions-trigger-{id}`
- item do popover: `{entity}-{action}-action-{id}`
- fallback: `{screen}-page-fallback` ou `{entity}-form-fallback`

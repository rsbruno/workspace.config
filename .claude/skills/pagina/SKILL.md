---
name: pagina
description: Padroniza como uma tela/rota nova é estruturada e desenvolvida neste projeto (TanStack Router + SSR). O arquivo de entrada da rota (`index.tsx` dentro de `src/pages/<rota>/`) segue as convenções de `/componente` (tipagem, sem comentário, sem forwardRef) e concentra as regras de negócio da tela — mutations, handlers, orquestração de modal, navegação —, mas nunca é segmentado em múltiplos arquivos, sempre um `index.tsx` só. `loader` busca dado bruto via server/SSR, `validateSearch` (Zod) define filtro/tab/paginação como estado de URL. Toda tela é decomposta em componentes menores que tratam sua própria lógica interna (parse, debounce, ordenação, seleção) e buscam seu próprio dado do TanStack Query sozinhos (prop drilling mínimo, mesma regra de `/componente`) em vez de recebê-lo pronto via prop da rota — só recebem prop pro que é genuinamente decisão externa (callback, `open`/`onOpenChange`). Cada componente/helper/schema da tela sobe de nível conforme reuso REAL observado, nunca hipotético: nasce ESCOPADO À TELA (`_components/`/`_utils/`/`_schemas/` ao lado do `index.tsx`), sobe pra ESCOPADO AO GRUPO DE ROTAS (`_components/`/`_utils/`/`_schemas/` ao lado do `route.tsx` do grupo, ex: `(autenticacao)/_schemas/`) só quando 2+ telas do MESMO grupo usam, e só vira GLOBAL (`src/components/`, `src/utils/`, `src/schemas/zod/`) quando o reuso atravessa grupos diferentes ou é genuinamente genérico pra qualquer tela do app — nunca pula direto pro topo. Pastas com `_` são ignoradas pelo gerador de rotas via `tsr.config.json` em qualquer nível da árvore. Componente escopado ou global com 2+ partes coordenando estado usa `/componente`; se for simples, vira só `component-name/index.tsx`. Nome de rota/pasta de página (`src/pages/<rota>/`) fica sempre em português (URL amigável pro usuário brasileiro navegar); nome de componente, arquivo de componente e helper (pasta, arquivo, export) fica sempre em inglês, mesmo dentro de `_components/`/`_utils/` de uma rota em português. Busca de dado é sempre desenhada primeiro para SSR/server-side via loader da rota (`ensureQueryData`/`ensureApiQueryData`, nunca fetcher cru + `useLoaderData`) — client-side só como último recurso quando SSR genuinamente não se aplica ao caso; leitura sempre via `useApiQuery` (nunca `useQuery` direto, bloqueado por lint), escrita via `useMutation`, nunca useState+fetch na mão. Query de rota autenticada leva `meta: { requiresAuth: true }` na própria queryOptions — nunca gate de auth montado no call site. Helper (função pura sem JSX) nunca fica declarado dentro do arquivo do componente — segue a mesma classificação Global/Escopado. Todo texto visível vai pro i18n em `src/i18n/locales/pt-BR/`, separado por domínio (`pages.json` = texto de tela, `layouts.json` = texto de layout/grupo, `components.json` = texto de componente reutilizável, `schemas.json` = só mensagem de validação Zod, quando existir) — nunca string literal no JSX, e a chave dentro do arquivo sempre espelha o nome da pasta/rota/componente que ela traduz. Qualquer decisão de arquitetura fora do que esta skill cobre deve ser perguntada ao usuário, nunca decidida sozinha. Se a tela envolve layout novo com decisão real de UI/UX (não só reorganização mecânica), usa `/frontend-design` antes de implementar, se disponível. Código existente que não segue este padrão (rota gorda, componente global/escopado no lugar errado, helper solto) deve ser corrigido pra se adequar; só pergunta ao dev quando o ajuste for ambíguo ou de blast radius grande. Use esta skill sempre que for criar uma tela/página nova, adicionar uma rota nova, ou estruturar o desenvolvimento macro de uma feature de tela inteira (com ou sem filtro/tabela/tabs/dado compartilhado). NÃO é auto-invocável — só usar quando o usuário mencionar explicitamente esta skill/o comando `/pagina`, ou quando outra skill chamar por ela, nunca por inferência sozinha.
---

# Criar Tela

Padrão de referência para como uma tela nova nasce neste projeto: TanStack Router (file-based, `src/pages/`) com bias forte para SSR. A tela é uma árvore de responsabilidades bem separadas — a rota só trafega dado, os componentes tratam sua própria lógica, e cada peça mora na pasta certa (global vs escopada) desde o início.

## 1. A rota (`index.tsx`) concentra a regra de negócio da tela, mas nunca é segmentada

O arquivo de entrada (`src/pages/<rota>/index.tsx`) é o componente principal da tela — segue as mesmas convenções de `/componente` (tipagem via `ComponentProps<...>`, nunca `forwardRef`, zero comentário, `displayName`, sem `import * as React`, etc.), só que com uma peculiaridade fixa: **ele nunca é segmentado em múltiplos arquivos** (nada de `delivery-view/`, `delivery-page/index.tsx` + `delivery-page/_form.tsx` — um componente composto normal divide partes em arquivos próprios, a rota não). `index.tsx` é sempre um arquivo só: `Route` (via `createFileRoute`) + a função do componente da tela, lado a lado.

A rota faz:

1. **`loader`** — busca o dado bruto, sempre via server/SSR por padrão (ver seção 4).
2. **`validateSearch`** (Zod) — define filtro, tab ou paginação como estado de URL, quando esse estado precisa ser compartilhável/persistente (ver seção 4).
3. **`component`** — é dono das regras de negócio da tela: mutations, handlers de submit/seleção, orquestração de modal (`useDisclosure`), navegação condicional, cálculo do que depende de mais de uma seção pra decidir (ex: habilitar botão de continuar). Concentrar aqui em vez de espalhar por componente escopado é a peculiaridade desta skill em relação a `/componente`: numa família composta comum a regra de negócio se distribui pelas partes; numa tela, a regra de orquestração mora na rota, e as seções (`_components/`) só cuidam da própria apresentação + do que é genuinamente delas.

Nunca: parse de filtro cru no JSX da rota sem passar por schema, ou lógica que pertence só a UMA seção específica (isso fica na própria seção, não na rota) — mas mutation, handler que decide entre 2+ seções, e navegação seguem concentrados na rota mesmo.

**Prop drilling mínimo mesmo na rota (ver regra em `/componente`):** a rota não deve calcular dado de servidor e empurrar pronto pra cada seção como prop. Se uma seção precisa de `order`/`addresses`/`quotes`, ela chama a mesma `queryOptions` sozinha (cache hit, zero custo extra) — a rota só passa como prop o que é genuinamente uma decisão externa (callback de mutation, `open`/`onOpenChange` de modal). A rota ainda pode ler as mesmas queries pra sua PRÓPRIA lógica (ex: decidir se o botão "Continuar" fica habilitado, montar o payload de uma mutation) — isso não é prop drilling, é uso legítimo do cache compartilhado pra decisão que só a rota toma.

**O `loader` nunca chama o fetcher do orval direto e nunca devolve o dado via `return`/`useLoaderData()`.** Isso bypassa o cache do Query inteiro (sem `queryKeys`, sem invalidação, dado duplicado fora do TanStack Query — exatamente o que a seção 4 proíbe). O `loader` sempre popula o cache via `context.queryClient.ensureQueryData(algumaQueryOptions)`, e o componente lê a **mesma** `queryOptions` por `useApiQuery` (seção 4) — cache hit, zero refetch, já que o dado foi desidratado do SSR:

```tsx
export const Route = createFileRoute("/produtos/")({
  loader: ({ context, deps }) => context.queryClient.ensureQueryData(findAllProductsQueryOptions(deps)),
  validateSearch: zodValidator(productsSearchSchema),
  component: ProductsPage
});

function ProductsPage() {
  const search = Route.useSearch();
  const { data: products } = useApiQuery(findAllProductsQueryOptions(search));

  return (
    <Content>
      <ProductsFilters search={search} />
      <ProductsTable products={products ?? []} />
    </Content>
  );
}
```

Se a query é privada (`meta.requiresAuth`, seção 4), o `loader` usa `ensureApiQueryData(context.queryClient, algumaQueryOptions)` em vez de `ensureQueryData` puro — mesmo gate de auth do `useApiQuery`, aplicado no SSR, pra visitante anônimo numa rota autenticada não tomar 401 no primeiro render.

## 2. Componentes tratam sua própria lógica e buscam seu próprio dado

Cada componente filho é dono da sua própria lógica de interação — a rota nunca reimplementa isso — e, seguindo a regra de prop drilling mínimo de `/componente`, busca sozinho qualquer dado que já está (ou pode estar) no cache do TanStack Query, em vez de recebê-lo pronto via prop:

- `ProductsFilters` trata seu próprio parse de input, debounce, e sincroniza pra URL (via `navigate`/`useSearch`).
- `ProductsTable` trata sua própria ordenação client-side, seleção de linha, paginação visual; se precisa do dado de `findAllProductsQueryOptions`, chama `useApiQuery` com a mesma `queryOptions` que o loader já populou — não recebe `products` como prop da rota.
- `ProductsTabs` trata sua própria troca de aba.

Prop, nesse contexto, fica reservada pro que só a rota (ou quem monta a árvore) pode decidir: callback de mutation, `open`/`onOpenChange` de modal, `id` vindo da URL quando o componente não tem como ler `useParams` sozinho. Comunicação entre esses componentes e a URL/rota é via callback/`navigate` pra cima, nunca um estado global paralelo dessincronizado da URL.

## 3. Escopado → Grupo de rotas → Global (decisão obrigatória pra todo componente/helper/schema novo, sobe um nível de cada vez)

Antes de criar qualquer componente, helper ou schema Zod da tela, decida onde ele mora. **A decisão sobe um nível de cada vez, conforme o reuso real observado — nunca pula direto pro topo (Global) só porque "pode ser que outra tela use algum dia".** Essa decisão é autônoma — evidência concreta de reuso, não hipótese distante — e só é perguntada ao usuário quando genuinamente ambígua mesmo depois de checar o reuso real (ver seção 6).

Três níveis, do mais restrito ao mais amplo:

1. **Escopado à tela.** Só esta tela usa, hoje. Vai em `src/pages/<rota>/_components/<nome>/` (componente), `src/pages/<rota>/_utils/<nome>.ts` (helper) ou `src/pages/<rota>/_schemas/<nome>.schema.ts` (schema Zod) — ao lado do `index.tsx` da rota. **Ponto de partida padrão** pra tudo que nasce numa tela nova.
2. **Escopado ao grupo de rotas.** Passou a ser usado por 2+ telas, mas só dentro do mesmo grupo de rota (ex: `src/pages/(autenticacao)/*` — todas as telas de login/senha) — nenhuma tela fora desse grupo usa nem tem razão plausível pra usar. Sobe pra `src/pages/(grupo)/_components/<nome>/`, `src/pages/(grupo)/_utils/<nome>.ts` ou `src/pages/(grupo)/_schemas/<nome>.schema.ts` — ao lado do `route.tsx` do grupo, um nível acima das telas individuais que o usam. Exemplo real: um schema Zod de estado de URL usado só por `entrar` e `primeira-senha` (ambas dentro de `(autenticacao)`) vai em `(autenticacao)/_schemas/`, não em `src/schemas/zod/`.
3. **Global.** Usado por telas de grupos diferentes, ou claramente genérico o bastante pra qualquer tela do app usar (um schema de paginação, um card de produto, um formatter de moeda). Vai em `src/components/<nome>/` (componente), `src/utils/<nome>.ts` (helper) ou `src/schemas/zod/<nome>.schema.ts` (schema Zod). Segue as mesmas regras de `/componente` e das convenções já estabelecidas em `src/utils/`/`src/schemas/zod/`.

**Regra de subida:** ao identificar que uma segunda tela precisa de algo que hoje é escopado, primeiro checa se as duas telas estão no mesmo grupo de rota — se sim, sobe só até o nível do grupo, não até Global. Só sobe até Global quando o reuso atravessa grupos diferentes ou quando o item é genérico o bastante pra qualquer tela (não precisa esperar uma terceira tela pedir, só precisa não fazer sentido preso a um grupo específico).

`_components/`, `_utils/` e `_schemas/` já são ignorados pelo gerador de rotas do TanStack Router (`tsr.config.json` e `vite.config.ts` → `routeFileIgnorePattern`) em qualquer nível da árvore de `src/pages/` — tanto dentro de uma tela quanto dentro de um grupo — então não viram rota por engano.

### Idioma: rota em português, componente/helper/schema em inglês (regra fixa, sem exceção)

- **Pasta da rota (`src/pages/<rota>/`) e o `path`/`id` passado pro `createFileRoute` ficam em português** — é o que vira URL, e URL amigável em português é mais fácil de navegar pro usuário brasileiro (ex: `src/pages/(autenticacao)/entrar/`, rota `/entrar`).
- **Todo componente, helper e schema fica em inglês** — nome de pasta, nome de arquivo e nome de export — independente de estar em `src/components/`/`src/utils/`/`src/schemas/zod/` (global) ou em `_components/`/`_utils/`/`_schemas/` (escopado dentro de uma rota em português). Isso vale mesmo quando o nome mais óbvio seria uma tradução literal da rota: dentro de `entrar/_components/`, o form de login chama `sign-in-form/` (export `SignInForm`), nunca `entrar-form/`.
- Rota em português + peça interna em inglês não é inconsistência — são dois vocabulários com público diferente: URL é pro usuário final, nome de arquivo/export é pro time de dev (convenção já usada no resto do código-fonte, em inglês).
- **Toda prop de componente/hook é sempre em inglês, sem exceção** — nome da prop, tipo, valor de enum/union literal, tudo. Vale mesmo quando o path/rota que consome é em português: uma prop nunca vira `passo`, `etapaAtual`, `pedidoId` só porque a pasta da rota é `pedido/$id` — sempre `step`, `currentStep`, `orderId`. Se o domínio de negócio tem um nome natural em português (ex: um id de etapa como `"produtos"`/`"entrega"`/`"pagamento"`), isso é dado (valor de string literal vindo de config/i18n), não prop nem export — ver `/componente`.

### Hook é sempre `.tsx` (regra fixa, sem exceção)

Todo arquivo de hook — global em `src/hooks/` ou escopado em `_utils/` — usa extensão **`.tsx`**, nunca `.ts`, mesmo quando o hook não tem nenhum JSX hoje (ex: `use-page-title.tsx`). Motivo: hook é ponto de extensão natural pra retornar/renderizar JSX depois, e trocar a extensão no meio do caminho quebra todo import que já apontava pro arquivo. Extensão uniforme evita esse churn.

Isso vale só pra hook. Helper puro, schema e constante continuam `.ts`.

**Helper nunca vive dentro do arquivo do componente que o usa** (salvo caso muito pontual e específico daquele componente, e mesmo assim vale reavaliar). Se a função é pura (não depende de props/estado do componente, só transforma um valor), ela segue esta mesma classificação de três níveis — nunca fica declarada solta no meio do componente "porque é rapidinho".

### Componentes escopados: estrutura de pasta

- **Tem 2+ partes coordenando estado** (ex: uma tabela com Root/Row/Cell compartilhando contexto de seleção)? Usa `/componente` normalmente, só que dentro de `_components/` em vez de `src/components/`.
- **É simples, uma peça só** (ex: um card de filtro sem subpartes)? Vira só `_components/nome-do-componente/index.tsx` — sem o aparato completo de Root/barrel separado, só a pasta com o arquivo de entrada.

```
src/pages/produtos/
  index.tsx
  route.tsx
  _components/
    products-filters/
      index.tsx                    → componente simples, peça única
    products-table/
      products-table-root.tsx      → compound, via /componente
      products-table-row.tsx
      index.ts
  _utils/
    parse-products-filters.ts
  _schemas/
    products-filters.schema.ts
```

## 4. SSR primeiro, client-side por último recurso

Todo fetch de dado da tela é desenhado primeiro pra rodar no `loader` da rota, via `ensureQueryData`/`ensureApiQueryData` (SSR/server-side) — é a estratégia padrão sempre que a stack permitir (TanStack Router + SSR). O `loader` só popula o cache; o componente sempre lê de volta via `useApiQuery` (seção abaixo), então mesmo dado "SSR-first" passa pelo TanStack Query, não vira `useLoaderData()` solto (ver exemplo da seção 1). Client-side puro (sem loader nenhum por trás) só entra como último recurso, quando SSR genuinamente não se aplica: dado que depende de API só de browser, atualização em tempo real pós-interação, conteúdo atrás de gate client-only, etc.

**Toda busca de dado — SSR-first ou client-only — passa por TanStack Query** (`useApiQuery` pra leitura, `useMutation` pra escrita) — nunca `useState` + `fetch`/chamada direta ao service + `try/catch` na mão pra controlar loading/erro. O `QueryClient` já está disponível na árvore (ver `src/shared/query-client.ts` + integração SSR-Query no router) e já centraliza tratamento de erro (toast automático via `mutationCache`/`queryCache`, com `meta: { ignoreError: true }` pra quando o componente já mostra o próprio erro inline). Reimplementar esse controle na mão com `useState` é o tipo de erro que esta skill não aceita, mesmo em caso pontual.

**Toda `queryKey`/`mutationKey` (e todo `invalidateQueries`/`removeQueries`/`setQueryData`/`getQueryData`/`fetchQuery`/`prefetchQuery`/`ensureQueryData` que referencia uma) usa obrigatoriamente `queryKeys(Query.X)` de `src/utils/query-keys.ts`, nunca array cru** (`["orders", id]`, `["addresses"]`, etc.). Fluxo: adiciona o membro correspondente em `Query` (`src/constants/enums/http/query.enum.ts`), usa `queryKeys(Query.X).all()` sem parâmetro ou `queryKeys(Query.X).withParams({ id, ... })` quando a key varia por argumento. **Nunca extraia a key numa constante local/exportada** (`const FOO_QUERY_KEY = queryKeys(Query.X).all()`) — cada call site chama `queryKeys(Query.X)...` diretamente; a constante existe só pra reintroduzir o mesmo problema com outro nome. Não existe exceção — se uma query/mutation nova (ou uma existente que a tela está tocando) não segue esse padrão, está errado e deve ser corrigido.

**Cada membro de `Query` tem o mesmo nome (em `SCREAMING_SNAKE_CASE`) do método exportado pelo service gerado pelo orval** (`src/services/v1/**`) — `findOrderById` → `FIND_ORDER_BY_ID`, `getAuthenticatedUserProfile` → `GET_AUTHENTICATED_USER_PROFILE`. Isso deixa óbvio, só de olhar o enum, qual chamada HTTP cada query representa. Exceção: query sem service orval por trás (chamada a SDK de terceiro tipo um provider externo, ou cache slot puramente interno tipo access-token) — nesse caso o nome só precisa ser descritivo, não tem o que espelhar.

### TanStack Query é a fonte única de verdade pra dado de servidor (regra fixa, sem exceção)

Qualquer dado que vem de uma chamada HTTP (pedido, endereço, perfil do usuário, pedidos pendentes, etc.) vive **só** no cache do TanStack Query — nunca duplicado em zustand, Context API ou `useState` global. Store/Context só existe pra estado genuinamente client-only, sem contrapartida de API: modal aberto, tab selecionada, valor de input antes de aplicar filtro, tema. Duplicar dado de servidor numa store paralela é o tipo de bug que essa regra elimina: a store dessincroniza do cache e ninguém percebe até dar comportamento errado em produção. Se uma tela precisa saber se o usuário está autenticado, ler o perfil, etc., a resposta é sempre uma query lida do cache (`useSession()`, ver abaixo) — nunca um campo `isAuthenticated`/`user` numa store espelhando o que já está no cache.

### `useApiQuery` é o hook de leitura obrigatório — nunca `useQuery` direto (regra fixa, com 1 exceção)

Toda leitura de query numa tela usa `useApiQuery` (`@/hooks/use-api-query`), nunca `useQuery` de `@tanstack/react-query` importado direto. O ESLint já bloqueia esse import (`no-restricted-imports` em `eslint.config.js`) fora dos 2 arquivos que são a exceção estrutural (`src/hooks/use-api-query.ts` e `src/services/auth/use-session.ts` — o caso-base: `useSession` não pode depender de `useApiQuery` porque `useApiQuery` depende de `useSession` pra decidir o gate, seria recursão). `useMutation`/`useQueryClient` não têm essa restrição, só `useQuery`.

Motivo de existir: antes do `useApiQuery`, toda tela que lia dado de rota autenticada tinha que montar sua própria corrente manual de `enabled` (`accessToken` → `enabled` do profile → `enabled` da query real) — e bastava uma tela esquecer esse encadeamento pra um visitante anônimo tomar 401 na cara (foi um bug real do projeto). `useApiQuery` resolve isso na raiz: ele lê `meta.requiresAuth` da própria `queryOptions` e aplica o `enabled` sozinho, então esquecer o gate deixa de ser possível — a exigência de auth viaja com a query, não com quem a lê.

**Query privada — que só faz sentido pra usuário autenticado (pedido, endereço, perfil, pedidos pendentes) — declara isso na própria `queryOptions`, nunca no call site:**

```ts
export const findAllAddressesQueryOptions = queryOptions({
  queryFn: async () => (await getAddresses().findAllAddresses()).data,
  queryKey: queryKeys(Query.FIND_ALL_ADDRESSES).all(),
  meta: { requiresAuth: true }
});
```

No componente, é só `useApiQuery(findAllAddressesQueryOptions)` — anônimo nunca dispara a chamada (`enabled: false`), sem estourar erro na tela, sem toast. Query pública (catálogo, produto, vitrine) não leva `meta.requiresAuth` — `useApiQuery` funciona igual a `useQuery` nesse caso, então usa ele por padrão mesmo pra dado público (uniformidade: um hook só pra decidir).

**Pra saber se o usuário está logado, ou ler o perfil/dado do usuário atual, o hook é `useSession()`** (`@/services/auth/use-session.ts`) — único lugar do app que responde "está autenticado?", devolve `{ isAuthenticated, accessToken, user }` lendo só do cache. Nunca reimplementa essa checagem lendo `accessTokenQueryOptions`/`getAuthenticatedUserProfileQueryOptions` na mão numa tela nova.

**No `loader` da rota, o mesmo gate existe via `ensureApiQueryData`** (`@/services/queries/utils/ensure-query-data.util.ts`) — usa no lugar de `context.queryClient.ensureQueryData` sempre que a `queryOptions` for `requiresAuth`. Sem isso, visitante anônimo numa rota autenticada recebe 401 no SSR em vez de um fallback tratado (ver exemplo da seção 1).

### `src/services/queries/`: uma pasta por query, nome e assinatura espelham o orval

Toda query com um fetcher real (chamada HTTP de verdade, não estado client-only) mora em `src/services/queries/<nome-do-metodo-orval>/<nome-do-metodo-orval>.query.ts`, nunca inline dentro do componente e nunca atrás de um hook customizado (`useAlgumaCoisa`) — hook wrapper só reintroduz a duplicação que a regra acima proíbe, e esconde a query de quem só quer `useApiQuery` direto.

- **Pasta e export espelham o método exportado pelo service orval que a query consome**: `getOrders().findOrderById` → pasta `find-order-by-id/`, arquivo `find-order-by-id.query.ts`, export `findOrderByIdQueryOptions`. Sufixo do export é sempre `QueryOptions`.
- **A assinatura da função exportada espelha a assinatura do método orval** (mesma ordem de parâmetros, mesmo tipo de params já gerado pelo orval quando existir) — nunca inventa uma interface própria pra reagrupar os mesmos parâmetros que o orval já exporta tipado. Método sem parâmetro (só `options?`) vira um objeto `queryOptions({...})` direto, sem função wrapper.
- Definido com `queryOptions()` do `@tanstack/react-query` — reutilizável igual em qualquer lugar via `useApiQuery(x)`, `queryClient.prefetchQuery(x)`, `queryClient.fetchQuery(x)`, `ensureApiQueryData(queryClient, x)` no loader, e `invalidateQueries({ queryKey: x.queryKey })` (ou `x(params).queryKey` quando a query tem parâmetro).
- Helper que não é o `queryFn` em si (selector, formatter, cálculo sobre o resultado da query) vai em `<pasta-da-query>/utils/<nome-descritivo>.util.ts` — nome sempre descreve o que a função faz (`get-pending-cart.util.ts`, não `helper.ts`).
- Query sem service orval por trás (chamada a SDK direto, ex. um provider externo) segue a mesma estrutura de pasta, só sem a obrigação de espelhar nome/assinatura de um método que não existe.

**Ação que orquestra 2+ queries ao mesmo tempo (ex.: `revokeSession` limpando cache de pending-orders + order + whoami + access-token de uma vez) nunca vira `util` dentro da pasta de uma query específica** — isso esconderia que ela também mexe nas outras. Vira função solta em `src/services/<domínio>/<nome-da-ação>.ts` (ex.: `src/services/auth/revoke-session.ts`, `src/services/auth/restore-session.ts`), fora de qualquer pasta de query individual. Regra de decisão: se a função só deriva/lê dado de UMA query → `utils/` daquela query; se ela mexe (seta/invalida/remove) o cache de 2+ queries → `src/services/<domínio>/`.

Filtro/tab/paginação que devem ser compartilháveis ou sobreviver a refresh/voltar vão pro `validateSearch` da rota (schema Zod) — nunca em `useState` solto quando fazem sentido na URL. Estado que é puramente transiente de UI (ex: valor digitado antes de aplicar o filtro, expansão de linha de tabela) fica local no componente ou em `_utils/`, sincronizado pra URL só quando necessário (submit/debounce).

## 5. i18n: arquivo por domínio, chave sempre espelha a pasta/rota/componente

Todo texto visível da tela (título, label, placeholder, mensagem de toast, meta title) vai pro i18n — nunca string literal solta no JSX. Os arquivos de tradução em `src/i18n/locales/pt-BR/` são separados por domínio, um arquivo por tipo, e cada domínio só entra no arquivo que é dele:

- **`pages.json`** — texto de tela/rota: tudo que só existe porque aquela página existe (título, descrição, campos de formulário da tela, mensagens de sucesso/erro específicas da tela).
- **`layouts.json`** — texto de layout/casca que envolve páginas (`route.tsx` de grupo, header/footer/shell), não pertence a nenhuma página individual. Vale também pra `_layout/` dentro de uma rota (ex: `pedido/$id/_layout/`) sempre que ele for compartilhado por 2+ telas filhas (produtos/entrega/pagamento/confirmado) — mesmo estando fisicamente dentro da pasta da rota, o texto dele é de casca, não de uma página específica, e vai em `layouts.json` com chave espelhando o nome do componente raiz do layout (`order-checkout-layout-root.tsx` → chave `order-checkout-layout`), nunca dentro de `pages.json`.
- **`components.json`** — texto de componente reutilizável (`src/components/`), nunca texto amarrado a uma tela específica.
- **`schemas.json`** — só quando existir mensagem de validação Zod que precisa de tradução (`error.string.required`, etc.) — se a tela não tem schema com mensagem traduzível, não cria/mexe nesse arquivo.

**A chave dentro do arquivo certo sempre espelha o nome da pasta/rota/componente que ela traduz** — não um nome arbitrário nem uma sigla. Uma tela em `src/pages/<rota>/entrar/` usa a chave `sign-in` (ou o nome equivalente em inglês do componente principal daquela tela, já que chave de tradução é identificador de código — mesma regra de idioma do componente, não do path da URL) dentro de `pages.json`, não uma chave desconectada do que existe no código. Ao criar uma tela nova: decidir a chave olhando pro nome do componente/schema escopado que ela serve (`sign-in-form` → chave `sign-in`), não inventar um nome novo desalinhado.

Cada tela nova registra sua própria chave em `pages.json` (`{ "sign-in": { ...} }`) — nunca reaproveita/estica a chave de outra tela pra economizar. Se a tela usa um schema com mensagem traduzível, essa mensagem vai em `schemas.json` sob uma chave também alinhada ao schema (`error.<domínio>.<regra>`), nunca dentro de `pages.json` misturado com o texto da tela.

## 6. Fluxo ao criar uma tela nova

1. Cria `src/pages/<rota>/index.tsx` com o esqueleto: `loader` (mesmo que só um fetch simples) + `validateSearch` (se houver filtro/tab/paginação) + `component` que só compõe.
2. Quebra a tela em seções/features. Pra cada uma, decide o nível (Escopado à tela / ao grupo / Global — seção 3) e cria na pasta certa.
3. Pra cada componente identificado como compound (2+ partes), invoca `/componente`.
4. Identifica helpers e schemas Zod necessários (parse, format, cálculo, validação de form/search) e decide o nível (Escopado à tela / ao grupo / Global — seção 3).
5. Todo texto visível vai pro i18n: chave nova em `pages.json` alinhada ao nome do componente principal da tela (seção 5) — nunca string solta no JSX nem chave emprestada de outra tela.
6. Garante que a busca de dado está no `loader`, não em efeito client-side, salvo justificativa clara de por que SSR não se aplica.
7. Revisa: `index.tsx` não tem lógica de interação nem regra de negócio vazando — só orquestração.

## 7. Quando perguntar ao usuário

Esta skill deve rodar de forma autônoma na maior parte do tempo — a escolha de nível (tela / grupo / global), a escolha entre componente simples ou compound, e o desenho SSR-first são decisões que a skill toma sozinha usando as regras acima. Só pergunta ao usuário quando:

- A escolha de nível é genuinamente ambígua mesmo depois de checar o reuso real (quantas telas usam, e se estão no mesmo grupo) — e mesmo assim, é o último recurso, não o primeiro. Reuso hipotético ("pode virar padrão de outras telas, mas não há sinal nenhum disso ainda") nunca justifica subir de nível sozinho; só reuso observado sobe.
- Surge uma decisão de arquitetura fora do que esta skill cobre (ex: escolha de biblioteca nova, mudança de padrão de state management, algo que não é "onde colocar este arquivo" nem "SSR ou client").

Fora desses casos, decide e segue — não trava o fluxo pedindo confirmação pra cada arquivo.

## 8. Layout novo com decisão de UI/UX → `/frontend-design`

Se a tela envolve criar ou repensar um **layout** onde há decisão real de UI/UX (hierarquia visual, composição nova, escolha estética, algo sem padrão óbvio já estabelecido no projeto), usa `/frontend-design` se disponível antes de sair implementando o layout. Se for só organização — mover/dividir seções que já têm visual definido, aplicar a estrutura de pastas desta skill, extrair componente sem mudar nada visualmente — não precisa, é puro trabalho mecânico.

## 9. Código fora do padrão desta skill

Ao mexer numa tela existente, qualquer componente/helper/arquivo que não segue o padrão estabelecido aqui (rota gorda com lógica vazando, componente global que devia ser escopado ou vice-versa, helper solto no lugar errado, etc.) deve ser corrigido pra seguir o padrão. Só quando o ajuste é ambíguo, arriscado, ou blast radius grande (ex: mover pasta já usada por várias telas, mudar API pública de algo compartilhado) — aí sim, último recurso, pergunta ao dev o que fazer em vez de decidir sozinho.

## 10. Lint, build e teste (regra fixa)

Nunca rodar lint, build ou o comando de teste automaticamente depois de criar/ajustar a tela. Isso é decisão do dev — ele roda antes do commit, no momento que quiser. Só rodar teste se o dev pedir explicitamente pra testar.

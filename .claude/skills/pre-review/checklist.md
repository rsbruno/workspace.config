# checklist do pre-review

Procedimento completo. Orçamento: **6 chamadas de ferramenta**. Gaste-as assim: 1 coleta, 1 verificação, 2–3 correções, 0 sobra. Nunca leia um arquivo que o diff já mostrou.

## 1. Coleta (UMA chamada de bash, exatamente esta)

`lefandom.web` e `lefandom.api` são repos git independentes; a raiz não é repo. Substitua `REPOS` pelo alvo pedido.

```bash
cd <raiz>
for R in <REPOS>; do
  [ -d "$R/.git" ] || continue
  echo "########## $R"
  git -C "$R" status --porcelain=v1 -uall | grep -vE 'pnpm-lock|/routes/index.ts|src/services/v1|drizzle/migrations'
  echo "########## DIFF $R"
  git -C "$R" diff HEAD -- . ':(exclude)src/routes/index.ts' ':(exclude)src/services/v1' \
    ':(exclude)drizzle/migrations' ':(exclude)pnpm-lock.yaml' ':(exclude)README.md' | head -700
  echo "########## UNTRACKED $R"
  for f in $(git -C "$R" ls-files --others --exclude-standard | grep -E '\.(ts|tsx)$' | grep -vE 'src/services/v1|/routes/index.ts'); do
    echo "----- $R/$f"; cat -n "$R/$f" | head -120
  done
done
```

Arquivo gerado por ferramenta **nunca** entra no review: `src/routes/index.ts` (tsr), `src/services/v1/**` (orval), `drizzle/migrations/**` (drizzle-kit), `pnpm-lock.yaml`, `dist/`.

JSON de i18n: julgue pelo diff, não abra o arquivo inteiro.

Se sobrou arquivo truncado pelo `head`, diga no relatório em vez de gastar chamada relendo.

## 2. Lado

- `nest-cli.json` na raiz do repo → **back**
- `vite.config.ts` + `tsr.config.json` → **front**

## 3. Verificação (UMA chamada de bash, greps agrupados)

Todo achado precisa de evidência. Junte num único bash todos os greps que precisar — nunca um por chamada:

```bash
cd <raiz>/<repo>
echo "== import de X =="; grep -rn "NomeDoExport\|caminho/do/arquivo" src --include="*.ts" --include="*.tsx" | grep -v "o-proprio-arquivo"
echo "== duplicata de Y =="; grep -rn "trecho-caracteristico" src --include="*.ts" --include="*.tsx"
```

Sem evidência = não reporta, ou marca **suspeita** dizendo o que falta.

Pra cruzar `meta.requiresAuth` (regra do item 4) sem gastar chamada extra: junte no mesmo bash de verificação um grep pela URL do endpoint (a string em `getX().findY` → veja a `url:` no arquivo gerado do orval, ex. `src/services/v1/orders/orders.ts`) direto nos controllers do `lefandom.api` (`grep -rn "rota-do-endpoint" ../lefandom.api/src --include="*.controller.ts"` a partir da raiz do monorepo) e confira se o método tem guard de auth. Só faça isso pras queries que o diff realmente tocou — não varra todas as queries do projeto.

Falso positivo comum: arquivo de rota (TanStack Router) e módulo NestJS registrado por convenção não têm import explícito — não são código morto.

## 4. Checklist FRONT (`lefandom.web`)

**Estrutura**
- Rota (`src/pages/<rota>/index.tsx`) fina: só `loader`, `validateSearch`, `component` compondo. Lógica de interação/parse/regra de negócio na rota = violação.
- Nível certo, sem pular degrau: nasce em `_components/`/`_utils/`/`_schemas/` da tela → sobe pro grupo (`(grupo)/_components/`) com 2+ telas do mesmo grupo usando → só vira global (`src/components/`, `src/utils/`, `src/schemas/zod/`) atravessando grupos ou sendo genérico. Global com consumidor único = violação (confirme com grep).
- Pasta de rota em **português**; pasta/arquivo/export de componente, helper, hook e schema em **inglês**.
- **Hook é sempre `.tsx`, nunca `.ts`** — mesmo sem JSX. Exceção: `context.ts` de componente composto. Helper puro, schema e constante seguem `.ts`.
- Componente com 2+ partes coordenando estado segue `/componente`: arquivo por parte, kebab-case, export achatado (`ComponentNameRoot`, nunca `ComponentName.Root`), `index.ts` como único ponto de import externo.
- Helper (função pura, sem JSX) declarado dentro do arquivo do componente = violação.

**Dado e estado**
- Busca de dado no `loader` (SSR). Client-side só com motivo real e **sempre** via TanStack Query. `useState` + `fetch`/service na mão controlando loading/erro = violação.
- Filtro/tab/paginação compartilhável em `useState` em vez de `validateSearch`/URL = violação.
- **🔴 `queryKey`/`mutationKey` cru — regra fixa, sempre bloqueante.** Toda `queryKey`, `mutationKey`, e todo `invalidateQueries`/`removeQueries`/`setQueryData`/`getQueryData`/`fetchQuery`/`prefetchQuery`/`ensureQueryData` usa `queryKeys(Query.X)` de `src/utils/query-keys.ts`, chamado direto no call site. Array literal (`["orders", id]`) **ou constante local/exportada** (`const FOO_QUERY_KEY = queryKeys(Query.X).all()` reexportada e importada em outro arquivo) = 🔴 BLOQUEIA. Corrija: adicione o membro em `Query` (`src/constants/enums/http/query.enum.ts`) e troque pela chamada `queryKeys(Query.X).all()`/`.withParams({...})` direto onde a key é usada, sem constante intermediária.
- **🔴 `meta.requiresAuth` tem que espelhar o endpoint real — regra fixa, sempre bloqueante.** Toda `queryOptions` nova ou tocada em `src/services/queries/**` que chama um método do orval (`src/services/v1/**`) precisa refletir se aquele endpoint exige sessão. O orval não carrega essa informação no fetcher gerado — confirme no controller do `lefandom.api` (mesma URL/método do fetcher) se a rota tem guard de auth (`@UseGuards(...)` equivalente) e não tem `@Public()`/equivalente liberando anônimo. Rota autenticada no back sem `meta: { requiresAuth: true }` na `queryOptions` do front = 🔴 BLOQUEIA — é a classe exata de bug que gerava 401 pra usuário anônimo e cache vazando dado de sessão anterior. Rota pública no back com `meta.requiresAuth: true` sobrando no front também é achado (🟡 AJUSTA: gate desnecessário, bloqueia leitura de dado que devia ser livre). Se o review é só de `lefandom.web` e o `lefandom.api` não está disponível pra cruzar, não adivinhe: marque como suspeita (`🟡 NÃO REVISADO: confirmar guard de auth em <endpoint> no back antes de aprovar`), nunca assuma público nem privado sem checar.

**Componente**
- Reusa primitivo de `src/components/ui` em vez de HTML cru; não sobrescreve estilo do primitivo por fora (className conflitante, `!important`, cor literal).
- Zero comentário em componente.
- Sem import deprecado (`ElementRef` → `ComponentRef`), sem `as any`/`as never`/`as unknown` mascarando tipo.

**i18n**
- Zero string literal visível no JSX — inclusive `alt` e `aria-label`.
- Arquivo por domínio: `pages.json` (tela), `layouts.json` (layout/grupo), `components.json` (componente reutilizável), `schemas.json` (validação). Chave espelha a pasta/rota/componente.
- Chave usada que não existe no JSON quebra em runtime e o type-check não pega — confira as chaves novas do diff.
- Nome da marca vem de `layouts:tenant.name`, nunca hardcoded.

## 5. Checklist BACK (`lefandom.api`)

- **🔴 Saída do back é prop a prop — regra fixa, sempre bloqueante.** Escrita em banco (`.values()`, `.set()`) e envio pra integração externa (comando de SDK, body HTTP, chamada a serviço externo de qualquer tipo) montados campo a campo. `{ ...payload }` cruzando essa fronteira = 🔴 BLOQUEIA, nunca rebaixe pra 🟡 ou 🔵. Campo opcional usa `campo: cond ? v : undefined`, nunca spread condicional. Spread interno (handler → controller, `[...handlers]` no módulo) é permitido e não é achado. Grep pra achar candidato: `\.\.\.(payload|dto|command|data|input)\b` dentro de `.values(`, `.set(`, `new \w+Command(`, chamada de client/SDK.
- Nomenclatura: listagem = `findAll...`; busca por prop = `find...`. Nunca `get...`/`fetch...`.
- Camadas isoladas: domain não importa infrastructure; DTO de domínio separado do raw do provider; mapeamento via `@Transform` + `plainToInstance`, não função `map...` manual.
- Um caso de uso por service de integração.
- CQRS: repository de leitura e escrita separados; handler sem regra de negócio vazando pro controller.
- Provider/handler novo registrado no módulo (falta disso só quebra em runtime).
- Segredo, credencial ou URL de ambiente hardcoded em vez de `ConfigService`.

## 6. Checklist comum

**Morto** — export não consumido, função/variável/estado/prop não usado, import não usado, branch inalcançável, chave i18n órfã, dependência no diff sem import, arquivo sem nenhum importador (confirmar com grep).

**Duplicação** (o mais valioso) — pra cada helper, componente, schema, hook ou constante novo, procure equivalente que já existe. Busque por **comportamento**, não por nome: a duplicata quase sempre tem nome diferente. Típicos: formatador recriado, componente que já existe em `src/components/ui`, schema Zod repetido, lista de constante replicada.

**Lógica mal resolvida**
- Promise sem `await` e sem `.catch()` em callback — `mutateAsync` solto rejeita e vira unhandled rejection; o certo é `mutate`.
- Erro engolido (`catch {}`, `catch { throw error }`), `async` sem await.
- `||` onde precisa `??`; borda `<` vs `<=`; off-by-one.
- Estado derivado em `useState` em vez de calculado; efeito com dependência faltando.
- Ordem que deixa estado inconsistente se o passo seguinte falhar (grava no banco antes de confirmar chamada externa).
- `null`/`undefined` tratado como garantido (`!` gratuito).
- Env opcional com fallback `?? ""` que degrada em silêncio.

## 7. Corrija o que é mecânico

Corrija sozinho, seguindo a arquitetura do projeto, quando a correção for **óbvia e de escopo fechado**:

- mover arquivo pro nível certo e atualizar os imports que apontavam pra ele;
- renomear arquivo/export pra convenção (inclusive hook `.ts` → `.tsx`);
- extrair string literal do JSX pro JSON de i18n do domínio certo;
- trocar `mutateAsync` solto por `mutate`;
- adicionar/remover `meta: { requiresAuth: true }` numa `queryOptions` quando o guard do endpoint no `lefandom.api` já foi confirmado (regra do item 4) — é troca de uma linha, sem ambiguidade quando a confirmação existe;
- desmontar `{ ...payload }` em escrita de banco ou chamada externa pra campo a campo (regra do item 5, sempre corrigir quando os campos do objeto de origem estiverem visíveis no arquivo — se o tipo vem de outro arquivo e não dá pra confirmar os campos sem gastar chamada extra, reporte em vez de arriscar corrigir errado);
- remover import, variável, prop, export ou chave i18n não usados;
- trocar valor hardcoded por constante/chave que já existe (ex: nome da marca → `layouts:tenant.name`);
- extrair helper declarado dentro do componente pro arquivo certo.

**Não corrija — só reporte:**

- qualquer coisa que exija decisão de produto, de API ou de arquitetura;
- deduplicação que muda assinatura pública ou mexe em 3+ arquivos além do movimento;
- reescrita de lógica cuja intenção não está clara no código;
- achado marcado como suspeita.

Ao corrigir: edite, confira que nenhum import ficou apontando pro caminho antigo (grep na mesma chamada de verificação) e registre no relatório. **Nunca** rode lint/build/tsc pra validar — não é permitido.

## 8. Saída

Só o que muda a ação de quem lê. Nada de seção "fora do escopo", nada de listar o que não rodou, nada de narrar quantas chamadas usou, nada de confirmar o que estava OK — se um arquivo foi cortado pelo `head` mas não tinha nada relevante, não mencione o corte.

```
## <repo>

### Corrigido
caminho/arquivo.tsx:42 — <o que estava errado> → <o que foi feito>.

### Pendente
caminho/outro.tsx:8 — 🔴 BLOQUEIA: <defeito>. <correção>. Não corrigi: <motivo>.
caminho/mais.ts:15 — 🟡 AJUSTA: <defeito>. <correção>. Não corrigi: <motivo>.

**Veredito:** <pronto pra commit | N bloqueios pendentes>
```

Se um arquivo relevante (auth, pagamento, escrita em banco) ficou truncado pelo `head -700` e você não conseguiu ler o resto dentro do orçamento de chamadas, **isso sim** entra — como um pendente, não como nota de rodapé: `caminho/arquivo.ts — 🟡 NÃO REVISADO: arquivo cortado pelo corte de diff, releia antes de aprovar.`

Inclua 🔵 opinião só se for um achado específico e útil — não liste por completude, e não vire seção separada se não tiver nada.

Severidade: 🔴 **BLOQUEIA** = bug real, quebra em runtime, regra fixa violada, segredo exposto. 🟡 **AJUSTA** = padrão violado, duplicação, código/arquivo morto. 🔵 **OPINIÃO** = melhoria recusável.

Sem elogio, sem resumo do que o diff faz, sem "no geral está bom". Nada fora do diff, salvo se o diff quebrou aquilo.

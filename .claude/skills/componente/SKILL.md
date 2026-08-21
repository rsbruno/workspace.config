---
name: componente
description: Padroniza a criação de componentes React compostos — cada parte (Root, Trigger, Content, Item...) em seu próprio arquivo dentro de uma pasta, com nomes de export sempre achatados (ComponentNameRoot, ComponentNameTrigger — nunca dot notation como ComponentName.Root), nomes de PASTA e ARQUIVO sempre em kebab-case (component-name/component-name-root.tsx), e pasta/arquivo/export sempre em INGLÊS mesmo quando a rota que consome o componente é em português (rota é URL pro usuário final, componente é vocabulário de código), e o index.ts da pasta como único ponto de import permitido — nenhum arquivo interno pode ser importado diretamente de fora. Antes de criar qualquer parte, avalia se ela realmente pertence ao escopo desta família (depende do Context/Root) ou se é algo genérico — nesse caso reaproveita de onde já existe no projeto ou extrai pra uma pasta própria e isolada, nunca enterra dentro da família por engano. Nenhum comentário deve ser escrito em nenhum arquivo, nunca — nem em index.ts, nem pra explicar regra de negócio, nem decisão de padrão; nome descritivo resolve o que comentário resolveria. Sempre TypeScript, nunca `forwardRef` — projeto usa React 19, onde `ref` é uma prop normal recebida direto na assinatura da função, sem wrapper. Sempre reaproveita os primitivos de `src/components/ui` (Typography, Button, etc.) em vez de recriar HTML cru, resolvendo cada necessidade pelas props que o primitivo já expõe — nunca sobrescrevendo o estilo já definido por fora (className conflitante, `!important`, cor literal). Se o primitivo necessário não existir, ou se a variante/prop necessária não existir nele, para e pergunta ao usuário antes de criar/forçar algo novo. Prioriza `asChild` via `@radix-ui/react-slot` pra evitar wrappers desnecessários no DOM, mas decide caso a caso em vez de aplicar automaticamente em toda parte. Evita Context API por padrão — só usa quando tecnicamente necessário (partes que não são filhas diretas do Root, ou muitos consumidores desacoplados) ou quando pedido explicitamente; prefere composição via cloneElement/Children. Prop pública de negócio (não-`className`) só existe no Root — nunca redrilled em filho; se a família tem variant própria, é resolvida uma vez no Root com `tv({ slots, variants })` (`tailwind-variants`) e cada filho lê sua função de slot via Context, nunca recebendo a variant como prop. Todo texto visível vai pro i18n em `components.json` (nunca `pages.json`/`layouts.json`, que são de outro domínio), com chave espelhando o nome do componente. Sempre escrito pensando em performance e escalabilidade (memoização, evitar re-renders desnecessários). Nunca usa `forwardRef`/`ComponentRef`/`ElementRef` (ref é prop normal via `ComponentProps<...>`, React 19) nem cast (`as never`/`as any`/`as unknown`) pra mascarar erro de tipo — tipo que não fecha se corrige na origem, não com cast por cima. Use esta skill sempre que o usuário pedir para criar, refatorar ou estruturar qualquer componente React composto por múltiplas partes relacionadas (dropdowns, modais, tabs, accordions, popovers, forms multi-etapa, cards com header/body/footer, etc.), mesmo que ele não use literalmente o termo "compound component". Consulte esta skill antes de escrever qualquer novo componente React com mais de uma parte interna trabalhando junto. NÃO é auto-invocável — só usar quando o usuário mencionar explicitamente esta skill/o comando `/componente`, ou quando outra skill (ex: `/pagina`) chamar por ela, nunca por inferência sozinha.
---

# React Compound Components

Padrão de referência para todo componente React composto. Sempre TypeScript. Cada parte do componente vive no seu próprio arquivo, mas **o consumo externo nunca aponta pra esses arquivos** — só pro `index.ts` da pasta. Nomes de **export** sempre achatados: `ComponentNameRoot`, `ComponentNameTrigger`, `ComponentNameContent` — nunca `ComponentName.Root`. Nomes de **arquivo** sempre kebab-case (ver seção "Convenções de nomenclatura").

Seis regras que atravessam tudo o resto: **sempre reaproveitar os primitivos de `src/components/ui`** (ver seção própria logo abaixo), **evitar Context sempre que der** (ver seção própria mais adiante), **prop drilling mínimo — todo componente recebe só o mínimo de props possível** (ver seção "Prop drilling mínimo" logo abaixo), **escrever sempre pensando em performance** — nada de re-render em cascata, objetos recriados à toa, ou componente que não escala quando a lista/árvore cresce —, **comentar só regra de negócio, nunca decisão mecânica** (ver seção própria logo abaixo), e **nunca usar import deprecado nem cast que mascara erro de tipo** (ver seção "Tipagem sem atalho" logo abaixo da seção de Tipagem de props).

## Comentários (regra fixa, vale pra todo arquivo do componente)

**Nenhum comentário deve ser escrito. Nunca.** Nem explicando decisão de padrão, nem regra de negócio, nem propósito de arquivo — nada. Todo o código tem que se explicar sozinho pelo nome de variável, função, arquivo e pasta. Se sentir vontade de comentar alguma coisa, é sinal de que o nome escolhido não é descritivo o suficiente — resolve renomeando, não comentando.

## Reuso de `src/components/ui` (obrigatório, checar antes de escrever qualquer parte)

Antes de escrever o JSX de qualquer parte do componente (Root, Trigger, Content, Item...), checar o que já existe em `src/components/ui` e usar de lá em vez de recriar na mão:

- Texto (título, label, descrição, qualquer `<p>`/`<span>`/`<h*>` com estilo) → `Typography` (`src/components/ui/typography.tsx`), nunca tag HTML crua com classe de fonte.

**Nenhum texto ou número solto fora de `Typography` (`src/components/ui/typography.tsx`), em nenhuma parte do componente.** Todo conteúdo textual/numérico visível — título, label, descrição, contador, badge de quantidade, preço, qualquer caractere que o usuário vai ler — sempre passa por `Typography`, nunca fica cru dentro de `<span>`/`<p>`/`<div>`/`{variavel}` solto no JSX. Vale até pra conteúdo curto tipo contador de badge (`{itemCount}`) ou símbolo (`×{quantity}`) — mesmo um número de 1 dígito entra em `Typography`, resolvendo tamanho/peso pelas props (`size`, `variant`) em vez de className manual.
- Botão/ação clicável → `Button` (`src/components/ui/button.tsx`).
- Avatar, separador, skeleton, spinner, drawer, loading, toast → os equivalentes já existentes em `src/components/ui/` (`avatar.tsx`, `separator.tsx`, `skeleton.tsx`, `spinner.tsx`, `drawer.tsx`, `loading.tsx`, `toast.tsx`).
- Wrapper de largura máxima / container de página → `Content`/`Container` (`src/components/ui/content/`).

**Se a parte que está sendo construída precisa de um primitivo que não existe em `src/components/ui`** (ex: não existe `Input`, não existe `Select`, não existe `Checkbox`) — não criar um novo componente por conta própria nem improvisar com HTML cru como solução definitiva. Parar e perguntar ao usuário: falar explicitamente qual primitivo está faltando, e perguntar se ele quer que (a) esse primitivo seja criado em `src/components/ui` primeiro (e reaproveitado dali), (b) uma lib externa seja usada pra isso, ou (c) resolver ali mesmo, pontual, sem virar primitivo novo. Só seguir depois da resposta.

**Usar o primitivo pelas props que ele já expõe, nunca sobrescrever o estilo que ele já define.** Se `Typography` tem `variant`/`color`/`size`, resolver a necessidade escolhendo entre essas props — não empilhar `className` com `!important`, cores literais, ou utilitário que conflita/sobrepõe o que o componente já decidiu (ex: passar `className="text-red-500"` num `Typography` que já define cor pela prop `color`). Se a variação que a parte precisa genuinamente não existe nas props do primitivo (ex: falta um `size` ou `variant` novo), não forçar por fora — parar e perguntar ao usuário se: (a) adiciona essa variante nova ao primitivo em `src/components/ui` (e todo mundo que já usa o primitivo ganha a opção), ou (b) resolve pontual, sabendo que ali é uma exceção ao padrão. Só seguir depois da resposta.

## Reuso de `src/components/utils` (obrigatório, checar antes de escrever qualquer parte)

Antes de escrever renderização condicional, lista ou tratamento de erro em qualquer parte do componente, checar o que já existe em `src/components/utils` e usar de lá em vez de reimplementar na mão (`if` dentro do JSX, `&&`, ternário solto, `.map` cru):

- Renderizar algo só se uma condição for true → `ShowIf` (`src/components/utils/show.tsx`), prop `if`. Vale pra todo `if`/`&&`/ternário de renderização condicional simples dentro de uma parte do componente — nunca `condition && <X/>`, `condition ? <X/> : null` ou um `if (condition) return <X/>` cru no meio do JSX; sempre `<ShowIf if={condition}><X/></ShowIf>`. **Vale também pro ternário either/or** (`condition ? <X/> : <Y/>`, as duas pontas renderizam algo, não `null`) — nunca deixar esse ternário cru no JSX; sempre dois `<ShowIf>` com condição negada entre si: `<ShowIf if={condition}><X/></ShowIf>` seguido de `<ShowIf if={!condition}><Y/></ShowIf>`.
- Renderizar lista com suporte a loading (skeleton repetido), limite de itens e componente extra ao atingir o limite → `ForEach` (`src/components/utils/foreach.tsx`). Vale pra todo loop de renderização entre componentes — nunca `.map()` cru solto no JSX; sempre `<ForEach items={...}>{(item) => <X/>}</ForEach>`.
- Renderizar algo só quando um erro específico (por `code`) ocorreu → `ShowExceptionIf` (`src/components/utils/show-exception.tsx`).

Mesma regra dos primitivos de UI: se o caso genuinamente não é coberto por nenhum desses (não é condicional simples, não é lista, não é erro por código), não forçar encaixe — resolver pontual ou parar e perguntar ao usuário se vale estender/criar um novo helper em `src/components/utils`.

## i18n: texto sempre em `components.json`, chave espelha o nome do componente

Nenhuma parte da família escreve string de texto visível (label, título, mensagem, placeholder) literal no JSX — sempre via i18n. Componente reutilizável (`src/components/`) usa `components.json` em `src/i18n/locales/pt-BR/` — nunca `pages.json` (esse é só pra texto de tela) nem `layouts.json` (só pra casca de layout). Se o componente é escopado a uma tela (`_components/` — ver `/pagina`), o texto que é exclusivamente dele ainda assim entra em `components.json` só se o componente for genuinamente reutilizável; texto que é da tela (não do componente em si) fica em `pages.json` sob a chave da tela, não duplicado dentro do componente.

A chave dentro de `components.json` sempre espelha o nome da pasta/componente (`product-review-card` → chave `product-review-card`, não uma chave genérica ou herdada de outro componente). Se o componente tem variant/mensagem de erro (ex: um `Alert` com texto de fallback), essa chave vive aninhada dentro da chave do componente, nunca solta na raiz do arquivo.

## Quando aplicar

Aplicar sempre que o componente tiver 2+ subpartes que precisam compartilhar estado ou coordenar comportamento: Select, Modal, Tabs, Accordion, Dropdown, Popover, Stepper/Wizard, Card com Header/Body/Footer, Form multi-step, Table, Toast, etc.

Não aplicar para componentes simples e isolados (um Button avulso, um Badge) — isso seria over-engineering.

## Avaliar escopo antes de criar qualquer parte (fazer isso primeiro, antes de qualquer código)

Antes de criar um arquivo novo dentro da pasta da família, perguntar: **essa peça é de fato específica desta família, ou é algo genérico que não devia morar aqui?** Teste: ela só faz sentido dependendo do Context/Root desta família (um `Trigger` sozinho não significa nada fora do `Select`)? Se sim, pertence à pasta. Se ela funciona sozinha, sem depender do resto da composição, **não é uma parte da família — é um componente à parte**, e precisa ser tratado como tal:

- **Se esse componente genérico já existe em algum lugar do projeto** (`src/components/ui`, ou qualquer outra pasta de `src/components/`) — reaproveitar de lá, nunca duplicar dentro da pasta da família nova.
- **Se não existe ainda** — não enterrar dentro da pasta da família só porque foi percebido durante a construção dela. Extrair pra pasta própria, isolada, com nome descritivo do que ele realmente faz (mesma regra de nome descritivo que vale pro resto — ver "Convenções de nomenclatura"). Se esta família está sendo construída dentro de uma tela (`_components/` de uma rota — ver `/pagina`), a extração sobe só até onde o reuso real já está comprovado: outra família na mesma tela → mantém em `_components/` da tela; outra tela do mesmo grupo de rota → sobe pra `_components/` do grupo (`(grupo)/_components/`); só vira `src/components/` quando o reuso atravessa grupos diferentes ou é genuinamente genérico pra qualquer tela. Não pula direto pra `src/components/` sem essa checagem.
- **Na dúvida se algo pertence à família ou devia ser extraído/reaproveitado** — parar e perguntar ao usuário antes de decidir sozinho.

Isso vale durante toda a construção, não só no início: se no meio de escrever uma parte ficar claro que ela é genérica, corrigir a rota ali mesmo em vez de terminar e deixar pra depois.

## Slot: preferência forte, mas avaliada caso a caso

`asChild` + `Slot` (de `@radix-ui/react-slot`) evita empilhar wrappers desnecessários no DOM (`<div><div><button>...`), então é sempre a primeira opção a considerar pra qualquer parte que renderiza um elemento DOM próprio. **Mas não é uma regra fixa aplicada sem pensar** — avaliar em cada parte se faz sentido:

- Faz sentido na maioria dos casos: Trigger, Root, Item, qualquer parte cujo consumidor possa razoavelmente querer trocar a tag renderizada ou evitar um elemento a mais.
- Pode não fazer sentido: uma parte cujo elemento carrega comportamento/estilo tão específico que trocar a tag quebraria a semântica (ex: um `Content` que depende de ser exatamente um `<dialog>` pra funcionar), ou quando o overhead de mais uma prop opcional não se justifica pro que a parte faz.

Decidir isso na hora, olhando pra parte específica que está sendo escrita — não aplicar `asChild` automaticamente em toda parte só porque é o padrão preferencial.

```tsx
const Comp = asChild ? Slot : "div"; // ou "button", "span", etc. conforme a parte
```

Instalar `@radix-ui/react-slot` como dependência direta do projeto (`npm install @radix-ui/react-slot`) em vez de reimplementar Slot na mão, quando a decisão for usar Slot.

## Estrutura de pastas (padrão fixo)

```
components/component-name/
  component-name-root.tsx
  component-name-trigger.tsx
  component-name-content.tsx
  component-name-<outra-parte>.tsx
  component-name-fallback.tsx → skeleton/placeholder usado como `fallBack` do `ForEach` (ou equivalente) enquanto a família carrega — ver seção "Fallback de loading" abaixo
  styles.ts                  → tv({ slots, variants }) — única fonte de estilo/variant da família (só existe se a família tiver variant própria, ver seção "Variants e slots")
  context.ts                 → Context + hook use<ComponentName>Context + tipos do estado (e dos slots, se houver)
  index.ts                    → ÚNICO ponto de entrada público
```

### Fallback de loading (regra fixa, sempre que a família busca lista de dado assíncrono)

Se alguma parte da família renderiza uma lista vinda de query (`ForEach` com `isLoading`/`fallBack`), o skeleton de cada item vive em arquivo próprio **`component-name-fallback.tsx`**, export **`ComponentNameFallback`** — nunca uma função solta declarada no meio do arquivo da parte que a usa. Vale pra qualquer variante de fallback que a família precise (loading de item de lista, loading de estado vazio, etc.) — cada uma ganha seu próprio arquivo `component-name-<variante>-fallback.tsx` se houver mais de uma.

`ComponentNameFallback` só entra no `index.ts` (reexportado publicamente) se algum consumidor de fora da família genuinamente precisa compô-lo isolado (ex: reaproveitar o mesmo skeleton em outro lugar da tela antes da família montar). Caso contrário fica de fora do index — é implementação interna da parte que o usa (mesmo tratamento de `context.ts`), só existe como arquivo próprio pra não inchar o componente principal com JSX de skeleton misturado à lógica real.

Regras fixas:
- Pasta e todo arquivo dentro dela sempre em **kebab-case** — `component-name/`, `component-name-trigger.tsx`, `context.ts`, `styles.ts`, sem exceção, `.ts` e `.tsx` no mesmo padrão.
- Cada subcomponente em arquivo próprio. Nome do **export** = achatado e PascalCase (`ComponentNameTrigger`); nome do **arquivo** = kebab-case do mesmo nome (`component-name-trigger.tsx`).
- Context, hook e tipos do estado compartilhado sempre em `context.ts` — nunca dentro do arquivo Root.
- `index.ts` reexporta tudo de forma achatada — nunca objeto composto, nunca `Object.assign`.
- Ninguém fora da pasta importa `component-name-trigger.tsx` diretamente. Todo import externo é `from "@/components/component-name"` (o index), nunca `from "@/components/component-name/component-name-trigger"`.
- **Prop pública (que não seja `className`/props nativas de DOM) só existe no Root.** Um filho nunca recebe prop de negócio/config redrilled pelo consumidor — se uma informação precisa chegar num filho, ela vem de `useXContext()`, nunca de uma prop que o consumidor teria que repetir card a card. `className` continua indo em toda parte normalmente (é override de estilo local, não estado compartilhado).

## Como bloquear import direto dos arquivos internos

Isso não é só convenção — precisa ser reforçado por lint, senão alguém importa o arquivo interno sem querer. Adicionar ao `.eslintrc` (ou `eslint.config.js`) uma regra `no-restricted-imports` que só permite importar a pasta do componente pelo index:

```js
// eslint.config.js (trecho)
{
  rules: {
    "no-restricted-imports": [
      "error",
      {
        patterns: [
          {
            group: ["@/components/*/!(index)", "@/components/*/*.tsx"],
            message: "Importe sempre pelo index.ts da pasta do componente, nunca pelo arquivo interno.",
          },
        ],
      },
    ],
  },
}
```

Se o projeto usar barrel exports com `package.json#exports` (monorepo/lib publicada), o mesmo efeito é obtido não expondo os arquivos internos no campo `exports`, só o `index.ts`.

## Tipagem de props (regra fixa, vale pra toda parte, sem exceção)

0. **Toda prop é sempre em inglês** — nome da prop, chave de tipo/interface, literal de union usado como valor de prop. Vale mesmo dentro de uma pasta/rota em português (ver `/pagina`): a pasta pode ser `pedido/$id`, a prop nunca é `pedidoId`, sempre `orderId`. Texto visível (label, título) não é prop de config — esse vai por i18n (`components.json`/`pages.json`), não é onde essa regra se aplica.
1. **Toda parte exporta seu tipo de props.** Nenhum componente fica com a interface só local ao arquivo — sempre `export type { ComponentNameTriggerProps }` (reexportado também no `index.ts`, ver seção acima).
2. **Nome do tipo = nome real do componente + `Props`.** Se o componente exportado é `SelectTrigger`, o tipo é `SelectTriggerProps`. Nunca `Props`, `TriggerProps` genérico ou nomes que não batem 1:1 com o componente.
3. **Estender sempre de `ComponentProps<...>` nativo** como base, em vez de redeclarar props de HTML na mão:
   - Componente do zero, renderizando uma tag HTML: `interface SelectTriggerProps extends ComponentProps<"button"> { asChild?: boolean }`. `ComponentProps<"button">` já inclui `ref` tipado corretamente (React 19) — nunca `ComponentPropsWithoutRef`, que é o tipo do mundo pré-19/`forwardRef`.
   - Componente que envolve uma lib externa (ex: Radix): estender do tipo da própria lib, não da tag HTML — `interface SelectTriggerProps extends ComponentProps<typeof SelectPrimitive.Trigger> {}`. Isso garante que qualquer prop nova que a lib adicionar em uma atualização já chega tipada automaticamente, sem manutenção manual.
4. **Nunca `forwardRef`.** `ref` é recebido como qualquer outra prop, direto na desestruturação da função — sem wrapper, sem segundo argumento.

```tsx
// select-trigger.tsx — do zero
interface SelectTriggerProps extends ComponentProps<"button"> {
  asChild?: boolean;
}
function SelectTrigger({ asChild, ref, ...props }: SelectTriggerProps) {
  /* ... */
}
export type { SelectTriggerProps };

// select-trigger.tsx — envolvendo lib externa (Radix)
interface SelectTriggerProps extends ComponentProps<typeof SelectPrimitive.Trigger> {}
function SelectTrigger({ ...props }: SelectTriggerProps) {
  /* ... */
}
export type { SelectTriggerProps };
```

**`forwardRef` nunca é usado nesta skill.** É um wrapper legado de antes do React 19; hoje `ref` chega como prop normal em qualquer função componente, então usar `forwardRef` é código morto que só adiciona uma camada. Pelo mesmo motivo, `ComponentRef<...>`/`ElementRef<...>` também não são necessários pra tipar ref — o tipo já vem embutido em `ComponentProps<...>`.

## Tipagem sem atalho (regra fixa, sem exceção)

**Nenhum import deprecado.** Antes de usar um tipo/API do React (ou de qualquer lib do projeto), checar se não foi substituído em versão mais recente — o caso mais comum neste projeto é `forwardRef`/`ComponentRef`/`ElementRef`, todos legado de antes do React 19: `ref` é tipado direto via `ComponentProps<...>` (ver exemplo na seção "Tipagem de props"), sem nenhum desses três. Se outro import aparecer marcado como deprecated pelo editor/TypeScript, resolver a substituição antes de seguir — nunca manter o import antigo "porque funciona".

**Nenhum cast que mascara erro de tipo.** `as never`, `as any`, `as unknown as X`, ou qualquer cast em cima de um valor cujo tipo genuinamente não bate — não é uma solução, é adiar o erro pra runtime. Se o TypeScript reclama de um tipo:

1. Primeiro, corrigir a origem: tipar o `state`/prop/parâmetro corretamente na declaração (`useState<TipoCerto>(...)`, `isValidElement<TipoCerto>(child)`, generic explícito na função) em vez de deixar inferir `unknown`/`any` e depois forçar por cima.
2. Se o cast é genuinamente necessário (ex: narrowing que o compilador não consegue provar sozinho, integração com lib de tipagem fraca), usar o tipo mais específico possível no cast — nunca `never`/`any`/`unknown` como destino, e nunca cast de dois passos (`as unknown as X`) pra contornar incompatibilidade real.
3. Na dúvida se o cast é aceitável ou está mascarando um bug de tipagem, parar e perguntar ao usuário antes de deixar no código.

Isso vale pra todo arquivo do componente (Root, filhos, `context.ts`, `styles.ts`), sem exceção — nenhum arquivo desta skill sai com diagnóstico de import deprecado ou cast forçado pendente.

## Prop drilling mínimo (regra fixa, vale pra toda parte e pra quem monta a família)

Todo componente recebe **só o mínimo possível de props** — o suficiente pra decidir o que ele não consegue decidir sozinho (ação vinda de fora: callback, `open`/`onOpenChange`, config genuinamente externa). Qualquer coisa que a própria parte consiga obter sozinha (dado de servidor, valor derivado de uma query já em cache) não deve ser calculada por quem monta a árvore e empurrada como prop — ela busca por conta própria.

Antes de adicionar uma prop nova a qualquer parte, perguntar: **essa informação é uma decisão/ação que só quem monta a árvore pode tomar, ou é um dado que a própria parte consegue buscar sozinha?** Callback de clique, estado de aberto/fechado controlado externamente, id vindo da URL — ficam como prop, porque são decisões do consumidor. Endereço selecionado, lista de cotação, texto de um pedido, qualquer coisa que já existe no cache do TanStack Query (ou é derivável dele) — a parte busca sozinha, nunca recebe pronta.

```tsx
// ERRADO — quem monta calcula o endereço selecionado e empurra como prop
function DeliveryPage() {
  const { data: order } = useApiQuery(findOrderByIdQueryOptions(orderId));
  const { data: addresses } = useApiQuery(findAllAddressesQueryOptions);
  const selectedAddress = addresses?.find((item) => item.id === order?.shipping?.addressId);

  return <SelectedAddressCard address={selectedAddress} onChangeAddress={openPicker} />;
}

// CERTO — SelectedAddressCard busca as mesmas queryOptions sozinho (cache hit, zero custo extra)
function DeliveryPage() {
  return <SelectedAddressCard onChangeAddress={openPicker} />;
}

function SelectedAddressCard({ onChangeAddress }: SelectedAddressCardProps) {
  const { id: orderId } = useParams({ from: "/(publicas)/pedido/$id" });
  const { data: order } = useApiQuery(findOrderByIdQueryOptions(orderId));
  const { data: addresses } = useApiQuery(findAllAddressesQueryOptions);
  const address = addresses?.find((item) => item.id === order?.shipping?.addressId);
  // ...
}
```

Isso vale mesmo fora de uma família composta com Context — um componente simples de uma peça só, montado por uma tela (`/pagina`) ou por outra família, segue a mesma regra: se o dado vem (ou pode vir) do TanStack Query, a própria parte chama a `queryOptions`, nunca recebe o resultado já calculado via prop. `className` e callbacks de ação continuam normais — a regra é só sobre dado de servidor/derivado dele.

## Controle de modal (`useDisclosure`): um por modal, nunca um só compartilhado com union de string

Quando uma tela/componente coordena **2+ modais**, cada modal tem sua **própria instância** de `useDisclosure()` (`@/hooks/use-disclosure`) — nunca uma instância só com um `data`/estado tipo `useDisclosure<"picker" | "form">()` comparando qual string está ativa pra decidir qual modal está aberto. Cada modal controla só o próprio estado, sem comparação de string nenhuma.

As props retornadas de cada instância são **desestruturadas e renomeadas** com o nome do método + o nome do modal (`onOpen` → `onOpen<Modal>`, `onClose` → `onClose<Modal>`, `onOpenChange` → `onOpenChange<Modal>`, `open` → `open<Modal>`):

```tsx
// ERRADO — um disclosure só, decide qual modal abrir comparando string
const modal = useDisclosure<"picker" | "form">();
<AddressPickerModal open={modal.open && modal.data === "picker"} onOpenChange={modal.onOpenChange} />
<AddressFormModal open={modal.open && modal.data === "form"} onOpenChange={modal.onOpenChange} />

// CERTO — um disclosure por modal, props renomeadas com o nome do modal
const { onOpen: onOpenPicker, onClose: onClosePicker, onOpenChange: onOpenChangePicker, open: openPicker } =
  useDisclosure();
const { onOpen: onOpenForm, onClose: onCloseForm, onOpenChange: onOpenChangeForm, open: openForm } =
  useDisclosure();

<AddressPickerModal open={openPicker} onOpenChange={onOpenChangePicker} />
<AddressFormModal open={openForm} onOpenChange={onOpenChangeForm} />
```

Quando uma ação precisa transicionar de um modal pro outro (ex: dentro do picker, "criar novo endereço" deve fechar o picker e abrir o form), isso é uma chamada explícita das duas instâncias, nunca uma mudança de `data`: `onClosePicker(); onOpenForm();`. Isso evita comparação de string espalhada pela árvore e deixa cada modal dono só do próprio ciclo aberto/fechado.

## Dado de TanStack Query nunca viaja pelo Context (regra fixa, sem exceção)

Se alguma parte da família busca dado assíncrono via `useApiQuery`/`useQuery`, esse dado (a resposta em si, `isLoading`, `isFetching`, etc.) **nunca** entra no `value` do Context da família — nem em `props` redrilled a partir do Root. O cache do TanStack Query já É o mecanismo de compartilhamento: cada parte que precisa do dado chama a **mesma** `queryOptions` (mesma `queryKey`) diretamente, e o Query Client resolve tudo — sem requisição extra (cache hit), sem stale entre partes, sem Provider carregando estado de servidor.

```tsx
// ERRADO — Root busca e empurra pelo Context; List e Empty ficam dependentes do Provider
function ComponentNameRoot({ children }: ComponentNameRootProps) {
  const query = useApiQuery(someQueryOptions);
  const contextValue = useMemo(() => ({ data: query.data, isLoading: query.isLoading }), [query.data, query.isLoading]);
  return <ComponentNameContext.Provider value={contextValue}>{children}</ComponentNameContext.Provider>;
}

// CERTO — cada parte que precisa do dado chama a mesma queryOptions sozinha
function ComponentNameList() {
  const { data, isLoading } = useApiQuery(someQueryOptions);
  // ...
}
```

O Root usa a query pra derivar o que **ele próprio** precisa (ex: `value`/`onValueChange` de um `RadioGroupRoot` que ele mesmo renderiza) — não pra virar fonte de verdade que os filhos leem via Context. Cada parte volta na mesma `queryOptions` como base sempre que precisar do dado, em vez de receber uma referência já resolvida por fora.

Consequência direta: bastante família nem precisa de Context nenhum — se a única coisa que as partes "compartilhariam" é dado de servidor, e cada uma já pode buscar esse dado sozinha, não sobra motivo pra Context existir. Antes de criar `context.ts`, perguntar: o que sobra pra compartilhar depois que dado de query sai da equação? Se a resposta for "nada", pula o Context.

## Como compartilhar estado entre as partes (ordem de preferência)

**Context é o último recurso, não o padrão automático.** Ele tem um custo real: qualquer mudança no `value` do Provider re-renderiza todo consumidor, mesmo que só precise de um campo específico. Seguir esta ordem:

1. **Composição via `Children` + `cloneElement`** — quando as partes que precisam se comunicar são filhas diretas do Root (não passam por camadas intermediárias). O Root injeta as props direto nos filhos, sem Provider, sem hook, sem re-render de árvore de contexto. Este é o padrão preferencial pra maioria dos casos (Tabs simples, Accordion de item único, Radio Group).
2. **Estado local + callback nas props** — quando só duas partes precisam se falar (ex: Trigger e Content) e o Root pode simplesmente passar `onOpenChange`/`open` como props pros filhos que renderiza diretamente, sem precisar que netos arbitrariamente aninhados acessem o estado.
3. **Context** — só quando (1) e (2) não são viáveis tecnicamente: partes que podem estar em qualquer nível de aninhamento dentro do Root (ex: `AccordionItem` dentro de `AccordionItem` dentro de wrappers do usuário), muitos consumidores desacoplados, ou **quando o usuário pedir Context explicitamente**. Nesses casos, seguir o template de `context.ts` abaixo.

### Template de composição com `cloneElement` (preferencial)

```tsx
// component-name-root.tsx
import { useState, useMemo, Children, isValidElement, cloneElement, type ComponentProps } from "react";
import { Slot } from "@radix-ui/react-slot";

interface ComponentNameChildProps {
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
}

interface ComponentNameRootProps extends ComponentProps<"div"> {
  asChild?: boolean;
}

function ComponentNameRoot({ asChild, children, ref, ...props }: ComponentNameRootProps) {
  const [open, setOpen] = useState(false);

  const childrenWithProps = useMemo(
    () =>
      Children.map(children, (child) => {
        if (!isValidElement<ComponentNameChildProps>(child)) return child;
        return cloneElement(child, { open, onOpenChange: setOpen });
      }),
    [children, open]
  );

  const Comp = asChild ? Slot : "div";

  return (
    <Comp ref={ref} {...props}>
      {childrenWithProps}
    </Comp>
  );
}
ComponentNameRoot.displayName = "ComponentNameRoot";

export { ComponentNameRoot };
export type { ComponentNameRootProps };
```

`isValidElement<ComponentNameChildProps>(child)` tipa o `child` corretamente pro `cloneElement` aceitar as props novas sem cast — nunca usar `as Partial<unknown>`/`as never`/`as any` pra forçar o compilador a aceitar; se o tipo não fecha sem cast, o modelo dos filhos precisa de ajuste (ver seção "Tipagem sem atalho" mais abaixo), não um cast por cima.

Usar esse caminho sempre que possível. Só subir pro template de Context (próxima seção) quando a estrutura genuinamente exigir.

## `context.ts` (só quando Context for justificado — ver seção acima)

```tsx
import { createContext, useContext } from "react";

interface ComponentNameState {
  open: boolean;
}

interface ComponentNameContextValue {
  state: ComponentNameState;
  onChange: (next: ComponentNameState) => void;
}

const ComponentNameContext = createContext<ComponentNameContextValue | null>(null);

function useComponentNameContext(consumerName: string): ComponentNameContextValue {
  const context = useContext(ComponentNameContext);
  if (!context) {
    throw new Error(`\`${consumerName}\` must be used within \`ComponentNameRoot\``);
  }
  return context;
}

export { ComponentNameContext, useComponentNameContext };
export type { ComponentNameContextValue, ComponentNameState };
```

O contrato do Context (`ComponentNameContextValue`, e qualquer tipo de estado que ele carregue, como `ComponentNameState` acima) é sempre nomeado e completo — nunca um placeholder tipo `unknown`/`any` que empurra a tipagem de volta pro consumidor resolver com cast.

O hook recebe `consumerName` (nome de quem chamou) pra jogar na mensagem de erro — assim o erro aponta exatamente pro subcomponente errado, não uma mensagem genérica.

## Variants e slots (padrão fixo, sempre que a família tem variant própria)

**Variant só é prop pública no Root. Nunca redeclarada como prop nos filhos.** Se o Root aceita `size`/`align`/`variant`, o filho não recebe essa mesma prop de novo — ele lê o resultado já resolvido do Context. Isso é um caso concreto da opção 3 da seção anterior (Context justificado): variant que precisa valer pra mais de um slot é exatamente "muitos consumidores desacoplados", então aqui Context deixa de ser exceção e vira o caminho padrão.

Uma família com variant tem **um único `tv({ slots, variants })`** (do `tailwind-variants`, já usado no projeto em `button.tsx`/`section-heading/root.tsx`) num arquivo `styles.ts` próprio — nunca um `tv()` por arquivo, nunca `twMerge` solto competindo com a variant. O Root resolve a variant uma vez, guarda o objeto de slot-functions resultante no Context, e cada filho só chama a própria função de slot.

### `styles.ts`

```tsx
import { type VariantProps, tv } from "tailwind-variants";

const componentNameVariants = tv({
  slots: {
    root: "base classes do Root aqui",
    trigger: "base classes do Trigger aqui",
    content: "base classes do Content aqui",
  },
  variants: {
    size: {
      sm: { root: "...", trigger: "...", content: "..." },
      lg: { root: "...", trigger: "...", content: "..." },
    },
  },
  defaultVariants: {
    size: "sm",
  },
});

type ComponentNameVariantProps = VariantProps<typeof componentNameVariants>;

export { componentNameVariants };
export type { ComponentNameVariantProps };
```

### `context.ts` com slots

```tsx
import { createContext, useContext } from "react";
import { componentNameVariants } from "./styles";

interface ComponentNameContextValue {
  slots: ReturnType<typeof componentNameVariants>;
}

const ComponentNameContext = createContext<ComponentNameContextValue | null>(null);

function useComponentNameContext(consumerName: string): ComponentNameContextValue {
  const context = useContext(ComponentNameContext);
  if (!context) {
    throw new Error(`\`${consumerName}\` must be used within \`ComponentNameRoot\``);
  }
  return context;
}

export { ComponentNameContext, useComponentNameContext };
export type { ComponentNameContextValue };
```

### Root resolve a variant, filho só consome o slot

```tsx
// component-name-root.tsx
function ComponentNameRoot({ className, size, children, ref, ...props }: ComponentNameRootProps) {
  const slots = useMemo(() => componentNameVariants({ size }), [size]);
  const contextValue = useMemo(() => ({ slots }), [slots]);

  return (
    <ComponentNameContext.Provider value={contextValue}>
      <div className={slots.root({ className })} ref={ref} {...props}>
        {children}
      </div>
    </ComponentNameContext.Provider>
  );
}

// component-name-trigger.tsx — não recebe `size`, pega o slot já resolvido do Context
function ComponentNameTrigger({ className, ref, ...props }: ComponentNameTriggerProps) {
  const { slots } = useComponentNameContext("ComponentNameTrigger");
  return <button className={slots.trigger({ className })} ref={ref} {...props} />;
}
```

`className` continua sendo a única coisa que o consumidor passa direto num filho pra ajustar estilo local — a função de slot (`slots.trigger({ className })`) já mescla isso com a base + a variant resolvida, sem precisar de `twMerge` por fora.

## `component-name-root.tsx` (caminho com Context — só quando justificado)

```tsx
import { useState, useCallback, useMemo, type ComponentProps } from "react";
import { Slot } from "@radix-ui/react-slot";
import { ComponentNameContext } from "./context";
import type { ComponentNameContextValue, ComponentNameState } from "./context";

interface ComponentNameRootProps extends ComponentProps<"div"> {
  defaultState?: ComponentNameState;
  asChild?: boolean;
}

function ComponentNameRoot({ asChild, defaultState, children, ref, ...props }: ComponentNameRootProps) {
  const [state, setState] = useState<ComponentNameState>(() => defaultState ?? { open: false });

  const handleChange = useCallback((next: ComponentNameState) => {
    setState(next);
  }, []);

  const contextValue: ComponentNameContextValue = useMemo(
    () => ({
      state,
      onChange: handleChange,
    }),
    [state, handleChange]
  );

  const Comp = asChild ? Slot : "div";

  return (
    <ComponentNameContext.Provider value={contextValue}>
      <Comp ref={ref} {...props}>
        {children}
      </Comp>
    </ComponentNameContext.Provider>
  );
}
ComponentNameRoot.displayName = "ComponentNameRoot";

export { ComponentNameRoot };
export type { ComponentNameRootProps };
```

O tipo do estado (`ComponentNameState` no exemplo) vem tipado desde a declaração — `useState<ComponentNameState>`, `useCallback((next: ComponentNameState) => ...)` — nunca `useState(/* valor sem tipo */)` seguido de um cast pra empurrar o valor pro tipo certo depois.

## `component-name-trigger.tsx` (com `asChild` + `Slot`)

```tsx
import { memo, type ComponentProps } from "react";
import { Slot } from "@radix-ui/react-slot";
import { useComponentNameContext } from "./context";

interface ComponentNameTriggerProps extends ComponentProps<"button"> {
  asChild?: boolean;
}

const ComponentNameTrigger = memo(({ asChild, ref, ...props }: ComponentNameTriggerProps) => {
  const context = useComponentNameContext("ComponentNameTrigger");
  const Comp = asChild ? Slot : "button";

  return <Comp ref={ref} type="button" data-state={context.open ? "open" : "closed"} {...props} />;
});
ComponentNameTrigger.displayName = "ComponentNameTrigger";

export { ComponentNameTrigger };
export type { ComponentNameTriggerProps };
```

`data-state` (não className condicional) é o padrão pra expor estado visual pro CSS.

## `index.ts` (único ponto de entrada, exports achatados)

Sem comentário nenhum aqui também (ver seção "Comentários" — regra sem exceção). O nome descritivo da pasta/componente já diz o que a família faz.

```tsx
export { ComponentNameRoot } from "./component-name-root";
export { ComponentNameTrigger } from "./component-name-trigger";
export { ComponentNameContent } from "./component-name-content";

export type { ComponentNameRootProps } from "./component-name-root";
export type { ComponentNameTriggerProps } from "./component-name-trigger";
export type { ComponentNameContentProps } from "./component-name-content";
```

Não reexportar `context.ts` — Context e hook são implementação interna, ninguém fora da pasta deve tocar neles.

## Uso no consumo

```tsx
import {
  ComponentNameRoot,
  ComponentNameTrigger,
  ComponentNameContent,
} from "@/components/component-name";

<ComponentNameRoot>
  <ComponentNameTrigger>Abrir</ComponentNameTrigger>
  <ComponentNameContent>...</ComponentNameContent>
</ComponentNameRoot>;
```

## Convenções de nomenclatura (fixas)

- **Nome bem descritivo, sempre** — tanto o nome da pasta/arquivo quanto o nome de cada parte composta. `ComponentName`/`Select` no resto deste documento é placeholder genérico de exemplo, não modelo de nome real: o nome de verdade tem que dizer o que o componente É, não uma categoria vaga. `Modal` é vago; `ConfirmDeleteAccountModal` é descritivo. `Card` é vago; `ProductReviewCard` é descritivo. Isso vale igual pra cada parte: não é só o nome da família que precisa ser claro, `<Nome><Parte>` inteiro tem que continuar legível e específico (`ProductReviewCardTrigger`, não `PRCardTrigger` nem abreviação).
- **Sempre em inglês, sem exceção** — nome da pasta, nome de cada arquivo e nome de cada export ficam em inglês, mesmo quando o componente vive dentro de (ou serve) uma tela cuja rota é em português (ver `/pagina`: rota/URL fica em português pro usuário final navegar, mas componente/helper/schema é vocabulário de código, sempre inglês). Ex: um componente de formulário de login usado na rota `/entrar` chama `sign-in-form/` (export `SignInForm`), nunca `entrar-form/`/`FormularioEntrar`. Nunca misturar os dois idiomas dentro do mesmo nome (`ProductCardCabecalho` não existe — é `ProductCardHeader`).
- **Pasta e arquivo: sempre `kebab-case`**, descritivo (`product-review-card/`, `confirm-delete-account-modal/`, `checkout-stepper/`). Nunca PascalCase, nunca camelCase no nome do arquivo.
- **Export: sempre `PascalCase` achatado** — `<ComponentName><Parte>` (`SelectRoot`, `SelectTrigger`, `SelectContent`) — nunca dot notation, nunca abreviações. É a única coisa que fica PascalCase, porque JS exige identificador válido e React exige inicial maiúscula pra reconhecer como componente em JSX.
- **Arquivo = kebab-case do nome do export**: `SelectTrigger` exportado vive em `select-trigger.tsx`. Vale igual pra `.ts` (`context.ts`, `styles.ts`) e `.tsx` — mesmo padrão, sem prefixo especial pra nenhum dos dois.
- **Arquivo de hook é sempre `.tsx`, nunca `.ts`** — vale pra hook global (`src/hooks/use-page-title.tsx`) e pra hook escopado, mesmo quando ele não tem nenhum JSX hoje. Hook é ponto de extensão natural pra passar a retornar JSX depois, e trocar a extensão no meio do caminho quebra todo import que já apontava pro arquivo. Exceção única: `context.ts` do componente composto segue `.ts`, porque é Context + tipos, não um hook de uso geral. Helper puro, schema e constante continuam `.ts`.
- Hook de contexto: `use<ComponentName>Context`, privado — nunca exportado no `index.ts`.
- Tipos: `<ComponentName>ContextValue` pro contrato do Context, `<ComponentName><Parte>Props` pras props de cada parte.
- **Nunca importar o namespace inteiro (`import * as React from "react"`) e usar `React.useState`, `React.useMemo`, etc.** Sempre importar cada símbolo direto do módulo: `import { useState, useCallback, useMemo, type ComponentProps } from "react"` e usar `useState`, `useMemo` etc. sem prefixo. Vale pra qualquer arquivo do componente, sem exceção.

## Performance e escalabilidade (regra fixa, aplicar sempre)

Todo componente composto deve ser escrito assumindo que vai rodar em listas grandes, re-renderizar com frequência, ou compor árvores profundas. Práticas obrigatórias:

1. **Value do Context sempre memoizado com `useMemo`**, e handlers dentro dele sempre memoizados com `useCallback` — um objeto novo a cada render do Provider derruba a otimização de todo consumidor, Context ou não.
2. **Separar Context de estado que muda pouco do que muda muito**, quando o componente for grande o suficiente pra justificar (ex: Context de configuração estática separado do Context de estado de interação) — evita que uma mudança de UI re-renderize consumidores que só leem config.
3. **`memo` nas partes "folha"** (Trigger, Item, Content) que não têm motivo pra re-renderizar quando o pai re-renderiza por outro motivo. Não memoizar às cegas — só quando a parte é usada em quantidade (listas, itens repetidos) ou o pai re-renderiza com frequência.
4. **Nunca criar objetos, arrays ou funções inline dentro do JSX** de props que vão pra componentes memoizados — isso quebra a comparação de igualdade do `memo` e anula a otimização. Sempre `useCallback`/`useMemo` antes.
5. **Inicialização de estado sempre lazy quando o valor inicial é caro de calcular**: `useState(() => computeInitial())`, não `useState(computeInitial())` (essa segunda forma roda a cada render).
6. **Evitar `useEffect` para sincronizar estado derivado** — se um valor pode ser calculado a partir de outro estado/props durante o render, calcular direto (ou com `useMemo` se for caro), nunca com `useEffect` + `useState` extra.
7. **Composição via `cloneElement`/`children` sempre que possível** (ver seção acima) — é estruturalmente mais leve que Context porque não recria um Provider/consumer tree.
8. Se a parte "Content"/"Item" puder gerar listas longas (ex: `SelectContent` com centenas de opções), considerar virtualização (ex: `@tanstack/react-virtual`) em vez de renderizar tudo de uma vez — mencionar isso ao usuário como opção quando o caso de uso sugerir volume grande, em vez de assumir por padrão.

## Busca/envio de dado e helpers (regra fixa)

**Fetch, mutação, ou qualquer chamada à API disparada pelo componente sempre passa por TanStack Query** (`useQuery`/`useMutation`) quando a lib estiver disponível no projeto — nunca `useState` + `fetch`/chamada direta ao service + `try/catch` na mão. TanStack Query já resolve loading/error/retry/cache; reimplementar isso com `useState` é regra que a skill não aceita, mesmo parecendo mais simples pra um caso pontual. Erro já cai no tratamento global (`mutationCache`/`queryCache` do `QueryClient`, ver `src/shared/query-client.ts`) — só usa `meta: { ignoreError: true }` na mutation quando o componente já mostra o próprio erro inline (evita toast duplicado).

**Nenhuma função helper (pura, sem JSX) vive dentro do arquivo do componente**, salvo caso muito pontual e genuinamente specific daquele componente (ex: um formatter de 1 linha usado só ali, e ainda assim avaliar se não vale extrair). A regra: se a função não depende de `props`/estado do componente e só transforma um valor, ela não é "parte" do componente — é helper, e helper segue a mesma classificação Global vs Escopado do resto do projeto: se o componente é global (`src/components/`), o helper vai pra `src/utils/`; se o componente é escopado a uma tela (`_components/` dentro de `src/pages/<rota>/`), o helper vai pra `_utils/` ao lado do `index.tsx` da rota. Nunca dentro do arquivo do componente "porque é rapidinho".

## Lint, build e teste (regra fixa)

Nunca rodar lint, build ou o comando de teste automaticamente depois de escrever/editar o componente. Isso é decisão do dev — ele roda antes do commit, no momento que quiser. Só rodar teste se o dev pedir explicitamente pra testar. Escrever código correto de olho no padrão desta skill já resolve a maior parte do que lint/build pegariam; se sobrar algo, o dev pega no próprio fluxo dele.

## Checklist antes de finalizar um componente composto

1. Cada parte está em arquivo próprio, nomeado igual ao export (em kebab-case)?
1a. Toda parte que está na pasta desta família realmente pertence a ela (depende do Context/Root, não funciona sozinha)? Nenhuma peça genérica foi enterrada aqui em vez de reaproveitada de outro lugar do projeto ou extraída pra pasta própria?
2. O nome da pasta e o nome de cada parte são descritivos de verdade (dizem o que o componente É, não uma categoria genérica tipo `Modal`/`Card` solto)?
2a. Pasta e arquivos em kebab-case? Arquivo `.ts` (não `.tsx`) começando com `_`, exceto `index.ts`?
3. Nenhum arquivo tem comentário nenhum — nem de decisão de padrão, nem de regra de negócio, nem de propósito?
4. Toda parte que renderiza texto/botão/avatar/etc. usa o primitivo correspondente de `src/components/ui` em vez de HTML cru — e, se algum primitivo necessário não existia lá, o usuário foi consultado antes de decidir o caminho?
5. Nenhuma parte sobrescreve por fora o estilo que o primitivo já define pelas props (sem `className` conflitante, `!important`, cor literal por cima de `color`/`variant`) — e, se faltava uma variante, o usuário foi consultado antes de forçar algo?
6. Se este componente usa Context: isso foi realmente necessário (partes não são filhas diretas, ou muitos consumidores desacoplados) ou foi pedido explicitamente pelo usuário? Se não, foi tentada composição via `cloneElement`/`children` antes?
6b. Nenhum dado de `useApiQuery`/`useQuery` (resposta, `isLoading`, `isFetching`, etc.) entra no `value` do Context nem é redrilled via props a partir do Root? Toda parte que precisa desse dado chama a mesma `queryOptions` sozinha?
6c. Cada prop que a parte recebe é genuinamente uma decisão/ação externa (callback, `open`, id de URL) e não um dado que a própria parte já conseguiria buscar sozinha do TanStack Query? Nenhuma prop existe só porque "era mais fácil calcular uma vez lá em cima"?
6d. Se este componente coordena 2+ modais: cada um tem sua própria instância de `useDisclosure()`, com as props desestruturadas e renomeadas com o nome do modal (`onOpenPicker`, `openForm`, etc.), sem nenhuma comparação de string tipo `data === "picker"` decidindo qual modal está aberto?
6a. Se a família tem variant própria (`size`/`align`/`variant`/etc.): a variant só é prop no Root? Nenhum filho redeclara a mesma prop? Existe um único `tv({ slots, variants })` em `styles.ts`, e cada filho lê sua função de slot via `useXContext()` em vez de receber a variant redrilled?
7. Todos os nomes exportados são achatados (`ComponentNameTrigger`), nunca dot notation ou objeto composto?
8. O `index.ts` reexporta tudo e é o único arquivo importável de fora da pasta — `context.ts` (se existir) e os arquivos internos NÃO são reexportados nem importados diretamente em nenhum lugar do projeto?
9. Existe uma regra de lint (`no-restricted-imports` ou equivalente) impedindo import direto dos arquivos internos?
10. Toda parte que renderiza DOM define `displayName`, e nenhuma usa `forwardRef` (ref é recebido como prop normal, React 19)?
11. Pra cada parte que renderiza DOM, foi avaliado (não assumido automaticamente) se `asChild` via `Slot` faz sentido pra evitar wrapper extra no DOM?
12. Estado visual é exposto via `data-state`/`data-disabled`, não className condicional?
13. Todas as props e o contrato do Context (se existir) estão tipados (sem `any`)?
14. Toda parte exporta seu próprio tipo de props, nomeado exatamente `<NomeRealDoComponente>Props`?
15. Cada tipo de props estende `ComponentProps<...>` da tag HTML nativa (nunca `ComponentPropsWithoutRef`, que é só pro mundo `forwardRef`) — ou, se o componente envolve uma lib externa, estende do tipo dessa lib em vez da tag HTML?
16. Se há Context, o `value` do Provider está memoizado com `useMemo` e os handlers com `useCallback`?
17. Partes "folha" usadas em quantidade (itens de lista, etc.) estão com `memo` quando faz sentido?
18. Nenhum objeto/array/função é criado inline dentro do JSX em props passadas pra componentes memoizados?
19. Nenhum arquivo usa `import * as React from "react"` com `React.algumaCoisa` — todos os símbolos (`useState`, `useMemo`, `ComponentProps`, etc.) são importados nomeados direto de `"react"`?
20. Nenhum arquivo usa `forwardRef`, `ComponentRef` ou `ElementRef` — ref é prop normal tipada via `ComponentProps<...>` (React 19)?
21. Nenhum cast (`as never`/`as any`/`as unknown`/cast de dois passos) mascarando um erro de tipo real — todo tipo que não fechava foi corrigido na origem (declaração tipada, generic explícito), não empurrado com cast?
22. Se a família tem lista carregada assincronamente (`ForEach` com `isLoading`/`fallBack`): o skeleton está em `component-name-fallback.tsx` próprio (export `ComponentNameFallback`), não uma função solta dentro da parte que o usa? Só está no `index.ts` se algum consumidor de fora genuinamente precisa dele isolado?

Se qualquer resposta for não (ou "não, mas deveria"), corrija antes de considerar o componente pronto.

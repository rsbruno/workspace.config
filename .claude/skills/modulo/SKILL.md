---
name: modulo
description: Cria um novo módulo NestJS neste projeto (<repo-api>) seguindo exatamente o padrão DDD/Clean Architecture já estabelecido — CQRS, camadas domain/infrastructure/presentation isoladas, DTOs separados de raw external shapes, infra agrupada por provider. NÃO é auto-invocável — só usar quando o usuário mencionar explicitamente esta skill/o comando `/modulo`, nunca por inferência de "cria um módulo"/"nova feature" sozinho.
---

# modulo

Gera um módulo novo em `src/modules/v1/<dominio>/<modulo>/` replicando **exatamente** a estrutura de um módulo de leitura (query) já existente no projeto e, quando houver escrita, de um módulo de escrita (command) já existente. Antes de escrever qualquer arquivo, releia esses diretórios reais no projeto para confirmar que o padrão não mudou — esta skill descreve o padrão, os arquivos-fonte são a verdade.

**Prioridade: agilidade.** Sem validação, sem rodar nada, sem passo extra. Reúna a informação mínima, escreva os arquivos, registre no `app.module.ts`, pare. O usuário confere/roda quando quiser.

## 1. Reúna a informação (pergunte o que faltar, não assuma)

- **Domínio**: pasta pai em `src/modules/v1/` (ex: `catalog`, `identity`). Se o domínio não existir, será criado.
- **Nome do módulo**: plural, kebab-case (ex: `categories`, `orders`). Vira o nome da pasta, do `*.module.ts`, do `*.controller.ts`.
- **Entidade**: nome singular em PascalCase (ex: `Category`) — usado no DTO de domínio e nos nomes de classe.
- **Operações**: precisa de queries (leitura), commands (escrita), ou ambos?
- **Fonte de dado**: integra um provider externo (ex: um novo SaaS de terceiro) ou é backed por banco (Drizzle, via repository)? Isso define o conteúdo de `infrastructure/`.
- **Rota pública ou autenticada**: por padrão as rotas exigem JWT (guard global). Só use `@Public()` se o usuário disser explicitamente que a rota é pública.

Nunca invente nome de provider, campo, ou endpoint — pergunte se não estiver claro.

## 2. Estrutura de pastas (sempre)

```
src/modules/v1/<dominio>/<modulo>/
├── <modulo>.controller.ts
├── <modulo>.module.ts
├── dtos/
│   └── <entidade>.dto.ts                 # DTO de domínio/resposta -- NUNCA fica dentro de infrastructure/
├── domain/                               # só se o módulo tiver enum de entidade e/ou Port -- ver seção "domain/" abaixo
│   ├── enums/
│   │   └── <entidade>-status.enum.ts     # (ou outro enum de estado do negócio -- ver 2.1)
│   └── gateways/
│       └── <algo>-gateway.interface.ts   # Port: contrato que um adapter de infrastructure/ implementa
├── infrastructure/
│   └── <provider>/                       # uma pasta por provider/fonte externa -- nunca "services/" ou "helpers/" soltos direto em infrastructure/
│       ├── dtos/<provider>-<entidade>.dto.ts     # shape cru que o provider devolve
│       └── services/                              # um arquivo por caso de uso, nunca um service com vários métodos
│           ├── find-all-<entidades>.service.ts
│           └── find-<entidade>-by-<prop>.service.ts
# SEM pasta helpers/ dentro do módulo -- ver "Mapeamento raw → domínio" abaixo
├── queries/                              # só se houver leitura
│   └── find-all-<entidades>/             # ou find-<entidade>-by-<prop>/ pra lookup específico
│       ├── find-all-<entidades>.query.ts
│       ├── find-all-<entidades>.handler.ts
│       └── find-all-<entidades>.dto.ts   # só se a query tiver query params (ex: filtro)
├── commands/                             # só se houver escrita
│   └── <verbo>-<entidade>/
│       ├── <verbo>-<entidade>.command.ts
│       ├── <verbo>-<entidade>.dto.ts      # Payload + Result DTOs no mesmo arquivo
│       └── <verbo>-<entidade>.handler.ts
└── webhooks/                             # só se o módulo receber eventos de provider externo
    └── commands/                         # webhooks sempre disparam commands (POST recebido)
        └── handle-<provider>-webhook/
            ├── handle-<provider>-webhook.command.ts
            └── handle-<provider>-webhook.handler.ts
```

### Responsabilidade de cada pasta (Clean Arch / DDD) — não misture o conteúdo entre elas

| Pasta | Responsabilidade | Nunca contém |
|---|---|---|
| `<modulo>.controller.ts` | Camada de apresentação (HTTP). Recebe request, valida via DTO, delega pro `QueryBus`/`CommandBus`, devolve resposta. Zero regra de negócio, zero chamada direta a service/provider. | lógica de mapeamento, chamada a `infrastructure/` direto |
| `<modulo>.module.ts` | Composition root do módulo: declara `providers`, `controllers`, `imports`, `exports`. Fiação, nada de lógica. | lógica de negócio, imports de outro módulo além do que ele expõe |
| `dtos/` (raiz do módulo) | Contrato de **domínio** do módulo — o formato de dado que ele expõe/entende, independente de onde o dado veio. É o que o `controller` devolve. Também é onde mora o mapeamento raw→domínio, via `@Transform` (ver seção "Mapeamento raw → domínio" abaixo). | shape cru de provider externo puro sem decorator |
| `infrastructure/<provider>/` | Tudo que é **detalhe técnico de UM provider/fonte externa específica**, isolado do resto do módulo. Se trocar o provider amanhã, só essa pasta muda — nada fora dela deveria saber que aquele provider existe. Uma pasta por provider (`infrastructure/{provider}/`, `infrastructure/database/`), nunca misturados. | qualquer coisa que o `controller` ou outro módulo importe diretamente |
| `infrastructure/<provider>/dtos/` | Shape **cru**, exatamente como o provider devolve (campo `snake_case`, sem decorator nenhum). Não é contrato do módulo, é só tipagem de resposta externa. | `@ApiProperty`, `@Expose`, qualquer decorator |
| `infrastructure/<provider>/services/` | Faz a chamada real (HTTP/SDK/query), aplica cache/log/try-catch, converte o resultado cru pro dto de domínio via `plainToInstance` (ver seção "Mapeamento raw → domínio"), e retorna já no formato de `dtos/`. É o único lugar que conhece o client/token de injeção do provider. **Um service = um caso de uso = um arquivo.** `findAll` e `findBySlug` nunca vivem na mesma classe, mesmo que pareçam simples — sempre `{Provider}FindAll{Entidades}Service` e `{Provider}Find{Entidade}By{Prop}Service` separados, cada um com seu próprio `@Injectable()`. Vale pra qualquer service criado nessa skill, não só integração com provider externo. | função de mapeamento manual, regra de apresentação, mais de um método público/caso de uso na mesma classe |
| `queries/<nome>/` | Um **use case por trás de um `@Get`** (CQRS): `.query.ts` (dados de entrada), `.handler.ts` (orquestra — chama o service e retorna), `.dto.ts` (opcional, query params validados). Um use case = uma pasta. Classificação é pelo verbo HTTP, não por "será que muda estado" — ver seção 3.2. | lógica de mapeamento raw→domínio, chamada direta ao client externo |
| `commands/<nome>/` | Um **use case por trás de `@Post`/`@Put`/`@Patch`/`@Delete`** (CQRS), mesmo quando não persiste nada (ex: calculadora que só lê e devolve um número, mas recebe body). `.dto.ts` aqui carrega Payload (validação de entrada) + Result (shape de saída) no mesmo arquivo. | leitura por `@Get` (isso é query, ver seção 3.2) |
| `webhooks/commands/<nome>/` | Handler de evento recebido de **provider externo** via HTTP POST (ex: MP, Stripe). Sempre é um Command (POST recebido). O controller delega ao `CommandBus`; o handler valida a assinatura (HMAC), re-confirma o estado com o provider antes de qualquer write, e atualiza o DB. `.command.ts` carrega o payload cru do provider (headers + body). Sem `.dto.ts` de validação de entrada via `class-validator` — a verificação é feita manualmente no handler (HMAC). | lógica de negócio fora do handler, chamada direta a repositórios de outros módulos |

## Mapeamento raw → domínio: `plainToInstance` + `@Transform`, **não** helper de módulo

**Evite helper ao máximo.** O módulo **não tem** `infrastructure/<provider>/helpers/`. O mapeamento raw→domínio vive como `@Transform` direto nos campos do dto de `dtos/{entidade}.dto.ts` (ver template 4.1), e o service chama `plainToInstance({Entidade}Dto, raw, { excludeExtraneousValues: true })` em vez de uma função `map...` escrita à mão (ver template 4.4). Procure um dto já existente no projeto com `@Transform` pra usar de referência.

Regras de reuso, sem exceção:

- **Nunca recrie lógica de transformação que já existe em algum lugar global.** Antes de escrever qualquer `@Transform` novo, procure em `src/infrastructure/helpers/` (genérico, qualquer módulo — ex: `parsePriceToCents`) e em `src/infrastructure/services/<provider>/helpers/` (específico do provider, qualquer módulo desse provider — ex: `pickLocalizedText`, `mapProviderIdName`) e reaproveite se existir.
- **Helper só existe em nível de infraestrutura global**, nunca dentro de um módulo (`src/modules/...`). Se a transformação for específica de UM campo de UMA entidade e não repete em lugar nenhum, ela fica inline no `@Transform` mesmo, sem virar arquivo. Só vira helper global quando **mais de um lugar** (módulos diferentes, ou mais de um campo do mesmo módulo) precisa da mesma lógica — nesse caso sobe pra `src/infrastructure/helpers/` (se for genérico) ou `src/infrastructure/services/<provider>/helpers/` (se for específico do provider), nunca fica local ao módulo.
- **Nunca importe algo de dentro de outro módulo** (ex: `categories/infrastructure/...` importado direto por `orders/`), **e nunca injete `Repository`/`Service` de outro módulo direto, mesmo que ele esteja no `exports`**. Cross-module é sempre via `QueryBus`/`CommandBus` — ver seção 2.5.
- Se for **backed por banco** em vez de provider externo, `infrastructure/database/` segue o padrão de um repository já existente no projeto (`*-query.repository.ts`) — repository no lugar de service, mesma responsabilidade de isolar o acesso a dado concreto, nome diferente porque a origem é banco, não API.

**Tipos de payload no command repository derivam do schema Drizzle — nunca interfaces manuais (regra fixa):**

```ts
// command.repository.ts
export type AddressEntity = typeof addressesTable.$inferSelect;
export type CreateAddressPayload = Omit<typeof addressesTable.$inferInsert, 'id' | 'createdAt'>;
export type UpdateAddressPayload = Partial<Omit<typeof addressesTable.$inferInsert, 'id' | 'userId' | 'isDefault' | 'createdAt'>>;
```

- `$inferSelect` → tipo de entidade retornada pelo banco
- `Omit<$inferInsert, ...>` → payload de criação (exclui campos gerados: `id`, `createdAt`)
- `Partial<Omit<$inferInsert, ...>>` → payload de update (exclui também campos imutáveis como `userId`)

Nunca escrever `interface CreateXPayload { campo: string; ... }` manualmente — duplica o schema e desincroniza quando colunas mudam. Ajuste os campos excluídos no `Omit` conforme o que cada entidade gera internamente (`id` sempre; `createdAt`/`updatedAt` se tiver; campos de domínio imutáveis como `userId`, `slug`, `status` no update).

## 2.1 Soft delete obrigatório — nunca DELETE físico (regra fixa do projeto)

Todo módulo que expõe um endpoint de exclusão (`@Delete`) usa **soft delete via coluna `status`** — nunca `DELETE FROM` no banco. O dado "excluído" permanece na tabela, invisível para qualquer query subsequente.

Vale também pra **tabela de pivot/referência** (N:N) — desanexar/desassociar (ex: tirar uma role de uma policy, tirar um membro de uma policy) é uma exclusão como qualquer outra. Toda tabela de pivot leva `status`+`updatedAt` igual a uma tabela "normal", nunca fica de fora dessa regra só por ser uma tabela de junção.

### Schema

Toda tabela que suporta exclusão deve ter as colunas:

```ts
status: integer('status').notNull().default(1),
updatedAt: timestamp('updated_at').notNull().defaultNow(),
```

### Enum

Criar `<modulo>-status.enum.ts` dentro de `domain/enums/` (ver seção "domain/" abaixo) — nunca solto na raiz do módulo, mesmo que seja o único arquivo de `domain/` que o módulo tenha. Procure um enum de status já existente em `domain/enums/` de outro módulo pra usar de referência.

```ts
export enum <Entidade>Status {
  ACTIVE = 1,
  INACTIVE = 0,
}
```

### Command repository

- **`create`**: inserir com `status: <Entidade>Status.ACTIVE` (explícito, não depende do default do banco)
- **`delete`**: UPDATE SET `status = INACTIVE, updatedAt = new Date()` WHERE `id = ? AND status = ACTIVE` — nunca `db.delete()`
- **`update`**: SET incluir `updatedAt: new Date()`, WHERE incluir `AND status = ACTIVE`
- Qualquer operação que muda estado (ex: `setDefault`) deve incluir `updatedAt: new Date()` e filtrar `AND status = ACTIVE`

```ts
// delete — NUNCA db.delete()
async delete(id: string, userId: string): Promise<EntityType | null> {
  const [row] = await this.db
    .update(table)
    .set({ status: EntityStatus.INACTIVE, updatedAt: new Date() })
    .where(and(eq(table.id, id), eq(table.userId, userId), eq(table.status, EntityStatus.ACTIVE)))
    .returning();
  return row ?? null;
}
```

### Query repository

Todo `SELECT` filtra `WHERE status = ACTIVE` — nunca retornar registros inativos:

```ts
.where(and(eq(table.userId, userId), eq(table.status, <Entidade>Status.ACTIVE)))
```

### Tipos inferidos

Excluir `status` e `updatedAt` dos payloads expostos ao handler — são campos gerenciados internamente:

```ts
export type Create<Entidade>Payload = Omit<typeof table.$inferInsert, 'id' | 'status' | 'createdAt' | 'updatedAt'>;
export type Update<Entidade>Payload = Partial<Omit<typeof table.$inferInsert, 'id' | 'userId' | 'isDefault' | 'status' | 'createdAt' | 'updatedAt'>>;
```

### DTO de resposta

`status` **nunca** aparece no DTO de domínio — é detalhe interno. Sem `@Expose()` no campo `status`, sem `@ApiProperty` para ele.

### Toda query que atravessa relação (join/FK) valida `status = ACTIVE` em CADA tabela da cadeia, não só na tabela final

Bug real já cometido nesse projeto: uma query que resolvia permissões de membro (`organization_members → policy_members → policies → policy_roles → roles`) filtrava `status = ACTIVE` em quase toda tabela, mas esqueceu a própria `organizations` — resultado: uma organização soft-deletada continuava liberando acesso pros seus ex-membros, porque nada na query dependia do status dela.

Regra: ao escrever um `SELECT`/`join` que passa por mais de uma tabela com soft delete, **cada tabela da cadeia precisa do seu próprio filtro `status = ACTIVE`** (ou `innerJoin` com essa condição embutida) — nunca assume que filtrar a ponta final (ou só a tabela de onde a query "começa") garante que todo o caminho está ativo. Antes de considerar uma query de leitura pronta, liste mentalmente todas as tabelas com soft delete que ela atravessa e confirma que cada uma tem seu `eq(table.status, EntityStatus.ACTIVE)` — se faltar uma, é dado "fantasma" (logicamente excluído) vazando pro resultado.

## 2.1.1 `domain/` — quando o módulo tem enum de entidade e/ou Port (regra fixa do projeto)

**Cria `domain/` sempre que o módulo tiver pelo menos um dos dois**: um enum de estado do negócio (ex: `<entidade>-status.enum.ts` do soft delete, ver 2.1 — o que cobre praticamente todo módulo com exclusão) e/ou um Port, quando o módulo precisa trocar de provider/implementação sem o resto do código saber (ex: um módulo de pagamento que hoje usa Mercado Pago mas pode trocar de gateway amanhã; um módulo de notificação que hoje manda email mas pode trocar de provedor de e-mail). Cada tipo vai na sua subpasta (`domain/enums/`, `domain/gateways/`) — o módulo pode ter só uma das duas, ou as duas.

**O que entra em `domain/`** — só os dois tipos de arquivo abaixo, cada um na sua subpasta, nada solto direto em `domain/`:

1. **`domain/enums/`** — enums de entidade (`<entidade>-status.enum.ts`, `<entidade>-origin.enum.ts`, etc), estado do negócio, zero dependência de framework/banco/provider. Procure um enum de status já existente em `domain/enums/` de outro módulo pra usar de referência.
2. **`domain/gateways/`** — Ports (`<algo>-gateway.interface.ts`, `<algo>-provider.interface.ts`), a interface que define o que o módulo *precisa* de uma dependência externa, junto com o token de injeção (`Symbol`) na mesma linha de export. Procure um gateway já existente em `domain/gateways/` de outro módulo pra usar de referência.

Um enum entra em `domain/enums/`, um Port entra em `domain/gateways/` — nunca solto direto em `domain/`, mesmo quando o módulo só tem um arquivo de cada tipo.

**Por que fica em `domain/`, não em `infrastructure/`**: Dependency Inversion — o Port é definido por quem *usa* (o caso de uso, em `commands/`/`queries/`), não por quem *implementa* (o adapter, em `infrastructure/<provider>/`). A seta de dependência aponta pra dentro: o adapter depende do Port, nunca o contrário. Se a interface morasse dentro de `infrastructure/<provider>/`, a leitura ficaria invertida — pareceria que o provider é dono do contrato.

```ts
// domain/gateways/<algo>-gateway.interface.ts
export const <ALGO>_GATEWAY = Symbol('<ALGO>_GATEWAY');

export interface <Algo>GatewayResult {
  // shape já normalizado, no vocabulário do domínio -- nunca campo/valor cru do provider aqui
}

export interface <Algo>Gateway {
  algumaOperacao(input: AlgumInput): Promise<<Algo>GatewayResult>;
}
```

```ts
// infrastructure/<provider>/services/<provider>-<algo>-gateway.service.ts
@Injectable()
export class <Provider><Algo>GatewayService implements <Algo>Gateway {
  // aqui, e só aqui, vive o vocabulário cru do provider (status strings, nomes de campo do payload) --
  // esse service traduz pra PaymentStatus/shape do domain/ antes de devolver
}
```

```ts
// {modulo}.module.ts
providers: [
  // ...
  { provide: <ALGO>_GATEWAY, useClass: <Provider><Algo>GatewayService },
],
```

Trocar de provider depois = escrever um novo adapter implementando o mesmo Port + trocar o `useClass` dessa linha. Nada em `commands/`/`queries/` muda.

**Exceção ao "um service = um caso de uso"**: o adapter que implementa um Port pode ter mais de um método público (um por operação do Port) — não é "service genérico com métodos soltos", é a forma exigida pela interface que ele implementa. Métodos internos de baixo nível que o adapter usa por trás (ex: uma chamada HTTP específica) continuam podendo ser services separados de um método só, compostos dentro do adapter.

**Handler/service que usa o Port nunca importa nada de `infrastructure/<provider>/` diretamente** — só o token + a interface de `domain/gateways/`:

```ts
// commands/algum-caso-de-uso/algum-caso-de-uso.handler.ts
constructor(
  @Inject(<ALGO>_GATEWAY)
  private readonly gateway: <Algo>Gateway, // nunca importa <Provider><Algo>GatewayService aqui
) {}
```

## 2.1.2 Tabela de pivot/referência (N:N) — sempre no schema da entidade de maior hierarquia (regra fixa do projeto)

Uma tabela de pivot (ex: `organizations_members`, ligando `organizations` a `users`) **não ganha arquivo `.schema.ts` próprio**. Ela é declarada dentro do mesmo arquivo `{modulo}.schema.ts` da entidade de **maior hierarquia** das duas pontas da relação — a entidade "dona"/container, não a entidade "membro". `organizations` é a entidade de maior hierarquia em relação a `users` numa membership (a organização é o container, o usuário é o elemento), então `organizationMembersTable` fica dentro de `organizations.schema.ts`, nunca num `organizations-members.schema.ts` separado.

Como decidir qual lado é "maior hierarquia": qual entidade **contém/agrupa** a outra na regra de negócio (não o tamanho do módulo nem ordem alfabética). Se a relação é entre duas entidades do mesmo módulo (ex: `orders` e `order_items`), a tabela de pivot/filha fica no schema do módulo — comportamento já natural, essa regra importa quando a pivot cruza dois módulos diferentes (ex: `tenancy/organizations` + `identity/users`).

### Nome da tabela de pivot: sempre `plural_plural` (regra fixa do projeto)

O nome da tabela em si (a string passada pra `pgTable(...)`) segue **plural_plural** — as duas entidades relacionadas, cada uma no plural, nessa ordem: `{entidadeMaiorHierarquiaPlural}_{entidadeMenorPlural}`. Nunca `singular_plural` (ex: `organization_members` está errado — o certo é `organizations_members`), mesmo quando a tabela tem colunas extras (`status`, `role`, `signedAt` etc.) e não é um join "puro" — a regra de nomenclatura da tabela não muda por causa disso, só o fato de ela ter `id` próprio (sempre tem, regra 2.1) e não depender de PK composta.

```ts
// ERRADO — singular_plural
export const organizationMembersTable = pgTable('organization_members', { /* ... */ });

// CERTO — plural_plural
export const organizationMembersTable = pgTable('organizations_members', { /* ... */ });
```

O nome da `const`/variável TypeScript (`organizationMembersTable`) continua em camelCase normal, sem relação com essa regra — só a string do nome da tabela no banco é que segue `plural_plural`.

```ts
// {modulo}.schema.ts — schema da entidade de maior hierarquia carrega a tabela de pivot também
import { usersTable } from '@/modules/v1/identity/users/infrastructure/database/drizzle/users.schema';

export const organizationsTable = pgTable('organizations', { /* ... */ });

export const organizationMembersTable = pgTable('organizations_members', {
  organizationId: varchar('organization_id', { length: 128 }).notNull().references(() => organizationsTable.id),
  userId: varchar('user_id', { length: 128 }).notNull().references(() => usersTable.id),
  // ...
});
```

O repository de pivot (`{modulo}-members-command.repository.ts`/`-query.repository.ts`, se houver) continua em arquivo próprio dentro de `infrastructure/database/drizzle/` — só o `.schema.ts` é que se une.

## 2.1.3 Todo enum de negócio é `integer` na tabela, `enum` TypeScript no código (regra fixa do projeto)

Vale pra qualquer enum de domínio, não só o `status` do soft delete (2.1) — tipo de imóvel, tipo de anúncio, categoria fixa, o que for. A coluna no banco é **sempre `integer`**, nunca `varchar` carregando a string do enum. O nome legível só existe em `domain/enums/` (TypeScript), nunca como valor persistido.

```ts
// ERRADO — enum como string na coluna
export enum PropertyListingType {
  SALE = 'sale',
  RENT = 'rent',
}
listingType: varchar('listing_type', { length: 10 }).notNull(),

// CERTO — enum numérico, coluna integer
export enum PropertyListingType {
  SALE = 1,
  RENT = 2,
}
listingType: integer('listing_type').notNull(),
```

Por quê: renomear o valor do enum (`'sale'` → `'for_sale'`) não pode nunca virar uma migration de dado — com `integer`, o código muda e o dado antigo continua válido; com `varchar`, cada rename é migration de UPDATE em massa. `integer` também é mais compacto e mais rápido de indexar/comparar que `varchar`.

Na prática:
- `@IsEnum(PropertyListingType)` no payload dto continua funcionando igual, client manda o número (ou o nome do enum member, mas o valor real trafegado/validado é o numérico).
- DTO de resposta expõe o campo como está (número) — se o front precisar do label legível, isso é resolvido no front a partir do enum compartilhado/gerado via Orval, não formatado no back.
- Primeiro valor de um enum de negócio novo começa em `1`, nunca `0` — `0` fica reservado como "não setado/desconhecido" quando fizer sentido, evita ambiguidade com o `default(0)` de coluna esquecida.

## 2.2 Identidade do usuário — sempre `userId` interno via `@CurrentUser()` (regra fixa do projeto)

`authenticatorId` (id do provider de auth externo) **só existe** dentro de `src/modules/v1/identity/o-auth/` e `src/configs/auth/`. Em qualquer outro lugar é proibido.

Controllers autenticados usam o decorator `@CurrentUser()` para acessar o `userId` interno já resolvido pelo `JwtAuthGuard`:

```ts
import { CurrentUser } from '@/infrastructure/decorators/current-user.decorator';
import type { CurrentUserContext } from '@/infrastructure/decorators/current-user.decorator';

@Get()
findAll(@CurrentUser() user: CurrentUserContext) {
  return this.queryBus.execute(new FindAllQuery(user.userId));
}
```

**Import obrigatoriamente separado:** `CurrentUser` (decorator, valor) e `CurrentUserContext` (interface, tipo) devem ser importados em linhas separadas — `import { CurrentUser }` normal e `import type { CurrentUserContext }` com `type`. Isso é exigido pelo TypeScript com `isolatedModules: true` + `emitDecoratorMetadata: true` (erro TS1272 se misturado em um import só).

**Nunca** use `@Req()`, `req.user.authenticatorId`, ou `UsersRepository.findByAuthenticatorId()` em handler/controller fora do módulo de autenticação. O guard já resolveu o `userId` interno (com cache) antes de chegar no controller — não repita esse trabalho.

Commands e queries recebem `userId: string` (interno), nunca `authenticatorId`.

## 2.3 Swagger nos DTOs de resposta — fiel ao retorno real (regra fixa do projeto)

O projeto usa **Orval** para gerar os tipos TypeScript do front a partir do OpenAPI. Por isso o Swagger **não é documentação opcional** — é contrato de tipagem. Todo DTO de resposta (`dtos/<entidade>.dto.ts`) deve refletir exatamente o que o back retorna.

### Regras obrigatórias

**Sempre especifique o `type` explicitamente** em todo `@ApiProperty` — nunca use `@ApiProperty()` sem argumentos, pois o Swagger pode inferir errado:

```ts
@ApiProperty({ type: String })   // string
@ApiProperty({ type: Number })   // number
@ApiProperty({ type: Boolean })  // boolean
@ApiProperty({ type: String, format: 'date-time' })  // Date serializada como ISO string
```

**Campo sempre presente mas que pode ser `null`** → `@ApiProperty({ type: String, nullable: true })`:

```ts
// ERRADO — gera field?: string no Orval (campo ausente), mas o back sempre retorna null
@ApiPropertyOptional()
@Expose()
complement: string | null;

// CERTO — gera field: string | null no Orval
@ApiProperty({ type: String, nullable: true })
@Expose()
complement: string | null;
```

**Campo que pode estar ausente do response** (raro — prefira sempre retornar `null`) → `@ApiPropertyOptional({ type: String })`.

**Campo de array de objetos** → use `{ type: () => [EntidadeDto] }`:

```ts
@ApiProperty({ type: () => [ItemDto] })
@Expose()
items: ItemDto[];
```

### Distinção crítica para o Orval

| Situação | Decorator correto | Orval gera |
|---|---|---|
| Sempre presente, nunca null | `@ApiProperty({ type: String })` | `field: string` |
| Sempre presente, pode ser null | `@ApiProperty({ type: String, nullable: true })` | `field: string \| null` |
| Pode estar ausente do response | `@ApiPropertyOptional({ type: String })` | `field?: string` |
| Ausente E pode ser null | `@ApiPropertyOptional({ type: String, nullable: true })` | `field?: string \| null` |

`@ApiPropertyOptional` é reservado para campos de **payload de entrada** (body, query params) que o cliente pode omitir. Em DTO de resposta, prefira sempre `nullable: true` quando o valor pode ser null — o back controla o shape, nunca omite campo do response silenciosamente.

## 2.4 DTO de resposta retorna só o que o front usa (regra fixa do projeto)

Antes de adicionar um campo ao DTO de domínio, pergunte: **o front vai usar isso?** Se não, não inclua.

Campos que **nunca** devem aparecer em DTO de resposta:
- `userId` — front não precisa saber quem é o dono; o dono é o usuário logado
- `status` — é detalhe interno de soft delete (ver 2.1)
- `createdAt` / `updatedAt` — só incluir se a UI exibir ou ordenar por data
- IDs internos de pivot/relação (ex: `addressId` numa linha de pedido quando o pedido já tem `address` embutido)

O DTO de domínio é o **contrato com o front** — quanto menor, mais fácil de manter e mais seguro (menos vazamento de dados). Se o front precisar de um campo depois, adiciona; nunca "deixa por precaução".

```ts
// ERRADO — expõe dados que o front não usa
export class AddressDto {
  @ApiProperty({ type: String }) @Expose() id: string;
  @ApiProperty({ type: String }) @Expose() userId: string;   // ← desnecessário
  @ApiProperty({ type: String }) @Expose() street: string;
  @ApiProperty({ type: String }) @Expose() createdAt: string; // ← desnecessário
}

// CERTO — só o que a UI consome
export class AddressDto {
  @ApiProperty({ type: String }) @Expose() id: string;
  @ApiProperty({ type: String }) @Expose() street: string;
  @ApiProperty({ type: Boolean }) @Expose() isDefault: boolean;
}
```

## 2.5 Cross-module: sempre via `QueryBus`/`CommandBus`, nunca injeção direta (regra fixa do projeto)

Quando um módulo precisa de algo de outro módulo (ex: `orders` precisa de produto do `catalog/products`, ou de endereço do `logistic/addresses`), a chamada é **sempre** via `queryBus.execute(new Find...Query(...))` / `commandBus.execute(new ...Command(...))` — nunca injeção direta de `Repository`/`Service` do módulo alvo no construtor, mesmo que esse `Repository`/`Service` esteja em `exports` do `*.module.ts` alvo.

**Por quê**: bus desacopla — o módulo consumidor só conhece o contrato (`Query`/`Command`), nunca a classe concreta nem a estrutura interna (schema, repository, provider) do módulo alvo. Injeção direta de repo cria acoplamento estrutural entre bounded contexts: qualquer refactor interno do módulo alvo (trocar repository, mudar schema, trocar de provider externo) quebra o módulo consumidor. Bus resolve isso: o módulo alvo pode reescrever tudo por dentro contanto que o handler continue respondendo ao mesmo `Query`/`Command`.

**Na prática**:
- Se o módulo alvo já tem a `Query`/`Command` que cobre o caso de uso, reuse ela.
- Se não tem, crie uma nova `queries/find-.../` ou `commands/.../` **dentro do módulo alvo** (nunca dentro do módulo consumidor) — mesmo que seja um wrapper fino em cima do repository (`execute()` só chamando `repository.findX(...)`), é ela que vira o contrato público do módulo pro resto do sistema.
- `*.module.ts` do módulo consumidor **não precisa** importar (`imports: [...]`) o módulo alvo pra isso funcionar — `QueryBus`/`CommandBus` resolve o handler globalmente contanto que o módulo alvo esteja registrado em algum ponto da árvore (normalmente já está, via `app.module.ts` ou um módulo pai). Só importe o módulo alvo se precisar mesmo de algo que ele exporta em `exports` (raro, e nesse caso não é pra injetar `Repository`/`Service` cross-module, é caso excepcional — confirme com o usuário antes).

```ts
// ERRADO — orders injeta repo de outro módulo direto
constructor(private readonly productsRepository: ProductsRepository) {}
const { items } = await this.productsRepository.findAllProducts({ productIds }, 1, ids.length);

// CERTO — orders fala com products via bus, usando a Query que products expõe
constructor(private readonly queryBus: QueryBus) {}
const { items } = await this.queryBus.execute(new FindAllProductsQuery(undefined, 1, ids.length, undefined, undefined, ids));
```

Exceção documentada: se o handler do módulo alvo tem orquestração pesada (chama provider externo, múltiplos repositories) e criar dependência reversa de módulo geraria import circular (`A` importa `B` e `B` já importa `A`), confirme com o usuário antes de decidir — pode ser aceitável manter via bus só (que já resolve o ciclo, já que bus não precisa de `imports`) em vez de reestruturar módulos.

## 2.5.1 Repository nunca sai do módulo — nem pra guard global, nem pra `app.module.ts` (regra fixa do projeto)

Todo `Repository`/`Service` de infraestrutura de um módulo (`infrastructure/database/...`) é `provider` **daquele** `*.module.ts` e só dele. Nenhum outro lugar do código — outro módulo de feature (isso já é a regra 2.5, via bus), mas também `app.module.ts`, um guard global, um interceptor global, ou qualquer coisa fora do módulo — pode importar a classe e declará-la solta no próprio `providers: [...]`. Quem precisa do repository **importa o módulo** (`imports: [XModule]`) e consome via `exports` dele — nunca reimporta a classe crua e a registra em outro lugar.

Isso vale mesmo quando quem precisa do repository não é outro módulo de feature, e sim infraestrutura transversal (ex: um `CanGuard` registrado como `APP_GUARD` em `app.module.ts` que precisa ler permissões do banco). Nesse caso, `app.module.ts` importa o `*.module.ts` do domínio dono do repository (ex: `PoliciesModule`, que declara `providers: [PermissionsRepository]` e `exports: [PermissionsRepository]`) — nunca declara `PermissionsRepository` direto no `providers` do `AppModule`.

```ts
// ERRADO — app.module.ts registra repository de outro módulo direto
import { PermissionsRepository } from '@/modules/v1/tenancy/policies/infrastructure/database/drizzle/permissions-query.repository';

@Module({
  providers: [
    { useClass: CanGuard, provide: APP_GUARD },
    PermissionsRepository, // repository "solto", fora do módulo dono
  ],
})

// CERTO — repository só existe dentro do PoliciesModule; app.module.ts importa o módulo
import { PoliciesModule } from '@/modules/v1/tenancy/policies/policies.module';

@Module({
  imports: [PoliciesModule],
  providers: [{ useClass: CanGuard, provide: APP_GUARD }],
})
```

Por quê: repository solto em `app.module.ts` quebra a regra de encapsulamento por módulo (2.5) pela porta dos fundos — mesmo sem ser "outro módulo de feature", ainda é um consumidor externo enxergando a classe concreta e o `provide` interno do módulo dono. Se o módulo dono trocar a implementação do repository, todo lugar que o importou solto precisa mudar junto; importando o módulo, só o `*.module.ts` dono precisa saber o que mudou por dentro.

## 2.6 Intra-módulo: cada Command dono da regra ponta a ponta, sem duplicar (regra fixa do projeto)

Dentro do **mesmo módulo**, se duas ou mais ações (`Command`s) precisam do mesmo pedaço de regra de negócio (ex: "quando os itens do pedido mudam, invalida frete e recalcula status"), essa regra vira **um `Command`/`Handler` próprio**, e as ações que precisam dela chamam via `commandBus.execute(new Aquele...Command(...))` — nunca cada handler reimplementando o mesmo bloco de lógica inline.

Regra de identificação: antes de escrever um handler novo, pergunte — "esse pedaço de lógica (validar, mudar status, disparar efeito colateral) já existe igual em outro handler do módulo?" Se sim, extrai pra um Command novo em vez de copiar. Se um Command precisa que outro Command rode como parte da sua própria regra (ex: excluir item de vez do pedido precisa também invalidar progresso do pedido), ele chama o outro via `commandBus.execute(...)` — cada Command cuida da sua fatia da regra do início ao fim, e compõe com outros Commands do mesmo módulo em vez de inline duplicado.

```ts
// ERRADO — AddItemsHandler e UpdateItemQuantityHandler reimplementam a mesma regra cada um no seu arquivo
if (order.status >= OrderStatus.ADDRESS_SELECTED) {
  await this.commandBus.execute(new RemoveOrderShippingCommand(order.id));
  await this.ordersCommandRepository.updateStatus(order.id, OrderStatus.CART);
}

// CERTO — regra extraída pra commands/invalidate-order-progress/, cada handler só delega
await this.commandBus.execute(new InvalidateOrderProgressCommand(order.id, order.status, remainingItemsCount));
```

Exemplo do padrão: um command que reaproveita a regra de outro command já existente (ex: um fluxo de "atualizar quantidade" que, ao zerar, chama o command de "remover item" em vez de duplicar a lógica de exclusão) — procure um caso assim já existente no projeto pra usar de referência.

## 3. Nomenclatura (regra fixa do projeto, ver AGENTS.md)

- Método/query/handler de **listagem** (mesmo sem paginação real ainda) = `findAll...` (ex: `FindAllCategoriesQuery`, `findAllCategories()`).
- Método/query/handler de **busca por uma prop específica** = `find...` (ex: `FindProductBySlugQuery`, `findBySlug()`).
- Nunca `findCategories`/`getCategories` — sempre esse prefixo.

## 3.0 Idioma das propriedades — English-only, sem exceção (regra fixa do projeto)

**Todas as propriedades de DTO de domínio (resposta e payload) são sempre em inglês.** Isso vale mesmo quando o dado vem de uma API externa em português (Brasil API, Correios, etc.) ou quando o campo é um termo técnico brasileiro (CEP, UF, CPF, CNPJ).

Mapeie no service, antes de retornar:

```ts
// Brasil API retorna { sigla, nome } → mapear para
{ abbreviation: raw.sigla, name: raw.nome }

// Brasil API retorna { cep } → mapear para
{ postalCode: data.cep }

// Brasil API retorna { codigo_ibge } → mapear para
{ ibgeCode: raw.codigo_ibge }
```

A única exceção são **mensagens de aviso/erro retornadas ao front** (strings de texto visível ao usuário) — essas devem estar em português, mas **sempre via i18n** (arquivo de tradução em `src/infrastructure/translate/`), nunca hardcoded em PT no código. Strings hardcoded em qualquer idioma dentro do código são proibidas para mensagens ao usuário.

### Todo erro lançado usa `BusinessException` — nunca `NotFoundException`/`BadRequestException`/`ConflictException`/`ForbiddenException` nativas do Nest (regra fixa do projeto)

As exceptions nativas do `@nestjs/common` passadas com string solta (`throw new NotFoundException('order.not_found')`) **não passam por nenhum filtro global** — caem no handler default do Nest, sem tradução, sem o shape `{ errors, status }` padrão da API. Só `BusinessException` é interceptada (`business-exception.filter.ts`) e devolve `{ message: <traduzido>, code: <código> }` de verdade.

Toda vez que um handler/service precisar recusar/abortar com erro pro cliente, use:

```ts
import { BusinessException } from '@/infrastructure/exceptions/infrastructure/business-client-exception.exception';
import { CodeExceptions } from '@/infrastructure/enums/code-exceptions.enum';
import { HttpStatus } from '@nestjs/common';

// status default é BAD_REQUEST — só passa o 2º argumento quando for outro (NOT_FOUND, CONFLICT, FORBIDDEN...)
throw new BusinessException(CodeExceptions.ORDER_NOT_FOUND, HttpStatus.NOT_FOUND);
throw new BusinessException(CodeExceptions.ORDER_ITEMS_REQUIRED); // 400 implícito
```

**Antes de lançar qualquer erro, confira `src/infrastructure/exceptions/`** — pode já existir uma exception pronta pro cenário (ex: `business-client-exception.exception.ts` → `BusinessException`, o caso de uso padrão pra erro de negócio; outras pastas ali cobrem cenários específicos como fluxo de auth de provider externo ou validação de schema). Reaproveita a que já existe em vez de inventar uma nova. **Se nenhuma exception existente cobrir o cenário, para e avisa o usuário** — não force `BusinessException` num caso que não é erro de negócio nem crie uma exception nova por conta própria sem confirmar.

**Passos pra cada erro novo de um módulo:**
1. Adicionar uma entrada em `src/infrastructure/enums/code-exceptions.enum.ts`, prefixo de 3 letras do domínio + módulo + número sequencial de 4 dígitos, seguindo o padrão já usado (`idt:oauth:0001` pra identity/oauth) — ex: `ORDER_NOT_FOUND = 'com:orders:0001'` pra commerce/orders. Nunca reaproveitar prefixo de outro domínio.
2. Adicionar a tradução correspondente em `src/infrastructure/translate/pt-BR/exceptions.json`, dentro do objeto `"business"`, usando a MESMA string do enum como chave (ex: `"com:orders:0001": "Pedido não encontrado."`). Sem essa entrada, o filtro devolve `message: undefined`.

```ts
// ERRADO — não passa por nenhum filtro, mensagem crua, sem tradução
throw new NotFoundException('order.not_found');

// CERTO
throw new BusinessException(CodeExceptions.ORDER_NOT_FOUND, HttpStatus.NOT_FOUND);
```

Ao criar um módulo novo, adicionar todas as chaves de erro do módulo em `code-exceptions.enum.ts` + `exceptions.json` junto com os arquivos do módulo — nunca deixar pra depois.

## 3.1 Saída do back é prop a prop — nunca spread (regra fixa do projeto)

Todo objeto que **atravessa a fronteira do backend** é montado campo a campo, explicitamente. Spread (`{ ...payload }`) é proibido nesses dois casos:

- **Escrita em banco** — `.values()`, `.set()`, insert/update de repository.
- **Envio para integração externa** — comando de SDK (AWS, etc.), body/params de request HTTP pro provider.

Spread continua liberado **dentro** do back: retorno de handler pro controller, composição entre camadas, providers de módulo (`[...handlers, ...services]`).

Motivo: com spread, o que atravessa a fronteira fica implícito. Um campo novo no tipo de origem vaza sozinho pro banco ou pro terceiro sem passar por revisão. Prop a prop torna o contrato explícito e faz o compilador e o review pegarem a mudança.

```ts
// ERRADO — repository de escrita
await this.db.insert(usersTable).values({ ...payload, id: createCUID('usr') });

// CERTO
await this.db.insert(usersTable).values({
  authenticatorId: payload.authenticatorId,
  id: createCUID('usr'),
  email: payload.email,
  name: payload.name,
});
```

Campo opcional usa ternário no próprio campo, nunca spread condicional:

```ts
// ERRADO — service de integração
...(message.text ? { Text: { Data: message.text, Charset: 'UTF-8' } } : {}),

// CERTO
Text: message.text ? { Data: message.text, Charset: 'UTF-8' } : undefined,
```

## 3.2 Verbo HTTP decide Query vs Command — não o efeito colateral (regra fixa do projeto)

**A classificação CQRS segue o verbo HTTP do endpoint, não se o handler muda estado ou não.**

- `@Get(...)` → sempre `Query`/`QueryHandler`/`QueryBus`, pasta `queries/`.
- `@Post(...)`, `@Put(...)`, `@Patch(...)`, `@Delete(...)` → sempre `Command`/`CommandHandler`/`CommandBus`, pasta `commands/`.

Isso vale mesmo quando o endpoint não persiste nada (ex: uma calculadora de preço/frete que só lê de um provider externo e devolve um número). Se o cliente manda dado no body (`@Post`/`@Put`/`@Patch`) ou pede exclusão (`@Delete`), é `Command` — a ausência de mutação em banco não isenta. Só GET puro (sem body, só query params/path params) é `Query`.

Motivo: verbo HTTP já é o contrato público da API sobre efeito esperado (idempotência, cache, retry automático de cliente). Deixar a classificação interna seguir esse mesmo contrato evita a situação de um endpoint que "parece leitura" por fora (semântica de negócio) mas se comporta diferente por dentro (ex: um poderia usar CommandBus outro QueryBus para o mesmo tipo de payload) — o verbo já decide, sem debate caso a caso.

Na prática, isso significa: qualquer endpoint que precise de body (payload que não cabe em query string — lista de itens, objeto aninhado) é `@Post` + `Command`, mesmo sendo uma "calculadora"/consulta pura. Ex: um endpoint que calcula um preço a partir de uma lista de itens no body é `Command`, não `Query`, porque é `@Post` — o verbo decide, não o fato de não escrever nada no banco.

## 3.3 `findAll` paginável nunca pagina em memória (regra fixa do projeto)

Sempre que um `findAll` puder ser paginado, a paginação é **sempre real na fonte**, nunca "busca tudo e corta em memória (`.slice()`)" — nem pro banco, nem pra provider externo.

- **Dado nosso, vindo do banco (Drizzle)**: sempre pagina. Usa `LIMIT`/`OFFSET` (`.limit(perPage).offset((page - 1) * perPage)`) direto na query do repository, mais um `count()` separado (`select({ value: count() }).from(table)`, mesmo `where`) pra `total`/`totalPages`. Nunca `select().from(table)` sem `limit` seguido de slice em JS.
- **Provider externo**: antes de implementar, confirma na doc oficial do provider se ele aceita paginação de verdade (`page`/`per_page`, cursor, etc). Se aceitar, repassa os parâmetros de paginação recebidos direto pra chamada e devolve a página que o provider já devolveu — não busca o dataset inteiro pra paginar depois em memória. Se o provider **não** aceitar paginação nativa (ou a paginação dele não é compatível com o filtro que o módulo precisa aplicar — caso real de `{Provider}FindAll{Entidades}Service`, que filtra por tag/busca livre que o provider não suporta nativamente, então busca o catálogo publicado inteiro e pagina o resultado filtrado em memória), documenta no código o motivo (comentário curto explicando por que não dá pra paginar na fonte) antes de recorrer a isso — é exceção, não o padrão.

Response DTO de listagem paginada segue sempre a forma de `src/modules/v1/catalog/products/dtos/paginated-products.dto.ts`:

```ts
export class Paginated{Entidades}Dto {
  @ApiProperty({ type: [{Entidade}Dto] })
  items: {Entidade}Dto[];

  @ApiProperty()
  page: number;

  @ApiProperty()
  perPage: number;

  @ApiProperty()
  total: number;

  @ApiProperty()
  totalPages: number;
}
```

`find-all-{entidades}.dto.ts` (query params) ganha `page`/`perPage` com os mesmos decorators de `products/queries/find-all-products/find-all-products.dto.ts`:

```ts
@ApiPropertyOptional({ minimum: 1, default: 1 })
@Type(() => Number)
@IsOptional()
@IsInt()
@Min(1)
page?: number;

@ApiPropertyOptional({ maximum: 200, default: 200, minimum: 1 })
@Type(() => Number)
@IsOptional()
@Max(200)
@IsInt()
@Min(1)
perPage?: number;
```

Repository de banco (exemplo real de paginação em DB, adaptar tabela/campos):

```ts
async findAllPaginated(page: number, perPage: number): Promise<{ items: TEntity[]; total: number }> {
  const offset = (page - 1) * perPage;

  const [items, [{ value: total }]] = await Promise.all([
    this.db.select().from(table).limit(perPage).offset(offset),
    this.db.select({ value: count() }).from(table),
  ]);

  return { items, total };
}
```

Handler monta `totalPages` a partir do `total` (`Math.max(1, Math.ceil(total / perPage))`), igual `{Provider}FindAll{Entidades}Service.findAll`.

**Paginação de banco sempre performática, sem exceção:**

- `select` (com `limit`/`offset`) e `select count()` **sempre em paralelo** via `Promise.all`, nunca um `await` depois do outro — são duas queries independentes, rodar em série dobra a latência à toa (ver template do repository acima).
- Toda coluna usada em `where`/`orderBy` da listagem paginada precisa de índice — se a tabela ainda não tem índice na coluna filtrada/ordenada, cria a migration do índice junto com a do módulo, não deixa pra depois.
- `OFFSET` alto é caro (o banco ainda percorre e descarta as linhas puladas) — pra listagem comum de admin/catálogo com poucas páginas isso não importa, então `LIMIT`/`OFFSET` continua o padrão default. Só considera paginação por keyset (`WHERE id > :cursor ORDER BY id LIMIT :perPage`) se o volume esperado da tabela for alto (dezenas de milhares de linhas +) ou o acesso for por scroll infinito — nesse caso, pergunta ao usuário antes de trocar o padrão, não troca sozinho.
- Nunca faz um `select count()` por linha nem dentro de loop — é uma query só, fora de qualquer `map`/`forEach`.

## 3.4 Coluna de banco: tamanho pensado + `class-validator` espelhando o limite (regra fixa do projeto)

Toda coluna `varchar` nova tem um `{ length: N }` **pensado pro campo real**, nunca um número arbitrário copiado de outra coluna. Antes de definir, pergunta: qual o maior valor plausível desse campo no mundo real? (nome de produto/categoria/tag: ~120-160; slug: nome + folga pra sufixo de unicidade, ~160; e-mail: 254 é o teto do RFC; etc). Column sem limite (`text`) só quando o campo é genuinamente de tamanho livre (descrição longa, corpo de mensagem) — nunca por preguiça de pensar no limite.

O DTO de payload (`class-validator`) **sempre espelha esse limite** com `@MaxLength(N)`, usando o mesmo `N` da coluna — nunca deixa o banco ser a única defesa (senão o erro só aparece como 500/constraint violation do Postgres, não como 400 validado). Exemplo:

```ts
// schema
name: varchar('name', { length: 120 }).notNull(),

// payload dto
@MaxLength(120, { message: 'name.max_length' })
@IsNotEmpty({ message: 'required' })
@IsString({ message: 'invalid' })
@ApiProperty()
name: string;
```

## 3.5 Coluna `slug` (regra fixa do projeto quando a entidade tiver slug)

Quando a entidade precisa de slug (URL amigável), a coluna é sempre `varchar` com `.unique()`, e o valor é **sempre gerado no back a partir do `name`**, nunca recebido do client no payload — usa o helper global `src/infrastructure/helpers/slugify.helper.ts` (`slugify(value): string`, kebab-case ascii sem acento; cria esse helper se ainda não existir, não duplica lógica de slugify local ao módulo).

- Geração acontece **só no `create`**. Editar o `name` depois (`update`) **não** regenera o slug — um slug que muda quebra link já publicado/indexado.
- Unicidade é resolvida no `CommandRepository`, checando colisão contra a própria tabela e resolvendo com sufixo incremental (`-2`, `-3`, ...) até achar um livre — nunca deixa a constraint do banco estourar como erro 500 pro usuário.

```ts
// {modulo}-command.repository.ts
import { slugify } from '@/infrastructure/helpers/slugify.helper';

private async generateUniqueSlug(name: string): Promise<string> {
  const base = slugify(name);
  let slug = base;
  let suffix = 2;

  while (await this.slugExists(slug)) {
    slug = `${base}-${suffix}`;
    suffix += 1;
  }

  return slug;
}

private async slugExists(slug: string): Promise<boolean> {
  const [existing] = await this.db.select({ id: table.id }).from(table).where(eq(table.slug, slug)).limit(1);
  return Boolean(existing);
}
```

Se o retorno público da entidade é enxuto (ex: só `id`/`name`/`slug`, sem `status`/`createdAt`/`updatedAt`), o DTO de domínio (`dtos/{entidade}.dto.ts`) só expõe (`@Expose()`) os campos pedidos — os demais continuam existindo na tabela/entidade (ex: `status` pro softdelete continuar funcionando via `update`/`delete`), só não aparecem no `@Expose()` do dto de resposta.

## 3.6 Seed de dado inicial (quando o usuário pedir) — nunca duplica ao rodar de novo

Seed fica em `drizzle/seeds/{modulo}/`, uma pasta por entidade com dois arquivos:

```
drizzle/seeds/{modulo}/
├── data.json     # valores já prontos pra ir pro banco -- id, slug etc já calculados, sem lógica de geração no seed
└── index.ts      # export async function seed{Entidades}(db) { ... }
```

`data.json` carrega os valores **finais**, não um shape cru pra transformar — `id` já é um CUID fixo (gerado uma vez, hardcoded), `slug` já vem calculado, nada de chamar `slugify`/`createCUID` dentro do `index.ts` do seed. Isso torna o seed determinístico entre execuções e entre ambientes (mesmo `id` sempre, sem depender de gerar em runtime). Procure um seed já existente no projeto pra usar de referência.

`index.ts` só lê o json e insere:

```ts
import { NodePgDatabase } from 'drizzle-orm/node-postgres';

import { {tabela} } from '@/modules/v1/{dominio}/{modulo}/infrastructure/database/drizzle/{modulo}.schema';
import { logger } from '@/configs/seeds/logger';
import * as schema from '@/configs/database/schema';

import {entidades} from './data.json';

export async function seed{Entidades}(db: NodePgDatabase<typeof schema>) {
  await db.insert({tabela}).values({entidades}).onConflictDoNothing({ target: {tabela}.{colunaUnica} });
  logger('{ENT}', 'CRE', '{entidades} seeded');
}
```

Registrado em `src/configs/seeds/database/index.ts` (import + chamada dentro do `main()`, mesma ordem dos demais).

**Rodar o seed duas vezes nunca pode duplicar linha.** Todo insert de seed usa `.onConflictDoNothing({ target: {tabela}.{colunaUnica} })`, apontando pra uma coluna com `.unique()` de verdade na tabela (slug, email, etc — nunca `id`, porque mesmo sendo fixo no json, `id` sozinho não é a garantia de negócio contra duplicata semântica). Se a entidade não tem nenhuma coluna unique além de `id`, adiciona uma antes de escrever o seed (não escreve seed sem proteção de duplicidade).

`logger` (`src/configs/seeds/logger.ts`) tem uma união fixa de siglas de entidade — adiciona a sigla nova (3 letras) no type `SeedEntity` se ainda não existir.

## 4. Templates de arquivo

Adapte `{Modulo}`, `{modulo}`, `{Entidade}`, `{entidade}`, `{entidades}`, `{Provider}`, `{provider}` ao caso real. Todo import relativo deve ser calculado pela profundidade real do arquivo — não copie os `../` cegamente.

### 4.1 DTO de domínio (`dtos/{entidade}.dto.ts`) — carrega o mapeamento via `@Transform`

Cada campo tem um `@Transform(({ obj }) => ...)` que lê do dto **raw** (`obj` tipado como `{Provider}{Entidade}Dto`) e devolve o valor já no formato de domínio. Campo trivial (mesmo nome, sem transformação) não precisa de `@Transform`, só `@Expose`. Reaproveite helper global (`pickLocalizedText`, `parsePriceToCents`, etc) dentro do `@Transform` em vez de reescrever a lógica — ver seção "Mapeamento raw → domínio" acima.

```ts
import { {algumHelperGlobalSeNecessario} } from '@/infrastructure/services/{provider}/helpers/{helper}.helper'; // só se precisar

import { {Provider}{Entidade}Dto } from '../infrastructure/{provider}/dtos/{provider}-{entidade}.dto';
import { Expose, Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class {Entidade}Dto {
  @Transform(({ obj }: { obj: {Provider}{Entidade}Dto }) => String(obj.id))
  @ApiProperty()
  @Expose()
  id: string;

  // campo sem transformação, só rename/pick direto:
  @ApiProperty()
  @Expose()
  algumCampoIgual: string;

  // ...demais campos, cada um com @Transform quando precisar computar/converter
}
```

Service usa esse dto com `plainToInstance` (template 4.4) — não existe função `map...` separada.

### 4.2 DTO raw do provider (`infrastructure/{provider}/dtos/{provider}-{entidade}.dto.ts`)

Sem decorators — é só o shape que a API externa devolve, tipado.

```ts
export class {Provider}{Entidade}Dto {
  id: number;
  // ...campos exatamente como o provider devolve, nomes originais (snake_case se for o caso)
}
```

### 4.3 Helper global (só se a lógica realmente se repetir em mais de um lugar)

**Não crie `infrastructure/{provider}/helpers/` dentro do módulo.** Se, ao escrever o `@Transform` do DTO (4.1), perceber que a mesma lógica já é (ou vai ser) usada em outro campo/módulo, extraia pra um helper **global**, fora de `src/modules/`:

- Lógica específica do provider (ex: escolher texto localizado, montar `{id, name}` a partir de um shape com nome localizado) → `src/infrastructure/services/{provider}/helpers/{nome}.helper.ts`.
- Lógica genérica de projeto, sem relação com o provider (ex: converter preço string pra centavos) → `src/infrastructure/helpers/{nome}.helper.ts`.

```ts
// src/infrastructure/services/{provider}/helpers/{nome}.helper.ts (exemplo)
export function {nomeDaFuncao}(entrada: TipoEntrada): TipoSaida {
  // função pura, sem I/O, sem @Injectable
}
```

Antes de escrever, procure se já existe algo assim (ex: `pick-localized-text.helper.ts`, `map-provider-id-name.helper.ts`, `parse-price-to-cents.helper.ts`) — reaproveite em vez de duplicar.

### 4.4 Service de integração — um arquivo por caso de uso

**Responsabilidade única: cada service resolve UM caso de uso.** Se o módulo precisa de `findAll` e `findBySlug`, são dois arquivos, duas classes, cada uma com seu próprio `@Injectable()` — nunca uma classe com dois métodos públicos. Ambos chamam o client global do provider (`@Inject` do token exportado por `src/infrastructure/services/{provider}/{provider}.provider.ts` — crie esse provider global primeiro se ainda não existir, seguindo outro provider já existente no projeto como referência), convertem o resultado com `plainToInstance` (**não** com uma função `map...` manual — o mapeamento já está nos `@Transform` do dto, template 4.1), logam erro e lançam exceção HTTP apropriada. Cache via `CACHE_MANAGER` quando o dado mudar pouco.

`infrastructure/{provider}/services/find-all-{entidades}.service.ts`:
```ts
import type { AxiosInstance } from 'axios'; // ou o SDK do provider

import { ServiceUnavailableException, Injectable, Inject, Logger } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';

import { {PROVIDER}_CLIENT } from '@/infrastructure/services/{provider}/{provider}.provider';

import { {Provider}{Entidade}Dto } from '../dtos/{provider}-{entidade}.dto';
import { {Entidade}Dto } from '../../../dtos/{entidade}.dto';

@Injectable()
export class {Provider}FindAll{Entidades}Service {
  private readonly logger = new Logger({Provider}FindAll{Entidades}Service.name);

  constructor(
    @Inject({PROVIDER}_CLIENT)
    private readonly client: AxiosInstance,
  ) {}

  async findAll(): Promise<{Entidade}Dto[]> {
    try {
      const { data } = await this.client.get<{Provider}{Entidade}Dto[]>('/{recurso}');

      return plainToInstance({Entidade}Dto, data, { excludeExtraneousValues: true });
    } catch (error) {
      this.logger.error('Failed to fetch {entidades}', error);

      throw new ServiceUnavailableException('Failed to fetch {entidades}');
    }
  }
}
```

`infrastructure/{provider}/services/find-{entidade}-by-{prop}.service.ts` (mesma forma, outro caso de uso, outro arquivo):
```ts
@Injectable()
export class {Provider}Find{Entidade}By{Prop}Service {
  private readonly logger = new Logger({Provider}Find{Entidade}By{Prop}Service.name);

  constructor(
    @Inject({PROVIDER}_CLIENT)
    private readonly client: AxiosInstance,
  ) {}

  async findBy{Prop}({prop}: string): Promise<{Entidade}Dto | null> {
    // mesma lógica de try/catch/log do exemplo acima; se achar registro, `plainToInstance({Entidade}Dto, raw, { excludeExtraneousValues: true })`, senão null
  }
}
```

### 4.5 Query (leitura) — `queries/find-all-{entidades}/`

`find-all-{entidades}.query.ts`:
```ts
export class FindAll{Entidades}Query {
  constructor(public readonly algumFiltro?: string) {} // sem args se não houver filtro
}
```

`find-all-{entidades}.handler.ts`:
```ts
import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';

import { {Provider}FindAll{Entidades}Service } from '../../infrastructure/{provider}/services/find-all-{entidades}.service';
import { FindAll{Entidades}Query } from './find-all-{entidades}.query';
import { {Entidade}Dto } from '../../dtos/{entidade}.dto';

@QueryHandler(FindAll{Entidades}Query)
export class FindAll{Entidades}Handler implements IQueryHandler<FindAll{Entidades}Query> {
  constructor(private readonly service: {Provider}FindAll{Entidades}Service) {}

  execute(query: FindAll{Entidades}Query): Promise<{Entidade}Dto[]> {
    return this.service.findAll(query.algumFiltro);
  }
}
```

Se a query tiver query params via `@Query()` no controller, crie também `find-all-{entidades}.dto.ts` com `class-validator` (`@IsOptional`, `@ApiPropertyOptional`), igual `products/queries/find-all-products/find-all-products.dto.ts`.

Query de busca específica segue o mesmo formato mas com prefixo `Find` (sem `All`) — ver `products/queries/find-product-by-slug/`.

### 4.6 Command (escrita) — `commands/{verbo}-{entidade}/`

Procure um command de autenticação já existente no projeto pra usar de referência.

`{verbo}-{entidade}.command.ts` (classe simples; use `extends Command<TResultado>` do `@nestjs/cqrs` só quando quiser o retorno tipado no `CommandBus.execute`):
```ts
export class {Verbo}{Entidade}Command {
  constructor(public readonly campo: string) {}
}
```

`{verbo}-{entidade}.dto.ts` (Payload = validação de entrada com `class-validator`, Result = shape de saída com `class-transformer`):
```ts
import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Expose } from 'class-transformer';

export class {Verbo}{Entidade}PayloadDto {
  @IsNotEmpty({ message: 'required' })
  @IsString({ message: 'invalid' })
  @ApiProperty()
  campo: string;
}

export class {Verbo}{Entidade}ResultDto {
  @Expose()
  @ApiProperty()
  id: string;
}
```

`{verbo}-{entidade}.handler.ts`:
```ts
import { ICommandHandler, CommandHandler } from '@nestjs/cqrs';

import { {Provider}{Verbo}{Entidade}Service } from '../../infrastructure/{provider}/services/{verbo}-{entidade}.service';
import { {Verbo}{Entidade}Command } from './{verbo}-{entidade}.command';

@CommandHandler({Verbo}{Entidade}Command)
export class {Verbo}{Entidade}Handler implements ICommandHandler<{Verbo}{Entidade}Command> {
  constructor(private readonly service: {Provider}{Verbo}{Entidade}Service) {}

  async execute(command: {Verbo}{Entidade}Command) {
    return this.service.{verbo}(command.campo);
  }
}
```

### 4.7 Controller (`{modulo}.controller.ts`)

```ts
import { Controller, Get, Post, Body, Query } from '@nestjs/common';
import { CommandBus, QueryBus } from '@nestjs/cqrs';

import { SwaggerGet } from '@/infrastructure/decorators/swagger-get.decorator';
import { SwaggerPost } from '@/infrastructure/decorators/swagger-post.decorator';
import { Public } from '@/infrastructure/decorators/public.decorator'; // só se a rota for pública

import { FindAll{Entidades}Query } from './queries/find-all-{entidades}/find-all-{entidades}.query';
import { {Entidade}Dto } from './dtos/{entidade}.dto';

@Controller('v1/{dominio}/{modulo}')
export class {Modulo}Controller {
  constructor(
    private readonly queryBus: QueryBus,
    private readonly commandBus: CommandBus, // só se houver command
  ) {}

  @SwaggerGet({ responseModel: {Entidade}Dto, isArray: true })
  @Get()
  findAll{Entidades}() {
    return this.queryBus.execute(new FindAll{Entidades}Query());
  }
}
```

Use `@Public()` acima do método **só** quando confirmado com o usuário que a rota não exige autenticação (ver `products.controller.ts`/`categories.controller.ts` como exemplo de rota pública, `o-auth.controller.ts` como exemplo misto).

### 4.8 Module (`{modulo}.module.ts`)

```ts
import { CqrsModule } from '@nestjs/cqrs';
import { Module } from '@nestjs/common';

import { FindAll{Entidades}Handler } from './queries/find-all-{entidades}/find-all-{entidades}.handler';
import { {Provider}FindAll{Entidades}Service } from './infrastructure/{provider}/services/find-all-{entidades}.service';
// ...um import por service de caso de uso (find-by-slug, etc), cada um seu próprio arquivo
import { {Modulo}Controller } from './{modulo}.controller';

const services = [{Provider}FindAll{Entidades}Service /* , ...demais services, um por caso de uso */];

@Module({
  providers: [FindAll{Entidades}Handler, ...services],
  exports: services, // só exporte o que outro módulo realmente precisa consumir
  controllers: [{Modulo}Controller],
  imports: [CqrsModule],
})
export class {Modulo}Module {}
```

Cada módulo é standalone — **não** crie um módulo "agregador" pra agrupar módulos irmãos (ex: não existe `catalog.module.ts` agregando `products`+`categories`). Se um módulo precisa de outro, a comunicação é sempre via `QueryBus`/`CommandBus` (seção 2.5) — **não** importa o módulo irmão em `imports` nem injeta `Repository`/`Service` dele, mesmo que esteja exportado.

### 4.9 Webhook Command + Handler — `webhooks/commands/handle-<provider>-webhook/`

O endpoint de webhook no controller é sempre `@Public() @HttpCode(200)` (sem JWT — autenticado via HMAC no handler). Controller só extrai headers + body e passa para o CommandBus; toda validação e lógica estão no handler.

`handle-<provider>-webhook.command.ts`:
```ts
export class Handle<Provider>WebhookCommand {
  constructor(
    public readonly signature: string,   // ex: x-signature do MP
    public readonly requestId: string,   // ex: x-request-id do MP
    public readonly body: Record<string, unknown>,
  ) {}
}
```

`handle-<provider>-webhook.handler.ts`:
```ts
import { createHmac, timingSafeEqual } from 'crypto';

import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { UnauthorizedException, Logger } from '@nestjs/common';

import { Handle<Provider>WebhookCommand } from './handle-<provider>-webhook.command';

@CommandHandler(Handle<Provider>WebhookCommand)
export class Handle<Provider>WebhookHandler implements ICommandHandler<Handle<Provider>WebhookCommand> {
  private readonly logger = new Logger(Handle<Provider>WebhookHandler.name);

  async execute(command: Handle<Provider>WebhookCommand): Promise<void> {
    // 1. Freshness check
    const ts = /* extrair timestamp da assinatura */;
    if (Math.abs(Date.now() - ts * 1000) > 300_000) {
      throw new UnauthorizedException('webhook.expired');
    }

    // 2. HMAC-SHA256 — timing-safe compare
    const secret = process.env.PROVIDER_WEBHOOK_SECRET!;
    const manifest = /* monta a string de assinatura conforme o provider */;
    const expected = createHmac('sha256', secret).update(manifest).digest();
    const received = Buffer.from(/* v1 extraído da assinatura */, 'hex');

    if (received.length !== expected.length || !timingSafeEqual(received, expected)) {
      throw new UnauthorizedException('webhook.invalid_signature');
    }

    // 3. SEMPRE re-confirma estado com o provider antes de qualquer write
    //    Nunca confia no status que vem no body do webhook
    const confirmedPayment = await this.<provider>GetPaymentService.get(command.body.data.id as string);

    // 4. Atualiza DB com estado confirmado
    // ...
  }
}
```

**Regras fixas para webhook handlers:**
- Nunca usar o `status` do body do webhook — sempre re-confirmar com o provider via GET
- `timingSafeEqual` obrigatório (previne timing attacks)
- Freshness check de ±5 min obrigatório
- Retornar `200 OK` imediatamente após processar — nunca 4xx para evento desconhecido (loga e ignora)
- Handler deve ser **idempotente**: mesmo evento duas vezes → estado final idêntico, sem erro

## 5. Provider global do fornecedor externo (se ainda não existir)

Se o módulo é o primeiro a integrar esse provider, crie antes (fora do módulo, em `src/infrastructure/services/{provider}/`):
- `{provider}.provider.ts` — factory do client (axios/SDK), token de injeção, valida env vars e lança `InternalServerErrorException` se faltar config. Ver outro provider já existente no projeto como referência.
- `{provider}.module.ts` — `@Global()`, exporta o token.
- Registre as env vars em `src/configs/environment/index.ts` (namespace `{provider}: {...}`) e em `.env.example`/`.env`.
- Registre o módulo global em `src/app.module.ts` (`imports`).

## 6. Depois de criar os arquivos

1. Registre `{Modulo}Module` em `src/app.module.ts` (`imports`), **não** dentro de um módulo agregador.
2. Diga quais env vars novas (se houver) precisam ser preenchidas.
3. **Pare aí.** Não rode `tsc`, `eslint`, `pnpm start`, `pnpm build`, `pnpm test` nem qualquer outro comando de verificação — nem mesmo lint/type-check. Essa skill não roda nada, só escreve arquivo. Validação é o usuário quem pede, quando pedir.

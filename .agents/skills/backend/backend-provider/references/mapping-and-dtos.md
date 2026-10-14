# Persistence standard, raw-to-domain mapping, DTOs and global helpers

## Platform persistence standard

When a provider integration writes to a local entity that follows the standard pattern, the local schema and use cases use `deletedAt` and `archivedAt`, never a persistence `status` column or Redis code reservation. Provider payloads may contain their own external `status`; it stays in the raw provider DTO and is mapped explicitly to the domain business enum when needed.

Local create/update/archive/delete/restore operations follow `backend-cqrs` and `backend-sql`: qualified command names, separate command/query repositories, `QueryBus` for cross-module relations, exclusion of deleted records, delete only after archive, and no broad repository `try/catch`. Global filters translate expected persistence constraints; provider-specific errors are handled at the provider boundary without exposing provider or database implementation details.

## Raw → domain mapping: `plainToInstance` + `@Transform`, **not** a module helper

**Avoid helpers as much as possible.** The module **has no** `infrastructure/<provider>/helpers/`. Raw→domain mapping lives as `@Transform` directly on the fields of the `http/dtos/{entity}.dto.ts` dto, and the service calls `plainToInstance({Entity}Dto, raw, { excludeExtraneousValues: true })` instead of a hand-written `map...` function. The real providers of this codebase live in `src/infrastructure/providers/` (`geo-provider`, `auth-provider`, `storage-provider`, `mail-provider`); `storage/media` consumes the storage provider through a Port (`domain/gateways/storage-gateway.interface.ts`).

Reuse rules, no exceptions:

- **Never recreate transformation logic that already exists somewhere global.** Before writing any new `@Transform`, check `src/http/helpers/` (generic, any module — e.g. `escapeLike`, or a `parseMoneyAmount` that turns `"1.234,56"` into the integer `123456`) and `src/infrastructure/providers/<provider>/helpers/` (provider-specific, any module of that provider) and reuse if it exists. Helper names follow the semantic naming of `backend-schema` 2.1.4/2.1.5: never a `cents`/`scaled` prefix or suffix.
- **A helper only exists at the global infrastructure level**, never inside a module (`src/modules/...`). If the transformation is specific to ONE field of ONE entity and doesn't repeat anywhere, it stays inline in the `@Transform` itself, without becoming a file. It only becomes a global helper when **more than one place** (different modules, or more than one field of the same module) needs the same logic — in that case it moves up to `src/http/helpers/` (if generic) or `src/infrastructure/providers/<provider>/helpers/` (if provider-specific), never local to the module.
- **Never import something from inside another module**, and never inject another module's `Repository`/`Service` directly, even if it's in its `exports`. Cross-module is always via `QueryBus`/`CommandBus`.

## Templates: raw dto, domain dto mapping, global helper, service, webhook, provider setup

Comments inside the templates are explanations for the reader; the real files never contain comments (global rule). A provider-unavailable error uses the module's own translated code, as the existing `ITEMS_PROVIDER_UNAVAILABLE` and `ADDRESS_GEO_PROVIDER_UNAVAILABLE` do. `UnauthorizedException` without a message is fine for webhooks: `UnauthorizedExceptionFilter` answers with the translated generic message.

### Domain DTO (`@Transform` mapping)

Each field has a `@Transform(({ obj }) => ...)` that reads from the **raw** dto (`obj` typed as `{Provider}{Entity}Dto`) and returns the value already in domain format. A trivial field (same name, no transformation) doesn't need `@Transform`, just `@Expose`. Reuse a global helper (e.g. `parseMoneyAmount`) inside the `@Transform` instead of rewriting the logic — see the "Raw → domain mapping" section above.

```ts
import { {someGlobalHelperIfNeeded} } from '@/infrastructure/providers/{provider}/helpers/{helper}.helper'; // only if needed

import { {Provider}{Entity}Dto } from '../infrastructure/{provider}/dtos/{provider}-{entity}.dto';
import { Expose, Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class {Entity}Dto {
  @Transform(({ obj }: { obj: {Provider}{Entity}Dto }) => String(obj.id))
  @ApiProperty()
  @Expose()
  id: string;

  // field with no transformation, just a direct rename/pick:
  @ApiProperty()
  @Expose()
  someEqualField: string;

  // ...remaining fields, each with @Transform when it needs to compute/convert
}
```

The service uses this dto with `plainToInstance` (see "Integration service" section) — there's no separate `map...` function.

### Provider raw DTO

No decorators — it's just the shape the external API returns, typed.

```ts
export class {Provider}{Entity}Dto {
  id: number;
  // ...fields exactly as the provider returns them, original names (snake_case if that's the case)
}
```

### Global helper (only if the logic repeats in more than one place)

**Don't create `infrastructure/{provider}/helpers/` inside the module.** If, while writing the DTO's `@Transform`, you notice the same logic is already (or will be) used in another field/module, extract it into a **global** helper, outside `src/modules/`:

- Provider-specific logic (e.g. picking localized text, building `{id, name}` from a shape with a localized name) → `src/infrastructure/providers/{provider}/helpers/{name}.helper.ts`.
- Generic project logic, unrelated to the provider (e.g. converting a price string to cents) → `src/http/helpers/{name}.helper.ts`.

```ts
// src/infrastructure/providers/{provider}/helpers/{name}.helper.ts (example)
export function {functionName}(input: InputType): OutputType {
  // pure function, no I/O, no @Injectable
}
```

Before writing one, check `src/http/helpers/` and `src/infrastructure/providers/<provider>/helpers/` for something equivalent — reuse instead of duplicating.

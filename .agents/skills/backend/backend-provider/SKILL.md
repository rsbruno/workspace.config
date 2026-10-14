---
name: backend-provider
description: External provider integration rules — plainToInstance + @Transform mapping, one service per use case, global client, webhook handler.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-provider

Rules for integrating a third-party API/SDK inside a module's `infrastructure/<provider>/` folder.

## Core rules

- Raw→domain mapping is `@Transform` on the domain DTO fields plus `plainToInstance(Dto, raw, { excludeExtraneousValues: true })`. No hand-written `map...` function, no `helpers/` folder inside a module.
- Check global helpers before writing a `@Transform`. A helper exists only globally (`src/http/helpers/` generic, `src/infrastructure/providers/<provider>/helpers/` provider-specific), and only once 2+ places need it.
- Provider raw DTO has no decorators; keeps original names and the provider's own `status`.
- One service file = one use case. Never one class with several public methods. Port adapters are the exception (see `backend-cqrs`).
- Provider errors become `BusinessException` with a translated code. Raw provider message never reaches the client.
- Money and fractions are converted once, in the `@Transform`, to integer cents / integer scale.
- Webhooks: `@Public() @HttpCode(200)`; handler checks ±5 min freshness, HMAC with `timingSafeEqual`, re-confirms state via provider GET (never trust body status), is idempotent, returns 200 for unknown events.
- First use of a provider: create the global client (`{provider}.provider.ts`, `@Global()` module, env registered, imported in app module).
- Calls on behalf of an organization carry its `organizationId`; cache keys and paths are scoped by it.
- Tests mock only the provider service or Port token; everything else runs for real.

## References

| Read when | File |
|---|---|
| Writing DTOs, `@Transform`, deciding on a helper | [references/mapping-and-dtos.md](references/mapping-and-dtos.md) |
| Writing the integration service | [references/integration-service.md](references/integration-service.md) |
| Writing a webhook endpoint/handler | [references/webhook.md](references/webhook.md) |
| First integration of a provider, scope/translation/money/test boundaries | [references/client-and-boundaries.md](references/client-and-boundaries.md) |

Related: `backend-cqrs` (Ports), `backend-locale`, `backend-schema`, `backend-test`.

# Global provider client and provider boundaries

## Global provider client (if it doesn't exist yet)

If the module is the first to integrate this provider, create beforehand (outside the module, in `src/infrastructure/providers/{provider}/`):
- `{provider}.provider.ts` — client factory (axios/SDK), injection token, validates env vars and throws `InternalServerErrorException` if config is missing. See `src/infrastructure/providers/auth-provider/auth-provider.provider.ts`.
- `{provider}.module.ts` — `@Global()`, exports the token.
- Register the env vars in `src/configs/environment/index.ts` (namespace `{provider}: {...}`) and in `.env.example`/`.env`.
- Register the global module in `src/app.module.ts` (`imports`).

## Provider boundaries: scope, translation, money and tests

- A provider call made on behalf of an organization receives the session `organizationId` from the command/query and never mixes data of different organizations (cache keys, storage paths and external ids are prefixed or filtered by organization).
- Provider errors are mapped at the boundary to a `BusinessException` with a translated code (`backend-locale`); the raw provider message, status or payload never reaches the client.
- Monetary and fractional values coming from a provider are converted **once**, in the raw→domain `@Transform`, to integer cents / the field's integer scale (`backend-schema` 2.1.4/2.1.5). From there on, the module only handles integers.
- Tests (`backend-test`): the provider service is the only thing mocked (jest mock of the service or the Port token). Handlers, repositories, guards and translations run for real in integration/E2E. Raw→domain mapping has unit tests with real provider payload samples, including missing/null fields and decimal amounts.

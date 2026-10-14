# English properties, BusinessException, code registration

## 3.0 Property language — English-only, no exception (fixed project rule)

**All domain DTO properties (response and payload) are always in English.** This applies even when the data comes from a Portuguese external API (a public geo API, a postal API, etc.) or when the field is a Brazilian technical term (CEP, UF, CPF, CNPJ).

Map it in the service, before returning:

```ts
// a public geo API returns { sigla, nome } → map to
{ abbreviation: raw.sigla, name: raw.nome }

// a public geo API returns { cep } → map to
{ postalCode: data.cep }

// a public geo API returns { codigo_ibge } → map to
{ ibgeCode: raw.codigo_ibge }
```

The only exception is **warning/error messages returned to the frontend** (text strings visible to the user) — these must be in Portuguese, but **always via i18n** (translation files under `src/configs/translate/pt-BR/`: `exceptions.json` for business/infrastructure errors, `schemas.json` for validation messages), never hardcoded in Portuguese in the code. Hardcoded strings in any language are forbidden for user-facing messages.

### Every thrown error uses `BusinessException` — never Nest's native `NotFoundException`/`BadRequestException`/`ConflictException`/`ForbiddenException` (fixed project rule)

Native `@nestjs/common` exceptions passed with a loose string (`throw new NotFoundException('order.not_found')`) **don't pass through any global filter** — they fall into Nest's default handler, with no translation, none of the API's standard `{ errors, status }` shape. Only `BusinessException` is intercepted (`business-exception.filter.ts`) and returns a real `{ message: <translated>, code: <code> }`.

Whenever a handler/service needs to reject/abort with an error to the client, use:

```ts
import { BusinessException } from '@/domain/exceptions/infrastructure/business-client-exception.exception';
import { CodeExceptions } from '@/domain/enums/code-exceptions.enum';
import { HttpStatus } from '@nestjs/common';

// default status is BAD_REQUEST — only pass the 2nd argument when it's something else (NOT_FOUND, CONFLICT, FORBIDDEN...)
throw new BusinessException(CodeExceptions.ORDER_NOT_FOUND, HttpStatus.NOT_FOUND);
throw new BusinessException(CodeExceptions.ORDER_ITEMS_REQUIRED); // implicit 400
```

**Before throwing any error, check `src/domain/exceptions/`** — a ready-made exception class for the scenario may already exist (`BusinessException`, the validation and AWS exceptions). Reuse what already exists. Adding a new **code** to `CodeExceptions` for a business error of the module is routine (steps below); creating a new exception **class** or a new global filter is not — stop and confirm with the user first.

**Steps for every new error in a module:**
1. Add an entry to `src/domain/enums/code-exceptions.enum.ts`, using the 3-letter domain prefix + module + a sequential 4-digit number, following the existing pattern (`aut:login:0001` for auth/login, `cat:items:0001` for catalog/items) — e.g. `ORDER_NOT_FOUND = 'com:orders:0001'` for commerce/orders. Never reuse another domain's prefix.
2. Add the corresponding translation to `src/configs/translate/pt-BR/exceptions.json`, inside the `"business"` object, using the SAME string from the enum as the key (e.g. `"com:orders:0001": "Pedido não encontrado."`). Without this entry, the filter returns `message: undefined`.

```ts
// WRONG — doesn't pass through any filter, raw message, no translation
throw new NotFoundException('order.not_found');

// CORRECT
throw new BusinessException(CodeExceptions.ORDER_NOT_FOUND, HttpStatus.NOT_FOUND);
```

When creating a new module, add all of that module's error keys to `code-exceptions.enum.ts` + `exceptions.json` together with the module's files — never leave it for later.

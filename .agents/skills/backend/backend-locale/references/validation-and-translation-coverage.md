# Enum validation, constraint errors, translation coverage

## Numeric enum validation

Business fields persisted as integer enums use the generic DTO validation pattern `@IsEnum(Enum)` with the shared enum-invalid translation. Do not create field-specific numeric hacks or invent a separate exception for every enum field. The validation filter translates the generic failure into the project's standard 400-series validation response; the response never exposes database, PostgreSQL, or implementation details.

The standard lifecycle uses this for account type, expense type and group level. The same pattern applies to every future integer business enum, with the enum registered in Swagger as required by `backend-schema`.

## Database constraint errors

Unique and other expected constraint failures are translated by the global infrastructure filter. The filter identifies the constraint when possible and returns the most specific Portuguese message; otherwise it returns the generic integrity message and a generic public code. No database exception name or constraint implementation detail may be exposed, and repositories do not duplicate this translation with local `try/catch` blocks.

## Every message that reaches the client is translated (fixed project rule, tested)

No response may carry an empty, `undefined`, raw-key or English message. This covers:
- business errors (`BusinessException`);
- validation errors (the `CustomValidationPipe` → `schemas.<message>`);
- whitelist errors;
- guard errors (401/403);
- database constraint errors (global filter).

- **Every class-validator decorator** on payload **and** query DTOs carries `{ message: '<key>' }`, and `<key>` exists in `schemas.json`. A decorator without `message` produces class-validator's English default (`pageSize must be an integer number`), which then resolves to an undefined translation. Use the generic keys (`required`, `invalid`, `strings.maxLength`, `numbers.min`, `numbers.max`, `email.invalid`, ...). Create a new generic key only when none fits; never a per-entity key such as `code.max_length` (such keys do not exist and return no message).
- **Every `CodeExceptions` value** has its entry in `exceptions.json` → `business`, written in the same change that creates the code.
- **Native Nest/HTTP exceptions** that escape every specific filter (rate limit `429`, unknown route `404`, payload too large `413`, malformed JSON `400`, provider misconfiguration `500`) are answered by `UnhandledExceptionFilter` with a status-based code (`sys:http:000N`, `REQUEST_DATA_INVALID`, `INTERNAL_SERVER_ERROR`) and a translated `exceptions.infrastructure.*` message. The raw exception text never reaches the client. This is a safety net, not a pattern: application code still throws `BusinessException`.
- **Every expected unique constraint** that the user can hit is mapped in `src/http/filters/infrastructure/unique-violation-exception.filter.ts` (`UNIQUE_CONSTRAINT_MESSAGES`) to the module's specific code; otherwise the user gets only the generic integrity message.
- **Tests (`backend-test`):**
  - the DTO spec asserts `untranslatedValidationMessagesOf(dto)` is `[]` for every DTO, and `untranslatedExceptionCodes(<module codes>)` is `[]`;
  - the E2E runs with the real i18n and calls `expectTranslatedErrors(body)` on every error response;
  - at least one E2E assertion checks the exact Portuguese text of a module message.

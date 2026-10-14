---
name: backend-locale
description: i18n rules — English DTO properties, Portuguese user-facing messages via translation files and BusinessException only.
disable-model-invocation: true
license: Complete terms in LICENSE.txt
metadata:
  version: "1.0.0"
---

# backend-locale

Language rules: code is English, anything the user reads is translated, nothing hardcoded.

## Core rules

- All DTO properties (response and payload) are English, even when the external API is Portuguese. Map in the service (`sigla` → `abbreviation`).
- User-facing text lives only in translation files (`exceptions.json` for errors, `schemas.json` for validation). Never hardcoded strings.
- Throw only `BusinessException(CodeExceptions.X, HttpStatus.Y)` (default 400). Never native Nest exceptions with a raw string.
- Check `src/domain/exceptions/` before throwing; reuse. New exception classes or global filters need user confirmation; new codes are routine.
- New error = enum entry (`<3-letter-domain>:<module>:<4 digits>`, never another domain's prefix) + same-key entry in `exceptions.json` → `business`. Do it with the module's files.
- Every class-validator decorator carries `{ message: '<key>' }` with a key present in `schemas.json`. Prefer generic keys; no per-entity keys.
- Integer business enums validate with `@IsEnum` and the shared enum-invalid message.
- Unique constraints the user can hit are mapped in the unique-violation filter to a module code. No database names in responses.
- No response may carry an empty, undefined, raw-key or English message. Tests assert it (`untranslated*` helpers, `expectTranslatedErrors`).

## References

| Read when | File |
|---|---|
| Naming properties, throwing errors, registering codes | [references/property-language-and-exceptions.md](references/property-language-and-exceptions.md) |
| Validation messages, DB constraint errors, translation test coverage | [references/validation-and-translation-coverage.md](references/validation-and-translation-coverage.md) |

Related: `backend-test`, `backend-provider`, `backend-schema`.

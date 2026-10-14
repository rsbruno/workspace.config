# Money in cents, integer-scaled values, dates

## 2.1.4 Monetary values are integer cents (fixed project rule)

Every monetary column stores an integer number of **cents**. The backend always works in cents:
- payload DTOs receive cents;
- handlers compute in cents;
- response DTOs return cents;
- the database stores cents.

Conversion to the human currency format (`1,234.56`) happens only in the frontend.

- **Column type:** `integer`, or `bigint('col', { mode: 'number' })` when the range can exceed 2,147,483,647 cents. Never `numeric`, `decimal`, `real`, `double precision`, or a JavaScript float.
- **Name:** the semantic name (`amount`, `value`, `totalValue`, `paidValue`). **Never** a `cents`/`Cents`/`inCents`/`_cents` prefix or suffix, whether in the column, the DTO, the command, a variable or a migration.
- **Payload:** `@IsInt({ message: 'invalid' })` + `@Min`/`@Max` in cents. Swagger `type: 'integer'` with `minimum`/`maximum` in cents.
- **Arithmetic:** in cents only. Splits (installments, allocations) distribute the remainder explicitly (for example, the remainder goes to the first installment). Never divide and round a float.

This applies to plans, transactions, documents, settlements, installments, allocations and every future financial entity.

## 2.1.5 Other fractional values are integer-scaled (fixed project rule)

Decimals are used as little as possible. Quantities, percentages, rates, areas, weights and any value with fixed decimal places follow the same strategy as money: an integer in the smallest unit of the field's scale.

- **Scale:** decided per field from the business requirement. Examples: a unit quantity with 3 decimal places is stored in thousandths (`60000` = `60,000`); a percentage with 4 decimal places is stored × `10^4`. Record the scale in the module implementation note and in the Swagger `description` of the field.
- **Column type:** `integer`, or `bigint('col', { mode: 'number' })` when `max × 10^scale` exceeds 2,147,483,647. The value must stay ≤ `Number.MAX_SAFE_INTEGER`.
- **Name:** stays semantic (`quantity`, `percentage`), never a `scaled`/`int`/`thousandths` suffix.
- **The same integer travels from the API to the database:**
  - the payload DTO receives the integer (`@IsInt`, with `@Min`/`@Max` already multiplied by the scale);
  - the handler and the repository never multiply or divide;
  - the column stores that integer;
  - the response DTO returns it (`type: 'integer'`).

  Only the frontend converts, for input and display. A multiplication or division by the scale in the backend is a bug.
- **Exception:** `numeric` is acceptable only where exact arithmetic is irrelevant, such as an approximate measurement that is never summed, compared for equality or converted. It must be justified in the implementation note and reported to the developer.
- **Converting an existing `numeric` column:** write a hand-written migration with explicit data conversion, `ALTER COLUMN "col" SET DATA TYPE bigint USING round("col" * 10^scale)::bigint`, and write the rollback in the implementation note. Write the migration by hand with an explicit data conversion.
- **Tests prove it end to end (`backend-test`):**
  - the DTO rejects fractional, string and out-of-range values;
  - the integration test asserts the column type and an exact round trip of the maximum;
  - the E2E asserts the API returns exactly the integer sent and the database holds the same integer.

## 2.1.6 Dates and instants (fixed project rule)

- **Calendar date without time** (due date, start/end date, birth date): `date('col')`, which in Drizzle's default `string` mode reads and writes `'YYYY-MM-DD'`. The value travels as that string from the API to the database. Never convert it to `Date` in the backend, because timezone shifts move it to the previous day. Payload: `@Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'invalid' })` + `@IsDateString({ strict: true }, { message: 'invalid' })`. Swagger: `type: String, format: 'date'`.
- **Instant** (`createdAt`, `archivedAt`, an event timestamp): `timestamp('col')`, written with `new Date()` by the backend (UTC). The response is an ISO string (`format: 'date-time'`). The client never sends lifecycle timestamps.
- **Ranges** (`startDate`/`endDate`, `{field}From`/`{field}To` filters): validate `start <= end` in the DTO or the handler (`BusinessException` with a translated code). The listing uses `gte`/`lte` on the same column type.
- Tests cover an invalid format, an impossible date (`2026-02-30`), an inverted range, and the round trip of the exact string through the database.

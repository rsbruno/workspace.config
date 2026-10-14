# Business enums as integer, Swagger enum registration

## 2.1.3 Every business enum is `integer` in the table, TypeScript `enum` in the code (fixed project rule)

Applies to any business enum — order channel, account type, expense type, and similar categories. The database column is **always `integer`**, never `varchar` carrying the enum string. Soft-delete lifecycle timestamps are not enums. The readable name only exists in `domain/enums/` (TypeScript), never as the persisted value.

```ts
// WRONG — enum as a string in the column
export enum OrderChannel {
  SALE = 'online',
  RENT = 'store',
}
channel: varchar('channel', { length: 10 }).notNull(),

// CORRECT — numeric enum, integer column
export enum OrderChannel {
  ONLINE = 1,
  STORE = 2,
}
channel: integer('channel').notNull(),
```

Why: renaming an enum value (`'online'` → `'web'`) must never become a data migration — with `integer`, the code changes and old data stays valid; with `varchar`, every rename is a mass UPDATE migration. `integer` is also more compact and faster to index/compare than `varchar`.

In practice:
- `@IsEnum(OrderChannel)` on the payload dto still works the same, the client sends the number (or the enum member name, but the value actually transmitted/validated is numeric).
- The response DTO exposes the field as-is (number) — if the frontend needs the readable label, that's resolved on the frontend from the shared enum generated via Orval, not formatted on the backend.
- A new business enum's first value starts at `1`, never `0` — `0` stays reserved as "not set/unknown" when it makes sense, avoiding ambiguity with a forgotten column's `default(0)`.

### Every numeric enum exposed via Swagger (`enum` on an `@ApiProperty`/`@ApiQuery`) must be registered in `swagger.config.ts` (fixed project rule, no exception)

`@nestjs/swagger` never emits the enum members' *names* in the OpenAPI schema on its own — only the numeric `enum: [...]` values array. Without the names, Orval (frontend's client generator, the web app) can't name the generated TS enum members either, and falls back to generic `NUMBER_1`/`NUMBER_2`/... — failure seen in practice (for example `SiteStatus`, `TenureType`: changes merged with `@ApiProperty({ enumName, enum })`/`@ApiQuery({ enumName, enum })` correctly set, but nobody registered the enum in the one place that actually injects the names — the whole frontend ended up consuming `SiteStatus.NUMBER_1` instead of `SiteStatus.ACTIVE`).

The fix lives in **`src/configs/swagger/swagger.config.ts`** — a manual post-processing step (`applyEnumVarNames`) that injects the OpenAPI extension `x-enum-varnames` (which Orval already knows how to read) into the generated Swagger document, sourced from each enum's own TypeScript key names:

```ts
// src/configs/swagger/swagger.config.ts
import { SiteStatus } from '@/modules/v1/agribusiness/sites/domain/enums/site-status.enum';
// ...import every other numeric enum used in enumName/enum on a DTO or @ApiQuery...

const numericEnumSchemas: Record<string, object> = {
  // ...existing entries...
  SiteStatus,
};
```

**Whenever a new numeric enum is used with `enumName: 'X'`/`enum: X` on any `@ApiProperty` (response DTO field) or `@ApiQuery` (controller query param) — anywhere in the module being written — add that enum to `numericEnumSchemas` in the same change, never as an afterthought.** This includes every business-state enum (`backend-schema` 2.1/2.1.3) and every listing filter enum (`backend-filter`). Skipping this step doesn't break the backend or its tests — the API still works, Swagger still renders — it only silently degrades the frontend's generated client to unreadable member names, which is exactly why it's easy to miss and exactly why it's a fixed rule here, not a "nice to have."

Checklist before considering a module with a numeric enum done: grep the new/changed DTOs and controllers for `enumName:`, cross-check every distinct enum name found against `swaggerConfig`'s `numericEnumSchemas` map, add whatever is missing.

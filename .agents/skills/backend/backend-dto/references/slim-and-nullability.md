# Slim responses, nullability, integer typing

## 2.4 Response DTOs return only what the frontend uses (fixed project rule)

Before adding a field to the domain DTO, ask: **will the frontend use this?** If not, don't include it.

Fields that must **never** appear in a response DTO:
- `organizationId` — the scope is always the session organization; exposing it only leaks tenancy internals
- `userId` — the frontend doesn't need to know who the owner is; the owner is the logged-in user
- `createdAt` / `updatedAt` — only include if the UI displays or sorts by date
- internal pivot/relation IDs (e.g. `addressId` on an order line when the order already embeds `address`)

For entities following the standard lifecycle, `archivedAt` is included as `@ApiProperty({ type: String, format: 'date-time', nullable: true })` when the frontend needs the archive state. `deletedAt` is never included: a deleted record is not returned by any endpoint.

The reference DTO shape is field-by-field and follows the contracts already established by `accounts` and `account-groups`: nested group/subgroup data uses its own typed DTO with `@Type`, numeric business enums expose `enum` and `enumName`, and nullable values are represented with `nullable: true`, never by optional response properties. A next-code response is a dedicated DTO with only `{ code: string }`.

The domain DTO is the **contract with the frontend** — the smaller it is, the easier to maintain and the more secure (less data leakage). If the frontend needs a field later, add it; never "leave it in just in case."

```ts
// WRONG — exposes data the frontend doesn't use
export class AddressDto {
  @ApiProperty({ type: String }) @Expose() id: string;
  @ApiProperty({ type: String }) @Expose() userId: string;   // ← unnecessary
  @ApiProperty({ type: String }) @Expose() street: string;
  @ApiProperty({ type: String }) @Expose() createdAt: string; // ← unnecessary
}

// CORRECT — only what the UI consumes
export class AddressDto {
  @ApiProperty({ type: String }) @Expose() id: string;
  @ApiProperty({ type: String }) @Expose() street: string;
  @ApiProperty({ type: Boolean }) @Expose() isDefault: boolean;
}
```

## 2.5 Nullability follows the query, numbers follow their storage (fixed project rule)

- **Nested relation from an `innerJoin`** is never `nullable`: the join guarantees it. `nullable: true` on a nested DTO is only for a `leftJoin`/optional FK that really returns `null`. A wrong `nullable` forces needless `?.` and fallbacks in the frontend and hides real bugs.
- **Money (cents) and integer-scaled values** (`backend-schema` 2.1.4/2.1.5) are `@ApiProperty({ type: 'integer', description: '<scale>' })`, never `type: Number`. Orval then generates `number` with the integer constraint visible, and the description states the scale (`'Quantidade em milésimos: 60000 = 60,000'`, `'Valor em centavos'`). The response returns the stored integer unchanged.
- The response DTO, the payload DTOs and the OpenAPI document are pinned by the `openapi contract` block of the module E2E (`backend-test` 6): types, `nullable`, `required`, `maxLength`, `minimum`/`maximum`, `integer`, nested `$ref`. A DTO change without updating that block is incomplete. Every contract change is listed as frontend impact in the task report.

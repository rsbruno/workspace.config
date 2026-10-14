# Swagger typing on response DTOs (Orval contract)

## 2.3 Swagger on response DTOs — faithful to the real return (fixed project rule)

The project uses **Orval** to generate the frontend's TypeScript types from OpenAPI. That's why Swagger **is not optional documentation** — it's a typing contract. Every response DTO (`dtos/<entity>.dto.ts`) must reflect exactly what the backend returns.

### Mandatory rules

**Always specify `type` explicitly** on every `@ApiProperty` — never use `@ApiProperty()` with no arguments, since Swagger can infer it wrong:

```ts
@ApiProperty({ type: String })   // string
@ApiProperty({ type: Number })   // number
@ApiProperty({ type: Boolean })  // boolean
@ApiProperty({ type: String, format: 'date-time' })  // Date serialized as an ISO string
```

**Field always present but that can be `null`** → `@ApiProperty({ type: String, nullable: true })`:

```ts
// WRONG — Orval generates field?: string (absent field), but the backend always returns null
@ApiPropertyOptional()
@Expose()
complement: string | null;

// CORRECT — Orval generates field: string | null
@ApiProperty({ type: String, nullable: true })
@Expose()
complement: string | null;
```

**Field that may be absent from the response** (rare — prefer always returning `null`) → `@ApiPropertyOptional({ type: String })`.

**Array-of-objects field** → use `{ type: () => [EntityDto] }`:

```ts
@ApiProperty({ type: () => [ItemDto] })
@Expose()
items: ItemDto[];
```

### Critical distinction for Orval

| Situation | Correct decorator | Orval generates |
|---|---|---|
| Always present, never null | `@ApiProperty({ type: String })` | `field: string` |
| Always present, can be null | `@ApiProperty({ type: String, nullable: true })` | `field: string \| null` |
| May be absent from the response | `@ApiPropertyOptional({ type: String })` | `field?: string` |
| Absent AND can be null | `@ApiPropertyOptional({ type: String, nullable: true })` | `field?: string \| null` |

`@ApiPropertyOptional` is reserved for **input payload** fields (body, query params) that the client can omit. In a response DTO, always prefer `nullable: true` when the value can be null — the backend controls the shape, it never silently omits a field from the response.

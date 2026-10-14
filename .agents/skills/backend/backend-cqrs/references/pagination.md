# Real pagination at the source

## 3.3 A paginable `findAll` never paginates in memory (fixed project rule)

Whenever a `findAll` can be paginated, pagination is **always real at the source**, never "fetch everything and slice in memory (`.slice()`)" — neither for the database nor for an external provider.

- **Our own data, from the database (Drizzle)**: always paginate. Use `LIMIT`/`OFFSET` (`.limit(pageSize).offset((pageNumber - 1) * pageSize)`) directly in the repository query, plus a separate `count()` (`select({ count: count() })`, same joins and `where`) for `total`. Never `select().from(table)` with no `limit` followed by a JS slice.
- **External provider**: before implementing, confirm in the provider's official docs whether it supports real pagination (`page`/`per_page`, cursor, etc). If it does, pass the received pagination params straight through to the call and return the page the provider already returned — don't fetch the whole dataset to paginate afterward in memory. If the provider does **not** support native pagination (or its pagination isn't compatible with the filter the module needs, e.g. a free-text search the provider can't do), paginating in memory is the exception: document the reason in the module's module implementation note (never as a code comment — global rule) and report it to the developer.

The paginated listing response is always `PaginationResultDto<{Entity}Dto>` (`src/configs/swagger/pagination.dto.ts`, `{ items, total }`), documented with `@SwaggerPaginated({ responseModel: {Entity}Dto })` + `@SwaggerPaginationQuery()` on the controller. Never create a per-module `Paginated{Entities}Dto` and never use `page`/`perPage` (the `<domain>/transactions` and `<domain>/settlements` listings still do and must be migrated during their refactor).

`findall.dto.ts` (query params) always declares `pageNumber`/`pageSize` with these decorators, plus the module filters (`backend-filter`):

```ts
@ApiPropertyOptional({ default: Pagination.PageNumber, minimum: 1, type: Number })
@IsInt({ message: 'invalid' })
@IsOptional()
@Min(1, { message: 'numbers.min' })
@Type(() => Number)
pageNumber: number = Pagination.PageNumber;

@ApiPropertyOptional({ default: Pagination.PageSize, maximum: Pagination.MaxPageSize, minimum: 1, type: Number })
@Max(Pagination.MaxPageSize, { message: 'numbers.max' })
@IsInt({ message: 'invalid' })
@IsOptional()
@Min(1, { message: 'numbers.min' })
@Type(() => Number)
pageSize: number = Pagination.PageSize;
```

The handler computes `limit = pageSize` and `offset = (pageNumber - 1) * pageSize`, calls the repository with `organizationId`, `limit`, `offset` and a filters object, maps each row with `plainToInstance({Entity}Dto, row, { excludeExtraneousValues: true })` and returns `new PaginationResultDto(items, total)`.

The actual repository code (parallel `Promise.all` for the page + `count()`, indexing, `OFFSET` cost, keyset pagination exception) lives in `backend-sql` — load it together with this rule whenever a repository is involved. The response carries only `items` and `total`; the frontend derives the page count.

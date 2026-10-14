# DTO, repository, controller and indexing

## 3. Where it's written

Everything from step 1 stays inside the query's own files — a filter is part of one `findAll` use case, not a shared/global concept:

`application/queries/findall/findall.dto.ts` (query params, appended to the pagination params of `backend-cqrs` 3.3):
```ts
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class FindAll{Entities}QueryDto {
  @Transform(({ value }: { value: unknown }) => (value === 'true' ? true : value === 'false' ? false : value))
  @ApiPropertyOptional({ type: Boolean })
  @IsBoolean({ message: 'invalid' })
  @IsOptional()
  archived?: boolean;

  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() || undefined : value))
  @MaxLength(128, { message: 'strings.maxLength' })
  @ApiPropertyOptional({ type: String })
  @IsString({ message: 'invalid' })
  @IsOptional()
  categoryId?: string;

  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() || undefined : value))
  @MaxLength(100, { message: 'strings.maxLength' })
  @ApiPropertyOptional({ type: String })
  @IsString({ message: 'invalid' })
  @IsOptional()
  search?: string;
}
```

Fixed rules for every filter param:
- Strings are trimmed and a blank value becomes `undefined` (no filter), never a filter by `''`.
- Every string param has `@MaxLength` (ids `128`, free text `100`), every validator carries a translated `message` (`backend-locale`).
- `organizationId` is **never** a filter: the scope comes from the session (`backend-cqrs` 2.2.1). The whitelist rejects it if the client sends it.
- Free-text search is escaped with `escapeLike` in the repository (`backend-sql` 10).
- Every filter is covered by tests (`backend-test`): DTO conversion/rejection, repository SQL and parameters, integration with real rows, E2E through the query string.

`{module}-query.repository.ts` — every filter combines with `and()`, each condition only added when the param was actually sent (`undefined` means "don't filter by this"), same pattern already used for pagination (`backend-cqrs` 3.3):

```ts
async findAll(
  organizationId: string,
  limit: number,
  offset: number,
  filters: { archived?: boolean; name?: string; categoryId?: string; createdAtFrom?: Date; createdAtTo?: Date },
): Promise<[EntityType[], number]> {
  const where = and(
    eq(table.organizationId, organizationId),
    isNull(table.deletedAt),
    filters.archived === true ? isNotNull(table.archivedAt) : filters.archived === false ? isNull(table.archivedAt) : undefined,
    filters.name ? ilike(table.name, `%${escapeLike(filters.name)}%`) : undefined,
    filters.categoryId ? eq(table.categoryId, filters.categoryId) : undefined,
    filters.createdAtFrom ? gte(table.createdAt, filters.createdAtFrom) : undefined,
    filters.createdAtTo ? lte(table.createdAt, filters.createdAtTo) : undefined,
  );

  const [data, [totalResult]] = await Promise.all([
    this.db.select().from(table).where(where).orderBy(asc(table.name), asc(table.id)).limit(limit).offset(offset),
    this.db.select({ count: count() }).from(table).where(where),
  ]);

  return [data, Number(totalResult.count)];
}
```

The controller passes each `@Query()` param straight into the `Query` class constructor (or a grouped `filters` object if there are more than two or three) — no transformation logic in the controller itself, that stays in the repository's `where` building.

## 4. Indexing

Every column used in a filter's `where` needs a database index if the table's expected volume isn't trivial — same rule as `backend-cqrs` 3.3 for `orderBy`/pagination columns. When adding a new filter to an existing column that has no index yet, create the index migration together with the filter, don't leave it for later.

Canonical decisions: accounts expose only `archived`; account groups expose `archived`, `search` over `name` and `code`, and `parentId` through separate group/subgroup listing use cases. `deletedAt` is always implicit and never user-selectable. Business uniqueness such as account code is a database constraint, not a findAll filter or a command precheck.

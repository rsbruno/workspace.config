# Column sizing and slug

## 3.4 Database column: a deliberate size + `class-validator` mirroring the limit, exposed on Swagger (fixed project rule)

Every new `varchar` column has a `{ length: N }` **thought out for the real field**, never an arbitrary number copied from another column. Two field names are standardized project-wide — never pick a different size for these two, on any entity:

| Field | Max length |
|---|---|
| `name` (or any entity's primary display name field) | **100** |
| `description` | **200** |

For any other field (slug, email, code, etc), think it through case by case: what's the largest plausible real-world value? (slug: name + room for a uniqueness suffix, ~160; email: 254, the RFC ceiling; etc). An unbounded column (`text`) only when the field is genuinely free-length (long body/message, not a short `description`) — never out of laziness about the limit.

The payload DTO (`class-validator`) **always mirrors that limit** with `@MaxLength(N)`, using the same `N` as the column — never let the database be the only defense (otherwise the error only shows up as a 500/Postgres constraint violation, not a validated 400).

**The limit is also always exposed on Swagger** — `@ApiProperty`/`@ApiPropertyOptional` carries `maxLength: N` (same `N`), so the constraint shows up in the generated docs/client, not just in server-side validation:

```ts
// schema
name: varchar('name', { length: 100 }).notNull(),
description: varchar('description', { length: 200 }),

// payload dto
@ApiProperty({ maxLength: 100 })
@MaxLength(100, { message: 'strings.maxLength' })
@IsNotEmpty({ message: 'required' })
@IsString({ message: 'invalid' })
name: string;

@ApiPropertyOptional({ maxLength: 200 })
@MaxLength(200, { message: 'strings.maxLength' })
@IsOptional()
@IsString({ message: 'invalid' })
description?: string;
```

## 3.5 `slug` column (fixed project rule when the entity has a slug)

When the entity needs a slug (URL-friendly identifier), the column is always `varchar` with `.unique()`, and the value is **always generated on the backend from `name`**, never received from the client in the payload — use the global helper `src/http/helpers/slugify.helper.ts` (`slugify(value): string`, ascii kebab-case without accents; create it there if it doesn't exist yet, next to `createCUID.helper.ts` and `escape-like.helper.ts`, never locally in the module).

- Generation happens **only on `create`**. Editing `name` afterwards (`update`) does **not** regenerate the slug — a slug that changes breaks an already-published/indexed link.
- Uniqueness is resolved in the `CommandRepository`, checking for collisions against the table itself and resolving with an incremental suffix (`-2`, `-3`, ...) until a free one is found — never let the database constraint blow up as a 500 error to the user.

```ts
// {module}-command.repository.ts
import { slugify } from '@/http/helpers/slugify.helper';

private async generateUniqueSlug(name: string): Promise<string> {
  const base = slugify(name);
  let slug = base;
  let suffix = 2;

  while (await this.slugExists(slug)) {
    slug = `${base}-${suffix}`;
    suffix += 1;
  }

  return slug;
}

private async slugExists(slug: string): Promise<boolean> {
  const [existing] = await this.db.select({ id: table.id }).from(table).where(eq(table.slug, slug)).limit(1);
  return Boolean(existing);
}
```

If the entity's public response is slim (e.g. only `id`/`name`/`slug`, without `archivedAt`/`createdAt`/`updatedAt`), the domain DTO (`dtos/{entity}.dto.ts`) only exposes (`@Expose()`) the requested fields — the rest still exist on the table/entity, they just don't show up in the response DTO's `@Expose()`. `deletedAt` is never exposed.

# Naming, no spread, HTTP verb, permissions

## 3. Naming (fixed project rule, see reference modules)

Public CQRS classes and DTOs always include the entity name. This prevents collisions in NestJS, TypeScript imports and Orval generation. The operation folder remains short and conventional; the class, handler and DTO are qualified:

| Operation | Query/Command | Handler | Folder |
|---|---|---|---|
| Create | `Create{Entity}Command` | `Create{Entity}Handler` | `application/commands/create/` |
| Update | `Update{Entity}Command` | `Update{Entity}Handler` | `application/commands/update/` |
| Archive | `Archive{Entity}Command` | `Archive{Entity}Handler` | `application/commands/archive/` |
| Delete | `Delete{Entity}Command` | `Delete{Entity}Handler` | `application/commands/delete/` |
| Restore | `Restore{Entity}Command` | `Restore{Entity}Handler` | `application/commands/restore/` |
| Find by id | `Find{Entity}Query` | `Find{Entity}Handler` | `application/queries/find/` |
| Find all | `FindAll{Entities}Query` | `FindAll{Entities}Handler` | `application/queries/findall/` |

Use descriptive names for non-CRUD operations, for example `FindNextAccountCodeQuery`. A listing that varies only by archive state or another value is still one `FindAll{Entities}Query` with filters, never duplicated handlers. `create-group` and `create-subgroup` are valid descriptive commands when the same table has distinct business entry points; the `AccountGroupLevel` determines which hierarchy is listed.

- **Listing** method/query/handler (even without real pagination yet and even when filtered) = `findAll...` (e.g. `FindAllAccountGroupsQuery`, `findAllAccountGroups()`).
- **Lookup by a specific prop** method/query/handler = `find...` (e.g. `FindProductBySlugQuery`, `findBySlug()`).
- Never `findCategories`/`getCategories` — always that prefix.

## 3.1 Backend output is prop by prop — never spread (fixed project rule)

Every object that **crosses the backend's boundary** is built field by field, explicitly — never `{ ...payload }` when writing to the database (that's `backend-sql`'s territory, see its section 5) or sending to an external integration (SDK call, HTTP body/params to a provider — see `backend-provider`). Spread is still allowed **inside** the backend: handler return to the controller, composition between layers, module providers (`[...handlers, ...services]`).

Reason: with spread, what crosses the boundary becomes implicit. A new field on the source type leaks by itself into the database or to the third party without going through review. Prop by prop makes the contract explicit and lets the compiler and the reviewer catch the change.

## 3.2 The HTTP verb decides Query vs Command — not the side effect (fixed project rule)

**CQRS classification follows the endpoint's HTTP verb, not whether the handler changes state or not.**

- `@Get(...)` → always `Query`/`QueryHandler`/`QueryBus`, `queries/` folder.
- `@Post(...)`, `@Put(...)`, `@Patch(...)`, `@Delete(...)` → always `Command`/`CommandHandler`/`CommandBus`, `commands/` folder.

This applies even when the endpoint persists nothing (e.g. a price/shipping calculator that only reads from an external provider and returns a number). If the client sends data in the body (`@Post`/`@Put`/`@Patch`) or requests deletion (`@Delete`), it's a `Command` — the absence of a database mutation doesn't exempt it. Only a pure GET (no body, just query/path params) is a `Query`.

Reason: the HTTP verb is already the API's public contract about the expected effect (idempotency, caching, automatic client retry). Letting the internal classification follow that same contract avoids a situation where an endpoint "looks like a read" from the outside (business semantics) but behaves differently on the inside (e.g. one could use CommandBus, another QueryBus, for the same kind of payload) — the verb already decides, no case-by-case debate.

In practice, this means: any endpoint that needs a body (a payload that doesn't fit in a query string — item list, nested object) is `@Post` + `Command`, even when it's a pure "calculator"/read. For example, a `POST .../calculate-pricing` that computes a price from `{ id, quantity }[]` is a `Command`, not a `Query`, because it's `@Post`.

## 3.2.1 No endpoint without a permission (fixed project rule, no exception)

**Every controller endpoint of a billed feature requires `@Feature` and a matching `@Can` policy.** Creating the endpoint and creating its permission are the same unit of work, not two separate tasks — see `backend-rule` for the policy's fixed shape and the seed mechanics. An endpoint without `@Can` (non-billed surface, or a global catalog such as `GET /v1/catalog/items/base`) is an exception: documented, tested and reported (`backend-rule` gate, section 2.2.1).

Never write the permission's code as a raw string in the guard, decorator or tests — always reference the constant from `src/domain/enums/policy.enum.ts` (e.g. `Policies.Access.Users.Create`), The seed JSON (`drizzle/seeds/policies/data.json`) is the only place that repeats the literal, kept in sync by `catalog-seeds.spec.ts` (`backend-rule`). Add the new nested key to `policy.enum.ts` before/alongside writing the endpoint, matching its module's existing branch (`Policies.{Domain}.{Module}.{Action}`, PascalCase keys, same `{action}` word as the qualified operation name).

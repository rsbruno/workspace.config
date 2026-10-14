# Cross-module and intra-module rules

## 2.5 Cross-module: always via `QueryBus`/`CommandBus`, never direct injection (fixed project rule)

When a module needs something from another module (e.g. `products` needs an organization unit from `catalog/items`, or `payments` needs a customer from `crm/customers`), the call is **always** via `queryBus.execute(new Find...Query(...))` / `commandBus.execute(new ...Command(...))` — never direct injection of the target module's `Repository`/`Service` in the constructor, even if that `Repository`/`Service` is in the target `*.module.ts`'s `exports`.

**Why**: the bus decouples — the consuming module only knows the contract (`Query`/`Command`), never the concrete class nor the target module's internal structure (schema, repository, provider). Direct repo injection creates structural coupling between bounded contexts: any internal refactor of the target module (swap repository, change schema, swap external provider) breaks the consuming module. The bus solves this: the target module can rewrite everything internally as long as the handler keeps responding to the same `Query`/`Command`.

**In practice**:
- If the target module already has the `Query`/`Command` covering the use case, reuse it.
- If not, create a new `queries/find-.../` or `commands/.../` **inside the target module** (never inside the consuming module) — even if it's a thin wrapper over the repository (`execute()` just calling `repository.findX(...)`), it's what becomes the module's public contract for the rest of the system.
- The consuming module's `*.module.ts` **doesn't need** to import (`imports: [...]`) the target module for this to work — `QueryBus`/`CommandBus` resolves the handler globally as long as the target module is registered somewhere in the tree (usually already is, via `app.module.ts` or a parent module). Only import the target module if you really need something it exposes via `exports` (rare, and in that case it's not to inject `Repository`/`Service` cross-module — it's an exceptional case, confirm with the user first).

```ts
// WRONG — products injects the items repository directly
constructor(private readonly itemsRepository: ItemsRepository) {}
const unit = await this.itemsRepository.findById(payload.captureItemId, organizationId);

// CORRECT — products talks to items via the bus, using the Query items exposes (same organization)
constructor(private readonly queryBus: QueryBus) {}
const unit = await this.queryBus.execute<FindItemQuery, ItemDto>(new FindItemQuery(payload.captureItemId, organizationId));
```

Documented exception: if the target module's handler has heavy orchestration (calls an external provider, multiple repositories) and creating a reverse module dependency would cause a circular import (`A` imports `B` and `B` already imports `A`), confirm with the user before deciding — it may be acceptable to keep it bus-only (which already resolves the cycle, since the bus needs no `imports`) instead of restructuring modules.

## 2.5.1 A repository never leaves its module — not even for a global guard, not even for `app.module.ts` (fixed project rule)

Pinned by `src/__tests__/unit/architecture/source.architecture.spec.ts` (`knownCrossModuleImports` ratchet — only shrinks; `.schema.ts` files may import other schemas for FK `references`).

The same applies to the Drizzle **table** objects: a repository only queries the tables of its own module (plus the global schema barrel for its own tables). Joining or selecting another module's table (e.g. `products-query.repository.ts` reading `organizationItemsTable` directly) couples the modules through the schema; the data comes through the owner's `Find...Query` instead. A cross-module join that is genuinely needed for performance in a listing is an explicit exception, reported to the developer and documented in both modules' implementation notes.

Every infrastructure `Repository`/`Service` of a module (`infrastructure/database/...`) is a `provider` of **that** `*.module.ts`, and only that one. Nowhere else in the code — another feature module (that's already rule 2.5, via the bus), but also `app.module.ts`, a global guard, a global interceptor, or anything outside the module — may import the class and declare it loose in its own `providers: [...]`. Whoever needs the repository **imports the module** (`imports: [XModule]`) and consumes it via its `exports` — never re-import the raw class and register it somewhere else.

This applies even when whoever needs the data isn't another feature module, but cross-cutting infrastructure (a guard registered as `APP_GUARD`, an interceptor). Prefer the bus there too: the real `CanGuard` and `FeatureGuard` resolve permissions and features through `ResolveGroupPolicySetsQuery` and `ResolveOrganizationFeaturesQuery`, without touching any repository. If a repository is truly needed, `app.module.ts` imports the owning `*.module.ts` and consumes its `exports`; it never declares the repository class in its own `providers`.

```ts
// WRONG — app.module.ts registers another module's repository directly
import { GroupsRepository } from '@/modules/v1/access/groups/infrastructure/database/drizzle/groups-query.repository';

@Module({
  providers: [
    { useClass: CanGuard, provide: APP_GUARD },
    GroupsRepository,
  ],
})

// CORRECT — the guard asks the owning module through the bus
const groupPolicySets = await this.queryBus.execute<ResolveGroupPolicySetsQuery, Set<string>[]>(
  new ResolveGroupPolicySetsQuery(user.organizationId, user.groupIds),
);
```

Why: a loose repository in `app.module.ts` breaks the module-encapsulation rule (2.5) through the back door — even without being "another feature module," it's still an external consumer seeing the concrete class and the owning module's internal `provide`. If the owning module swaps the repository's implementation, every place that imported it loose has to change along with it; by importing the module, only the owning `*.module.ts` needs to know what changed internally.

## 2.6 Intra-module: each Command owns its rule end to end, never duplicated (fixed project rule)

Within the **same module**, if two or more actions (`Command`s) need the same piece of business rule (e.g. "when the order's items change, invalidate shipping and recalculate status"), that rule becomes **its own `Command`/`Handler`**, and the actions that need it call it via `commandBus.execute(new That...Command(...))` — never each handler reimplementing the same logic block inline.

Rule of thumb: before writing a new handler, ask — "does this piece of logic (validate, change status, trigger a side effect) already exist identically in another handler of the module?" If so, extract it into a new Command instead of copying. If a Command needs another Command to run as part of its own rule (e.g. permanently removing an order item also needs to invalidate order progress), it calls the other one via `commandBus.execute(...)` — each Command owns its slice of the rule end to end, and composes with other Commands of the same module instead of duplicated inline logic.

```ts
// WRONG — AddItemsHandler and UpdateItemQuantityHandler each reimplement the same rule in their own file
if (order.status >= OrderStatus.ADDRESS_SELECTED) {
  await this.commandBus.execute(new RemoveOrderShippingCommand(order.id));
  await this.ordersCommandRepository.updateStatus(order.id, OrderStatus.CART);
}

// CORRECT — rule extracted into commands/invalidate-order-progress/, each handler just delegates
await this.commandBus.execute(new InvalidateOrderProgressCommand(order.id, order.status, remainingItemsCount));
```

The orders example above is illustrative (that module does not exist in this codebase); the rule applies to every module of `src/modules/v1`.

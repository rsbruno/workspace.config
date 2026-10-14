# Controller and module templates

### Controller (`{module}.controller.ts`, module root)

```ts
import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Query } from '@nestjs/common';
import { CommandBus, QueryBus } from '@nestjs/cqrs';

import { Audit } from '@/http/decorators/audit.decorator';
import { Can } from '@/http/decorators/can.decorator';
import { CurrentUser } from '@/http/decorators/current-user.decorator';
import type { CurrentUserContext } from '@/http/decorators/current-user.decorator';
import { Feature } from '@/http/decorators/feature.decorator';
import { SwaggerGet } from '@/http/decorators/swagger-get.decorator';
import { SwaggerPaginated } from '@/http/decorators/swagger-paginated.decorator';
import { SwaggerPaginationQuery } from '@/http/decorators/swagger-pagination-query.decorator';
import { SwaggerPost } from '@/http/decorators/swagger-post.decorator';
import { ParseIdPipe } from '@/http/pipes/parse-id.pipe';
import { Features } from '@/domain/enums/features.enum';
import { Policies } from '@/domain/enums/policy.enum';

@Controller('v1/{domain}/{module}')
export class {Module}Controller {
  constructor(
    private readonly commandBus: CommandBus,
    private readonly queryBus: QueryBus,
  ) {}

  @SwaggerPost({ responseModel: Create{Entity}ResultDto })
  @Can(Policies.{Domain}.{Module}.Create)
  @Feature(Features.{Domain}.{Module})
  @HttpCode(HttpStatus.CREATED)
  @Audit()
  @Post()
  async create{Entity}(@Body() body: Create{Entity}PayloadDto, @CurrentUser() user: CurrentUserContext) {
    return this.commandBus.execute(new Create{Entity}Command(body, user.organizationId));
  }

  @SwaggerPaginated({ responseModel: {Entity}Dto })
  @Can(Policies.{Domain}.{Module}.FindAll)
  @Feature(Features.{Domain}.{Module})
  @SwaggerPaginationQuery()
  @Get()
  async list{Entities}(@CurrentUser() user: CurrentUserContext, @Query() query: FindAll{Entities}QueryDto) {
    return this.queryBus.execute(new FindAll{Entities}Query(user.organizationId, query.pageSize, query.pageNumber, query.archived, query.search));
  }

  @SwaggerGet({ responseModel: {Entity}Dto })
  @Can(Policies.{Domain}.{Module}.Find)
  @Feature(Features.{Domain}.{Module})
  @Get(':id')
  async get{Entity}ById(@Param('id', ParseIdPipe) id: string, @CurrentUser() user: CurrentUserContext) {
    return this.queryBus.execute(new Find{Entity}Query(id, user.organizationId));
  }
}
```

Fixed controller rules (all pinned by `src/__tests__/unit/architecture/controllers.architecture.spec.ts`):
- Every authenticated endpoint has `@Feature` and `@Can` (exceptions: `backend-rule` gate, section 2.2.1).
- Every authenticated write endpoint (`@Post`/`@Put`/`@Patch`/`@Delete`) has `@Audit()` — the audit trail of who changed what is part of the use case, not optional. The only exception today is `OAuthController.signOut`.
- Every id path param (`:id`, `:siteId`, `...Id`) goes through `ParseIdPipe` (`src/http/pipes/parse-id.pipe.ts`: string, 1-128 chars, `[A-Za-z0-9_-]`), which answers `400 sys:validation:0001` translated before any handler runs.
- Method names are globally unique across all controllers: the method name is the OpenAPI `operationId` and the Orval function name (`operationIdFactory` in `swagger.config.ts`); a duplicate gets an unstable numeric suffix. Use entity-qualified names (`listItems`, `getItemById`, `archiveItem`).
- `@HttpCode(HttpStatus.NO_CONTENT)` + `@SwaggerDelete()` on deletes, `@HttpCode(HttpStatus.CREATED)` on creates.
- **Static routes never share a controller with a `:param` route that captures them.** Nest registers routes in method order, and the project lint (`perfectionist/sort-classes`, alphabetical, applied by `--fix` and by the pre-commit) reorders methods. Example: `getItemById` (`:id`) sorts before `listBaseItems` (`base`), so `/items/base` becomes unreachable. A static sibling route lives in its own controller, registered **first** in the module's `controllers` array. Pinned by the `shadowedRoutes()` check of `controllers.architecture.spec.ts`.

Only use `@Public()` above the method when confirmed with the user that the route doesn't require authentication.

### Module (`{module}.module.ts`, module root)

```ts
import { CqrsModule } from '@nestjs/cqrs';
import { Module } from '@nestjs/common';

import { FindAllHandler } from './application/queries/findall/findall.handler';
// ...one import per handler, each its own file
import { {Entities}CommandRepository } from './infrastructure/database/drizzle/{entities}-command.repository';
import { {Entities}QueryRepository } from './infrastructure/database/drizzle/{entities}-query.repository';
import { {Module}Controller } from './{module}.controller';

const handlers = [FindAllHandler /* , ...remaining handlers, one per use case */];
const repositories = [{Entities}CommandRepository, {Entities}QueryRepository];

@Module({
  providers: [...handlers, ...repositories],
  exports: repositories, // only export what another module actually needs to consume
  controllers: [{Module}Controller],
  imports: [CqrsModule],
})
export class {Module}Module {}
```

Every module is standalone — **don't** create an "aggregator" module to group sibling modules (e.g. there's no `shared.module.ts` aggregating `accounts`+`account-groups`). If a module needs another, communication is always via `QueryBus`/`CommandBus` (section 2.5) — **don't** import the sibling module in `imports` nor inject its `Repository`/`Service`, even if exported.

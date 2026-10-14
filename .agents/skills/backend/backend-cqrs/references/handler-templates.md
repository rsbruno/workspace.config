# Query and command templates

## Templates: query, command, controller, module

Comments inside the templates and examples are explanations for the reader; the real files never contain comments (global rule).

Folder root for everything below is `src/modules/v1/<domain>/<module>/`. Use the project's most complete DB-backed module and its provider-behind-a-Port module as live references.

### Query (read) — `application/queries/findall/`

`findall.query.ts`:
```ts
import { Pagination } from '@/domain/enums/pagination.enum';

export class FindAll{Entities}Query {
  constructor(
    public readonly organizationId: string,
    public readonly pageSize: number = Pagination.PageSize,
    public readonly pageNumber: number = Pagination.PageNumber,
    public readonly archived?: boolean,
    public readonly search?: string,
  ) {}
}
```

`findall.handler.ts`:
```ts
import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { plainToInstance } from 'class-transformer';

import { PaginationResultDto } from '@/configs/swagger/pagination.dto';

import { {Entities}Repository } from '../../../infrastructure/database/drizzle/{entities}-query.repository';
import { {Entity}Dto } from '../../../http/dtos/{entity}.dto';
import { FindAll{Entities}Query } from './findall.query';

@QueryHandler(FindAll{Entities}Query)
export class FindAll{Entities}Handler implements IQueryHandler<FindAll{Entities}Query> {
  constructor(private readonly repository: {Entities}Repository) {}

  async execute(query: FindAll{Entities}Query): Promise<PaginationResultDto<{Entity}Dto>> {
    const limit = query.pageSize;
    const offset = (query.pageNumber - 1) * query.pageSize;

    const [rows, total] = await this.repository.findAll(query.organizationId, limit, offset, {
      archived: query.archived,
      search: query.search,
    });

    const items = rows.map((row) => plainToInstance({Entity}Dto, row, { excludeExtraneousValues: true }));

    return new PaginationResultDto<{Entity}Dto>(items, total);
  }
}
```

If the query has params via `@Query()` on the controller, also create `findall.dto.ts` with `class-validator` (`@IsOptional`, `@ApiPropertyOptional`).

A specific-lookup by id follows the same shape under `application/queries/find/` with the `Find` prefix (no `All`). A lookup by a non-id prop, or anything that isn't plain CRUD, gets its own descriptive folder (e.g. `application/queries/find-base/`, `application/queries/findall-base-items/` in `catalog/items`, `application/queries/resolve-organization-features/` in `billing/subscriptions`).

### Command (write) — `application/commands/{verb}/`

Use the operation folder names `create`, `update`, `archive`, `delete` and `restore`; qualify each class with the entity name. Use descriptive verb-noun names for non-CRUD operations such as `next-code`.

`{verb}.command.ts` (simple class; use `extends Command<TResult>` from `@nestjs/cqrs` only when you want a typed return on `CommandBus.execute`):
```ts
export class {Verb}{Entity}Command {
  constructor(public readonly field: string) {}
}
```

`{verb}.dto.ts` (Payload = input validation with `class-validator`, Result = output shape with `class-transformer`; only when the command needs payload validation):
```ts
import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Expose } from 'class-transformer';

export class {Verb}{Entity}PayloadDto {
  @IsNotEmpty({ message: 'required' })
  @IsString({ message: 'invalid' })
  @ApiProperty()
  field: string;
}

export class {Verb}{Entity}ResultDto {
  @Expose()
  @ApiProperty()
  id: string;
}
```

`{verb}.handler.ts`:
```ts
import { ICommandHandler, CommandHandler } from '@nestjs/cqrs';

import { {Entities}CommandRepository } from '../../../infrastructure/database/drizzle/{entities}-command.repository';
import { {Verb}{Entity}Command } from './{verb}.command';

@CommandHandler({Verb}{Entity}Command)
export class {Verb}{Entity}Handler implements ICommandHandler<{Verb}{Entity}Command> {
  constructor(private readonly repository: {Entities}CommandRepository) {}

  async execute(command: {Verb}{Entity}Command) {
    return this.repository.{verb}(command.field);
  }
}
```

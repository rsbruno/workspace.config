# Integration service: one file per use case

### Integration service — one file per use case

**Single responsibility: each service resolves ONE use case.** If the module needs `findAll` and `findBySlug`, that's two files, two classes, each with its own `@Injectable()` — never one class with two public methods. Both call the provider's global client (`@Inject` of the token exported by `src/infrastructure/providers/{provider}/{provider}.provider.ts` — create this global provider first if it doesn't exist yet, following `src/infrastructure/providers/auth-provider/auth-provider.provider.ts` or `storage.provider.ts` as a reference), convert the result with `plainToInstance` (**not** with a manual `map...` function — the mapping already lives in the dto's `@Transform`, see "Domain DTO" section), log the error and throw a `BusinessException` with a translated code (`backend-locale`) — never a native Nest exception with a raw string. Cache via `CACHE_MANAGER` when the data changes rarely.

`infrastructure/{provider}/services/findall-{entities}.service.ts`:
```ts
import type { AxiosInstance } from 'axios'; // or the provider's SDK

import { HttpStatus, Injectable, Inject, Logger } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';

import { BusinessException } from '@/domain/exceptions/infrastructure/business-client-exception.exception';
import { CodeExceptions } from '@/domain/enums/code-exceptions.enum';
import { {PROVIDER}_CLIENT } from '@/infrastructure/providers/{provider}/{provider}.provider';

import { {Provider}{Entity}Dto } from '../dtos/{provider}-{entity}.dto';
import { {Entity}Dto } from '../../../http/dtos/{entity}.dto';

@Injectable()
export class {Provider}FindAll{Entities}Service {
  private readonly logger = new Logger({Provider}FindAll{Entities}Service.name);

  constructor(
    @Inject({PROVIDER}_CLIENT)
    private readonly client: AxiosInstance,
  ) {}

  async findAll(): Promise<{Entity}Dto[]> {
    try {
      const { data } = await this.client.get<{Provider}{Entity}Dto[]>('/{resource}');

      return plainToInstance({Entity}Dto, data, { excludeExtraneousValues: true });
    } catch (error) {
      this.logger.error('Failed to fetch {entities}', error);

      throw new BusinessException(CodeExceptions.{MODULE}_PROVIDER_UNAVAILABLE, HttpStatus.SERVICE_UNAVAILABLE);
    }
  }
}
```

`infrastructure/{provider}/services/find-{entity}-by-{prop}.service.ts` (same shape, different use case, different file):
```ts
@Injectable()
export class {Provider}Find{Entity}By{Prop}Service {
  private readonly logger = new Logger({Provider}Find{Entity}By{Prop}Service.name);

  constructor(
    @Inject({PROVIDER}_CLIENT)
    private readonly client: AxiosInstance,
  ) {}

  async findBy{Prop}({prop}: string): Promise<{Entity}Dto | null> {
    // same try/catch/log logic as the example above; if a record is found, `plainToInstance({Entity}Dto, raw, { excludeExtraneousValues: true })`, otherwise null
  }
}
```

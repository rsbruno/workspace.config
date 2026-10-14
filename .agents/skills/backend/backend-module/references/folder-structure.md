# Module folder structure and responsibilities

## 2. Folder structure (always)

The `#` notes in the tree are explanations; the real files never contain comments (global rule).

```
src/modules/v1/<domain>/<module>/
├── <module>.controller.ts
├── <module>.module.ts
├── application/
│   ├── commands/                         # only if there's writing -- one folder per use case
│   │   └── <verb>/                       # operation (create/update/archive/delete/restore),
│   │       │                              # verb-noun for anything else (next-code, attach-site, grant-user)
│   │       ├── <verb>.command.ts
│   │       ├── <verb>.dto.ts             # only if there's payload validation (class-validator)
│   │       └── <verb>.handler.ts
│   └── queries/                          # only if there's reading -- one folder per use case
│       ├── find/                         # lookup by id
│       │   ├── find.query.ts
│       │   └── find.handler.ts
│       └── findall/                      # canonical listing
│           ├── findall.query.ts
│           └── findall.handler.ts
├── domain/                               # only if there's an entity enum, a Port, and/or a pure helper
│   ├── enums/                            # business enums only; soft delete uses timestamps
│   ├── gateways/                         # Ports -- only when the module must swap provider without callers knowing
│   │   └── <thing>-gateway.interface.ts
│   └── helpers/                          # pure domain functions, zero framework/db dependency
│       └── <name>.helper.ts
├── http/
│   └── dtos/
│       └── <entity>.dto.ts               # response DTO returned by the controller -- NEVER lives inside infrastructure/
└── infrastructure/
    ├── database/drizzle/                 # only if DB-backed
    │   ├── <entities>.schema.ts
    │   ├── <entities>-command.repository.ts  # writes -- separate file from reads
    │   └── <entities>-query.repository.ts    # reads -- separate file from writes
    └── <provider>/                       # only if there's an external provider (auth-provider, s3, ses, geo-provider...)
        └── services/                      # one file per use case, never a service with multiple methods
            └── <name>.service.ts
```

### Responsibility of each folder (Clean Arch / DDD) — never mix content between them

| Folder | Responsibility | Never contains |
|---|---|---|
| `<module>.controller.ts` | Presentation layer (HTTP). Receives the request, validates via DTO, delegates to `QueryBus`/`CommandBus`, returns the response. | mapping logic, direct call to `infrastructure/` |
| `<module>.module.ts` | Composition root: `providers`, `controllers`, `imports`, `exports`. | business logic, imports of another module beyond what it exposes |
| `application/commands/<name>/` | One use case behind `@Post`/`@Put`/`@Patch`/`@Delete`, even without persisting. | reading via `@Get`, raw→domain mapping |
| `application/queries/<name>/` | One use case behind a `@Get`. | writing, direct call to the external client |
| `domain/enums/` | Entity business-state enums, zero framework/db dependency. | anything with a DB/provider import |
| `domain/gateways/` | Port interfaces + injection token (`Symbol`), defined by the use case that needs them. | the concrete adapter implementation (that lives in `infrastructure/<provider>/`) |
| `domain/helpers/` | Pure functions expressing a business rule. | DB queries, HTTP calls |
| `http/dtos/` | The module's **response** contract — what the `controller` returns. | raw provider shape without a decorator |
| `infrastructure/database/drizzle/` | Persistence detail. Command repo and query repo always **separate files**, never merged into one. | business logic, validation |
| `infrastructure/<provider>/services/` | Real call (HTTP/SDK) to one specific external provider. **One service = one use case = one file** (except a Port adapter, which may have one method per Port operation). | manual mapping without going through a DTO, more than one unrelated public method |

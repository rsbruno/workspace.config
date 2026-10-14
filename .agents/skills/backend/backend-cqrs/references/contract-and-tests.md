# Tests, OpenAPI identity, global uniqueness

### Tests are part of the use case

A query, command, controller or module is not done without its tests (`backend-test`): handler unit tests for every branch, repository SQL tests with the organization condition, controller metadata matrix, integration against the dev database and the E2E with the feature + permission matrix. Creating or changing an endpoint without updating its tests is incomplete work.

### OpenAPI/Orval response identity

Every controller response must have an explicit and unambiguous Swagger contract. Delete endpoints must use `@HttpCode(HttpStatus.NO_CONTENT)` together with `@SwaggerDelete()` so Nest does not infer an anonymous `200 {}` response. For non-empty responses, pass a named response DTO to the project Swagger decorator. Before regenerating the frontend client, inspect the generated OpenAPI for duplicate anonymous schemas and verify that every exported model name is unique; never fix a duplicate by editing generated files.

### Global symbol and operation uniqueness

This backend is consumed by Orval, so uniqueness is global across the entire backend, not local to a module. Every exported class, DTO, interface, enum, query, command, handler, controller method, and Swagger `operationId` must have a domain-qualified name that cannot collide with another resource. Do not use generic public names such as `CreateDto`, `UpdateDto`, `FindAll`, `Create`, `Update`, `Delete`, `Restore`, or `Find` when another resource can expose the same symbol. Use names such as `CreateAccountGroupPayloadDto`, `FindAllAccountGroupsQuery`, `FindAllAccountGroupsHandler`, and `listAccountGroups`. Before client generation, scan exported symbols and OpenAPI operation IDs globally and stop if any duplicate exists.

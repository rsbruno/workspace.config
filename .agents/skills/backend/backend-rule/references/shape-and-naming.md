# Permission fields, when to create, standard names

## Fields (fixed shape, no exceptions)

| Field | Rule | Example |
|---|---|---|
| `id` | Same id shape as every other table (`src/http/helpers/createCUID.helper.ts`, prefix `pol` + cuid2). Generate it once (`createCUID('pol')` in a scratch script), hardcode it in `data.json`. Never a readable or derived id | `polob10vds8v0uxzg6moadfp1bt` |
| `name` | **As short as possible**: a title, verb + entity only. Filler (`"permite"`, `"o usuário pode"`) belongs in `description`, never here | `"Criar usuário"` |
| `module` | The catalog grouping of the capability, following the existing values in `data.json` (`items`, `groups`, `chart-of-accounts` for accounts and groups, ...). Never an invented per-table label | `"users"` |
| `code` | **AWS-style** `{domain}:{bounded-context}:{action}`, lowercase, colon-separated. Same value as `Policies.{Domain}.{Module}.{Action}` | `"access:users:create"` |
| `feature` | The billing feature of the endpoint. Same value as `Features.{Domain}.{Module}`. The gate above checks it | `"access:users"` |
| `description` | One sentence in Portuguese, **hard max 100 characters**, starting with `Permite `. Carries the detail `name` omits | `"Permite criar usuários."` |

```json
{
  "id": "polob10vds8v0uxzg6moadfp1bt",
  "name": "Criar usuário",
  "module": "users",
  "feature": "access:users",
  "code": "access:users:create",
  "description": "Permite criar usuários."
}
```

## When to create one

**Every billed endpoint: one permission per controller method**, at the same granularity as the endpoint operation. This includes CRUD and non-CRUD actions, as well as auth/session endpoints when they belong to a billed feature.

The action uses the same standardized operation word for the same capability across every module. Never mix synonyms such as create/add/novo, update/edit/alter, or find/view/get.

## Standard permission names

| Action (`code`) | `name` pattern | `description` pattern |
|---|---|---|
| `create` | Criar {entidade} | Permite criar {entidade_plural}. |
| `update` | Editar {entidade} | Permite editar {entidade_plural}. |
| `archive` | Arquivar {entidade} | Permite arquivar {entidade_plural}. |
| `delete` | Excluir {entidade} | Permite excluir {entidade_plural}. |
| `restore` | Restaurar {entidade} | Permite restaurar {entidade_plural} arquivados. |
| `find` | Visualizar {entidade} | Permite visualizar os dados de {entidade}. |
| `findall` | Listar {entidade_plural} | Permite listar {entidade_plural}. |
| `manage-*` | Gerenciar {relação} | Permite {ação A} e {ação B} {objeto}. |

Naming rules:
- `name` is always a short title: standardized verb + entity/relation.
- `description` always starts with `Permite ` and explains the effect in the infinitive.
- No filler (`o usuário pode`, `o usuário tem permissão para`, `é possível`) and no implementation detail (HTTP method, route, endpoint, screen, button, API).
- No `novos`, `existentes`, `específico`, `todos` unless they change the authorization semantics. Prefer `Permite listar grupos.` over `Permite listar todos os grupos.`
- Entity terminology identical to the rest of the module. Singular for actions on one record (`Criar grupo`), plural for listing (`Listar grupos`).
- `Gerenciar` is reserved for a capability that intentionally groups inverse operations (grant/revoke, link/unlink, attach/detach). It is not a generic replacement for CRUD permissions.

The code action remains the canonical English operation (`create`, `update`, `archive`, `delete`, `restore`, `find`, `findall`, `manage-*`); `name`/`description` are its Portuguese representation.

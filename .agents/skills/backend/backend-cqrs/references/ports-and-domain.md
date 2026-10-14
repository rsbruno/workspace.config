# Domain folder and Ports (gateways)

## 2.1.1 `domain/` — when the module has an entity enum and/or a Port (fixed project rule)

**Create `domain/` whenever the module has at least one business enum and/or a Port.** Soft-delete timestamps do not create a status enum. Each type goes into its own subfolder (`domain/enums/`, `domain/gateways/`) — the module can have just one of the two, or both.

**What goes into `domain/`** — only these two file types, each in its own subfolder, nothing loose directly in `domain/`:

1. **`domain/enums/`** — business enums such as account type, expense type, group level or origin, with zero dependency on framework/database/provider. Soft-delete lifecycle uses `deletedAt` and `archivedAt`, not a status enum.
2. **`domain/gateways/`** — Ports (`<thing>-gateway.interface.ts`, `<thing>-provider.interface.ts`), the interface that defines what the module *needs* from an external dependency, together with the injection token (`Symbol`) on the same export line. Reference: the module's own `domain/gateways/storage-gateway.interface.ts`.

An enum goes into `domain/enums/`, a Port goes into `domain/gateways/` — never loose directly in `domain/`, even when the module only has one file of each type.

**Why it lives in `domain/`, not in `infrastructure/`**: Dependency Inversion — the Port is defined by whoever *uses* it (the use case, in `commands/`/`queries/`), not by whoever *implements* it (the adapter, in `infrastructure/<provider>/`). The dependency arrow points inward: the adapter depends on the Port, never the other way around. If the interface lived inside `infrastructure/<provider>/`, the reading would be inverted — it would look like the provider owns the contract.

```ts
// domain/gateways/<thing>-gateway.interface.ts
export const <THING>_GATEWAY = Symbol('<THING>_GATEWAY');

export interface <Thing>GatewayResult {
  // shape already normalized, in the domain vocabulary -- never a raw provider field/value here
}

export interface <Thing>Gateway {
  someOperation(input: SomeInput): Promise<<Thing>GatewayResult>;
}
```

```ts
// infrastructure/<provider>/services/<provider>-<thing>-gateway.service.ts
@Injectable()
export class <Provider><Thing>GatewayService implements <Thing>Gateway {
  // here, and only here, lives the provider's raw vocabulary (status strings, payload field names) --
  // this service translates to PaymentStatus/domain/ shape before returning
}
```

```ts
// {module}.module.ts
providers: [
  // ...
  { provide: <THING>_GATEWAY, useClass: <Provider><Thing>GatewayService },
],
```

Switching provider later = write a new adapter implementing the same Port + swap the `useClass` on that line. Nothing in `commands/`/`queries/` changes.

**Exception to "one service = one use case"**: the adapter implementing a Port can have more than one public method (one per Port operation) — this isn't a "generic service with loose methods," it's the form required by the interface it implements. Low-level internal methods the adapter uses behind the scenes (e.g. a specific HTTP call) can still be separate single-method services, composed inside the adapter.

**A handler/service using the Port never imports anything from `infrastructure/<provider>/` directly** — only the token + the interface from `domain/gateways/`:

```ts
// commands/some-use-case/some-use-case.handler.ts
constructor(
  @Inject(<THING>_GATEWAY)
  private readonly gateway: <Thing>Gateway, // never imports <Provider><Thing>GatewayService here
) {}
```

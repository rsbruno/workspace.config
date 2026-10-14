# Webhook command and handler

### Webhook Command + Handler

The webhook endpoint on the controller is always `@Public() @HttpCode(200)` (no JWT — authenticated via HMAC in the handler). The controller only extracts headers + body and passes them to the CommandBus; all validation and logic live in the handler.

`handle-<provider>-webhook.command.ts`:
```ts
export class Handle<Provider>WebhookCommand {
  constructor(
    public readonly signature: string,   // e.g. the provider's x-signature
    public readonly requestId: string,   // e.g. the provider's x-request-id
    public readonly body: Record<string, unknown>,
  ) {}
}
```

`handle-<provider>-webhook.handler.ts`:
```ts
import { createHmac, timingSafeEqual } from 'crypto';

import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { UnauthorizedException, Logger } from '@nestjs/common';

import { Handle<Provider>WebhookCommand } from './handle-<provider>-webhook.command';

@CommandHandler(Handle<Provider>WebhookCommand)
export class Handle<Provider>WebhookHandler implements ICommandHandler<Handle<Provider>WebhookCommand> {
  private readonly logger = new Logger(Handle<Provider>WebhookHandler.name);

  async execute(command: Handle<Provider>WebhookCommand): Promise<void> {
    // 1. Freshness check
    const ts = /* extract timestamp from the signature */;
    if (Math.abs(Date.now() - ts * 1000) > 300_000) {
      throw new UnauthorizedException();
    }

    // 2. HMAC-SHA256 — timing-safe compare
    const secret = process.env.PROVIDER_WEBHOOK_SECRET!;
    const manifest = /* build the signature string per the provider's spec */;
    const expected = createHmac('sha256', secret).update(manifest).digest();
    const received = Buffer.from(/* v1 extracted from the signature */, 'hex');

    if (received.length !== expected.length || !timingSafeEqual(received, expected)) {
      throw new UnauthorizedException();
    }

    // 3. ALWAYS re-confirm state with the provider before any write
    //    Never trust the status coming in the webhook body
    const confirmedPayment = await this.<provider>GetPaymentService.get(command.body.data.id as string);

    // 4. Update the DB with the confirmed state
    // ...
  }
}
```

**Fixed rules for webhook handlers:**
- Never use the `status` from the webhook body — always re-confirm with the provider via GET
- `timingSafeEqual` is mandatory (prevents timing attacks)
- A ±5 min freshness check is mandatory
- Return `200 OK` immediately after processing — never 4xx for an unknown event (log and ignore)
- The handler must be **idempotent**: same event twice → identical final state, no error

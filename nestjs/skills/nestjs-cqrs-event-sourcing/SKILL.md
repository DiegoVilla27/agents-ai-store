---
name: nestjs-cqrs-event-sourcing
description: The ultimate architectural standard for Enterprise CQRS and Event Sourcing in NestJS with @nestjs/cqrs, Event Store, Read Model Projections, and Distributed Sagas.
author: Diego Villanueva
trigger: When building complex domain architectures with CQRS, implementing Event Sourcing, orchestrating distributed Sagas, or separating read and write models in NestJS.
---

# Enterprise NestJS CQRS & Event Sourcing Architecture

For high-scale financial systems, auditing requirements, and complex domains, storing only the "current state" in a database loses historical audit trails. **Event Sourcing** stores state as an immutable sequence of domain events, while **CQRS** projects these events into optimized read models.

---

## 1. Aggregate Root with Event Sourcing

```bash
npm install @nestjs/cqrs
```

```typescript
// src/modules/billing/domain/events/invoice-created.event.ts
import { IEvent } from '@nestjs/cqrs';

export class InvoiceCreatedEvent implements IEvent {
  constructor(
    public readonly invoiceId: string,
    public readonly customerId: string,
    public readonly amountInCents: number,
    public readonly createdAt: Date
  ) {}
}
```

```typescript
// src/modules/billing/domain/aggregates/invoice.aggregate.ts
import { AggregateRoot } from '@nestjs/cqrs';
import { InvoiceCreatedEvent } from '../events/invoice-created.event';
import { InvoicePaidEvent } from '../events/invoice-paid.event';

export class InvoiceAggregate extends AggregateRoot {
  private id: string;
  private status: 'UNPAID' | 'PAID' | 'CANCELLED';
  private amount: number;

  constructor(id: string) {
    super();
    this.id = id;
    this.status = 'UNPAID';
  }

  // 1. Command Execution (Mutates aggregate by applying an event)
  static create(id: string, customerId: string, amount: number): InvoiceAggregate {
    const invoice = new InvoiceAggregate(id);
    invoice.apply(new InvoiceCreatedEvent(id, customerId, amount, new Date()));
    return invoice;
  }

  pay(): void {
    if (this.status === 'PAID') throw new Error('Invoice is already paid');
    this.apply(new InvoicePaidEvent(this.id, new Date()));
  }

  // 2. Event Sourcing Handlers (Rebuilds state from event history)
  onInvoiceCreatedEvent(event: InvoiceCreatedEvent) {
    this.id = event.invoiceId;
    this.amount = event.amountInCents;
    this.status = 'UNPAID';
  }

  onInvoicePaidEvent(event: InvoicePaidEvent) {
    this.status = 'PAID';
  }
}
```

---

## 2. Command Handler & Event Publishing

```typescript
// src/modules/billing/application/commands/create-invoice.handler.ts
import { CommandHandler, ICommandHandler, EventPublisher } from '@nestjs/cqrs';
import { CreateInvoiceCommand } from './create-invoice.command';
import { InvoiceAggregate } from '../../domain/aggregates/invoice.aggregate';
import { InvoiceEventStore } from '../../infrastructure/invoice-event-store';

@CommandHandler(CreateInvoiceCommand)
export class CreateInvoiceHandler implements ICommandHandler<CreateInvoiceCommand> {
  constructor(
    private readonly publisher: EventPublisher,
    private readonly eventStore: InvoiceEventStore
  ) {}

  async execute(command: CreateInvoiceCommand): Promise<string> {
    const { id, customerId, amount } = command;

    // 1. Create Aggregate
    const invoice = this.publisher.mergeObjectContext(
      InvoiceAggregate.create(id, customerId, amount)
    );

    // 2. Persist Uncommitted Events to Event Store
    await this.eventStore.saveEvents(id, invoice.getUncommittedEvents());

    // 3. Commit events (Dispatches events to NestJS EventBus & Sagas)
    invoice.commit();

    return id;
  }
}
```

---

## 3. Read Model Projections (Event Handlers)

Event Handlers listen to Domain Events and asynchronously project them into an optimized SQL/Elasticsearch table for read queries:

```typescript
// src/modules/billing/application/projections/invoice-projection.handler.ts
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';
import { InvoiceCreatedEvent } from '../../domain/events/invoice-created.event';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InvoiceReadModel } from '../../infrastructure/entities/invoice-read-model.entity';

@EventsHandler(InvoiceCreatedEvent)
export class InvoiceProjectionHandler implements IEventHandler<InvoiceCreatedEvent> {
  constructor(
    @InjectRepository(InvoiceReadModel)
    private readonly readRepo: Repository<InvoiceReadModel>
  ) {}

  async handle(event: InvoiceCreatedEvent) {
    // Project directly into fast read-optimized table
    await this.readRepo.save({
      id: event.invoiceId,
      customerId: event.customerId,
      amount: event.amountInCents / 100,
      status: 'UNPAID',
      createdAt: event.createdAt,
    });
  }
}
```

---

## 4. Distributed Sagas (Orchestrating Complex Flows)

```typescript
// src/modules/billing/application/sagas/order.saga.ts
import { Injectable } from '@nestjs/common';
import { ICommand, ofType, Saga } from '@nestjs/cqrs';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { InvoicePaidEvent } from '../../domain/events/invoice-paid.event';
import { ShipOrderCommand } from '../../../shipping/application/commands/ship-order.command';

@Injectable()
export class OrderSagas {
  @Saga()
  orderPaid = (events$: Observable<any>): Observable<ICommand> => {
    return events$.pipe(
      ofType(InvoicePaidEvent),
      map((event) => new ShipOrderCommand(event.invoiceId))
    );
  };
}
```

---

**Execution Protocol**
1. **Never mutate aggregate state directly in Command Handlers**: Always invoke `apply(new Event())` and handle mutations in `onEventName()`.
2. **Never query the Event Store for UI reads**: Always query read-model projections.
3. **Always use Sagas for cross-module coordination**: Keeps aggregates decoupled from secondary side-effects.
4. **Append-Only Event Store**: Events are immutable; never execute `UPDATE` or `DELETE` on the Event Store table.

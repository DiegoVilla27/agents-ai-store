---
name: nestjs-patterns
description: The ultimate architectural standard for Enterprise Design Patterns in NestJS CQRS, Strategy Pattern via DI, Factory Providers, and Hexagonal Adapters.
author: Diego Villanueva
trigger: When designing complex business logic, refactoring giant services, implementing multi-provider integrations, or applying CQRS.
---

# NestJS Design Patterns & Enterprise Architecture

NestJS is not just a routing framework; it is an Enterprise Inversion of Control (IoC) container. Because of its heavy reliance on Dependency Injection, many traditional Gang of Four (GoF) design patterns are natively solvable using NestJS primitives.

If you find yourself writing `switch` statements with 20 branches, or a Service class with 3,000 lines of code, you have failed the architectural standard. You must apply the following patterns.

## 1. The Strategy Pattern (Via Dependency Injection)

When your application needs to do the same task but using different algorithms (e.g., charging a credit card via Stripe vs PayPal, or saving a file to AWS S3 vs Azure Blob), you MUST use the Strategy Pattern.

Do NOT write a single `PaymentService` with `if (type === 'stripe') { ... } else if (type === 'paypal') { ... }`.

```typescript
// ✅ ALWAYS: Define a Port (Interface/Abstract Class)
export abstract class PaymentStrategy {
  abstract charge(amount: number): Promise<boolean>;
}

// ✅ ALWAYS: Create concrete Adapters (Implementations)
@Injectable()
export class StripePaymentStrategy implements PaymentStrategy {
  async charge(amount: number) { /* Stripe logic */ return true; }
}

@Injectable()
export class PaypalPaymentStrategy implements PaymentStrategy {
  async charge(amount: number) { /* Paypal logic */ return true; }
}

// ✅ ALWAYS: Inject the abstract strategy into the Domain Service
@Injectable()
export class CheckoutService {
  constructor(private readonly paymentStrategy: PaymentStrategy) {}

  async process() {
    await this.paymentStrategy.charge(100);
  }
}
```

## 2. Factory Providers (`useFactory`)

How do you tell NestJS which Strategy to inject into the `CheckoutService` based on environment variables or tenant configuration? You use a Factory Provider.

```typescript
// ✅ ALWAYS: Use Factories for dynamic Dependency Injection
@Module({
  providers: [
    StripePaymentStrategy,
    PaypalPaymentStrategy,
    {
      provide: PaymentStrategy,
      inject: [ConfigService, StripePaymentStrategy, PaypalPaymentStrategy],
      useFactory: (
        config: ConfigService, 
        stripe: StripePaymentStrategy, 
        paypal: PaypalPaymentStrategy
      ) => {
        const provider = config.get('PAYMENT_PROVIDER');
        return provider === 'stripe' ? stripe : paypal;
      },
    },
    CheckoutService,
  ],
})
export class PaymentsModule {}
```

## 3. CQRS (Command Query Responsibility Segregation)

For extremely complex domains (like an Order Processing Engine), a single `OrderService` will become a "God Class" that handles both intense writes (state machines, validations) and intense reads (complex joins, aggregations).

You MUST use `@nestjs/cqrs` to split this into Commands (Writes) and Queries (Reads).

```typescript
// ✅ ALWAYS: Isolate complex mutations into Commands and Handlers
import { CommandHandler, ICommandHandler, EventPublisher } from '@nestjs/cqrs';

// 1. The Command (Data Object)
export class PlaceOrderCommand {
  constructor(public readonly userId: string, public readonly items: string[]) {}
}

// 2. The Handler (Business Logic)
@CommandHandler(PlaceOrderCommand)
export class PlaceOrderHandler implements ICommandHandler<PlaceOrderCommand> {
  constructor(private publisher: EventPublisher, private repo: OrderRepository) {}

  async execute(command: PlaceOrderCommand) {
    const { userId, items } = command;
    
    // Complex validation and state logic...
    const order = this.repo.create(userId, items);
    
    // Fire domain events
    order.apply(new OrderPlacedEvent(order.id));
    this.publisher.mergeObjectContext(order).commit();
    
    return order;
  }
}

// In the Controller:
@Post()
async createOrder(@Body() dto: CreateOrderDto) {
  // The controller doesn't know who handles this, true decoupling!
  return this.commandBus.execute(new PlaceOrderCommand(dto.userId, dto.items));
}
```

## 4. The Adapter / Facade Pattern (External SDKs)

Never leak an external SDK (like AWS `S3Client` or `SendGridMail`) into your core domain services. If AWS changes their API, you will have to rewrite 50 different domain services.

You MUST wrap external SDKs in a Facade or Adapter class that belongs to your Infrastructure layer.

```typescript
// ❌ ATROCIOUS: Leaking AWS S3 into Domain Logic
@Injectable()
export class UserService {
  constructor(private s3Client: S3Client) {} // Core logic is now coupled to AWS
}

// ✅ ALWAYS: Wrap SDKs in an Adapter Interface
export abstract class StorageService {
  abstract uploadAvatar(userId: string, file: Buffer): Promise<string>;
}

@Injectable()
export class AwsStorageAdapter implements StorageService {
  constructor(private s3Client: S3Client) {}
  
  async uploadAvatar(userId: string, file: Buffer) {
    // Hide all the nasty S3 PutObjectCommand boilerplate here
    return 'https://s3.aws.com/avatar.png';
  }
}
```

## 5. The Proxy Pattern (Interceptors)

When you need to modify the behavior of a method without changing its source code (e.g., adding caching, logging, or timing), you are conceptually applying the Proxy or Decorator pattern. In NestJS, this is solved natively via **Interceptors**.

Never write logging or caching logic directly inside your Service methods. Use AOP (Aspect-Oriented Programming).

---

**Execution Protocol**
1. **Beware of Over-Engineering**: Do not use CQRS for a simple CRUD application. The overhead of creating Commands, Handlers, Queries, and Events will slow down development by 300%. Only use CQRS when the read model significantly diverges from the write model.
2. **Domain Events vs Integration Events**: In CQRS, Domain Events (`OrderPlacedEvent`) are used to update read models or trigger internal side-effects. Do not confuse them with Integration Events (sent to Kafka/RabbitMQ to notify other microservices).
3. **The `Provider` Array**: Master the `providers` array in your Modules. Understanding `useClass`, `useValue`, and `useFactory` is the key to unlocking all architectural patterns in NestJS.

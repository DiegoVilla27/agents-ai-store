---
name: nestjs-modular-monolith
description: The ultimate architectural standard for NestJS Modular Monoliths Bounded Contexts, Event-Driven Communication, avoiding Circular Dependencies, and DDD principles.
author: Diego Villanueva
trigger: When structuring a large NestJS application, defining domain boundaries, fixing circular dependencies, or implementing cross-module communication.
---

# NestJS Modular Monolith Architecture

Microservices are an organizational scaling mechanism, not a default architecture. 95% of applications should start as a **Modular Monolith**. 

NestJS enforces modularity by design, but if you do not respect Domain-Driven Design (DDD) Bounded Contexts, you will end up with a distributed Big Ball of Mud that is impossible to extract into microservices later.

## 1. Bounded Contexts & Strict Boundaries

A Module in NestJS represents a Bounded Context. Modules must be highly cohesive internally, and loosely coupled externally.

- **❌ ATROCIOUS**: The `OrdersModule` importing the `UsersRepository` directly to query user data. This couples the Order domain to the User database schema.
- **✅ ALWAYS**: The `OrdersModule` imports the `UsersModule` and calls a public `UsersService` method. 

```typescript
// ✅ ALWAYS: Expose a clean "Public API" for the module
@Module({
  imports: [TypeOrmModule.forFeature([UserEntity])],
  controllers: [UsersController],
  providers: [
    UsersService,       // Public API (Exported)
    UsersRepository,    // Private Implementation Detail (Hidden)
    UserPasswordHelper, // Private Implementation Detail (Hidden)
  ],
  exports: [UsersService], // ONLY export what other modules are allowed to use
})
export class UsersModule {}
```

## 2. In-Process Event-Driven Communication

If `UsersModule` calls `EmailModule` when a user registers, and `EmailModule` needs to check `UsersModule` for preferences, you have created a **Circular Dependency**.

To achieve true decoupling, use the `@nestjs/event-emitter` package. This simulates a message broker (like Kafka/RabbitMQ) but runs synchronously or asynchronously in memory.

```typescript
// ✅ ALWAYS: Use Event Emitters to decouple domains
// In UsersService (Triggering the event)
@Injectable()
export class UsersService {
  constructor(private eventEmitter: EventEmitter2) {}

  async registerUser(dto: RegisterDto) {
    const user = await this.repo.save(dto);
    
    // Fire and forget. UsersModule doesn't care who listens.
    this.eventEmitter.emit('user.registered', new UserRegisteredEvent(user.id, user.email));
    
    return user;
  }
}

// In EmailService (Listening to the event)
@Injectable()
export class EmailService {
  @OnEvent('user.registered', { async: true })
  async handleUserRegistration(payload: UserRegisteredEvent) {
    // React to the event without tightly coupling EmailModule to UsersModule
    await this.sendWelcomeEmail(payload.email);
  }
}
```

## 3. The `forwardRef()` Anti-Pattern

When you hit a Circular Dependency error (`A requires B, B requires A`), the NestJS documentation suggests using `forwardRef()`.

**CRITICAL WARNING**: Using `forwardRef()` is an architectural failure. It means your domain boundaries are wrong.

If you ever feel the need to use `forwardRef()`:
1. **Extract**: Move the shared logic into a third module (`C`) that both `A` and `B` import.
2. **Event Emitter**: Change the direct service call into an event emission.

## 4. Directory Structure (Domain Driven)

Do not group files by technical role (`/controllers`, `/services`, `/repositories`) at the root level. Group them by Business Domain (`/modules/users`, `/modules/orders`).

```text
src/
├── core/                  # Global utilities, interceptors, filters
├── shared/                # Shared modules (e.g., RedisModule)
├── modules/
│   ├── users/             # Bounded Context
│   │   ├── dto/           # Data Transfer Objects
│   │   ├── entities/      # DB Models
│   │   ├── repositories/  # Data Access Layer
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   └── users.module.ts
│   └── orders/            # Bounded Context
└── main.ts
```

## 5. The Danger of `@Global()` Modules

A Global Module makes its exported providers available everywhere without explicitly importing it in the `imports` array.

- **❌ NEVER**: Make a business module (like `UsersModule`) global just to save yourself from typing `imports: [UsersModule]`. This destroys explicit dependency tracking and makes refactoring impossible.
- **✅ ALWAYS**: Only use `@Global()` for foundational infrastructure: `ConfigModule`, `DatabaseModule`, or `LoggerModule`.

```typescript
// ✅ ALWAYS: Restrict @Global to infrastructure only
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class DatabaseModule {}
```

## 6. Hexagonal Architecture (Ports and Adapters)

In a highly scalable monolith, the Domain logic must not know about the Framework (NestJS) or the Database (Postgres/Prisma).

You achieve this by defining an Interface (Port) in the Domain, and creating an Adapter (Prisma Implementation) in the Infrastructure layer, wiring them together using NestJS Custom Providers.

```typescript
// ✅ ALWAYS: Depend on Interfaces, not Implementations
export const PAYMENT_GATEWAY = Symbol('PAYMENT_GATEWAY');

export interface IPaymentGateway {
  charge(amount: number): Promise<boolean>;
}

@Module({
  providers: [
    {
      provide: PAYMENT_GATEWAY,
      useClass: StripePaymentAdapter, // Can be swapped to PayPalAdapter without touching business logic!
    }
  ],
  exports: [PAYMENT_GATEWAY]
})
export class PaymentsModule {}
```

---

**Execution Protocol**
1. **Module Lazy Loading**: If you have a massive Modular Monolith with background jobs, Serverless functions, and HTTP APIs, you don't want to boot the entire monolith for a small Cron Job. Use NestJS Lazy Loading (`LazyModuleLoader`) or Standalone Applications to boot only the required sub-tree of modules.
2. **Microservice Readiness**: If you follow these rules (strict boundaries, no DB sharing between modules, event-driven communication), extracting the `OrdersModule` into a separate physical microservice in the future will be as simple as changing the `EventEmitter` to a Kafka Client.

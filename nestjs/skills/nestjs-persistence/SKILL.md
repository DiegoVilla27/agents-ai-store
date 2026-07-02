---
name: nestjs-persistence
description: The ultimate architectural standard for NestJS Persistence Repository Pattern, Pure Domain Entities, Data Mappers, and Unit of Work (Transactions).
author: Diego Villanueva
trigger: When configuring database access, writing repositories, managing transactions, or mapping ORM models to Domain Entities.
---

# NestJS Persistence & ORM Architecture

In Enterprise Architecture, the database is an implementation detail. Whether you use Prisma, TypeORM, or Mongoose, your core business logic (Domain Layer) MUST NOT know about it. 

If your Domain Services return Prisma-generated types or use TypeORM decorators (`@Column`), your architecture is highly coupled and you will face severe pain when migrating databases or mocking tests.

## 1. The Pure Domain Entity

A Domain Entity is a pure TypeScript class. It contains state and business rules, but **zero** database knowledge.

```typescript
// ✅ ALWAYS: Pure Domain Entity (No ORM decorators!)
export class User {
  constructor(
    private readonly id: string,
    private email: string,
    private status: 'ACTIVE' | 'BANNED',
  ) {}

  // Encapsulated Business Rule
  public ban(): void {
    if (this.status === 'BANNED') throw new Error("User already banned");
    this.status = 'BANNED';
  }

  // Getters only for reading state
  get getId() { return this.id; }
  get getStatus() { return this.status; }
}
```

## 2. The Repository Pattern (Ports & Adapters)

The Domain defines *what* it needs via an Interface (The Port). The Infrastructure layer provides *how* to do it via a Concrete Class (The Adapter).

```typescript
// ✅ ALWAYS: Define the Port in the Domain Layer
export const USER_REPOSITORY_TOKEN = Symbol('UserRepository');

export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}
```

```typescript
// ✅ ALWAYS: Implement the Adapter in the Infrastructure Layer
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PrismaUserRepository implements IUserRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): Promise<User | null> {
    // 1. Fetch raw data from the DB
    const rawData = await this.prisma.user.findUnique({ where: { id } });
    if (!rawData) return null;

    // 2. Map the raw DB row back into a Rich Domain Entity
    return UserMapper.toDomain(rawData);
  }

  async save(user: User): Promise<void> {
    // 1. Map the Domain Entity back to a raw DB object
    const persistenceData = UserMapper.toPersistence(user);
    
    // 2. Save it
    await this.prisma.user.upsert({
      where: { id: persistenceData.id },
      update: persistenceData,
      create: persistenceData,
    });
  }
}
```

## 3. Data Mappers (Domain ↔ Persistence)

The `UserMapper` is the crucial boundary that translates the database schema into the domain model. This allows your database table to look completely different from your Domain Entity.

```typescript
// ✅ ALWAYS: Isolate mapping logic
export class UserMapper {
  // DB Row -> Rich Entity
  static toDomain(raw: PrismaUser): User {
    return new User(raw.id, raw.email_address, raw.account_status);
  }

  // Rich Entity -> DB Row
  static toPersistence(entity: User): PrismaUser {
    return {
      id: entity.getId,
      email_address: entity.getEmail, // DB uses email_address
      account_status: entity.getStatus, // DB uses account_status
    };
  }
}
```

## 4. The Unit of Work (Transactions)

Handling transactions across multiple Repositories is the hardest problem in Clean Architecture. If you pass the `Prisma.TransactionClient` into your Repositories, you corrupt the Domain with Prisma types.

The modern Enterprise standard is to use **AsyncLocalStorage (ClsHooked)** to propagate the transaction context implicitly, or abstract it behind a Unit of Work (UoW) interface.

### The Unit of Work Interface

```typescript
// ✅ ALWAYS: Abstract transactions using a Unit of Work
export const UNIT_OF_WORK_TOKEN = Symbol('UnitOfWork');

export interface IUnitOfWork {
  execute<T>(work: () => Promise<T>): Promise<T>;
}

// In the Domain Service:
@Injectable()
export class OrderService {
  constructor(
    @Inject(UNIT_OF_WORK_TOKEN) private readonly uow: IUnitOfWork,
    @Inject(ORDER_REPOSITORY_TOKEN) private readonly orderRepo: IOrderRepository,
    @Inject(INVENTORY_REPOSITORY_TOKEN) private readonly inventoryRepo: IInventoryRepository,
  ) {}

  async placeOrder(orderId: string, itemId: string) {
    // Both repositories will magically use the same DB transaction!
    await this.uow.execute(async () => {
      await this.inventoryRepo.decrementStock(itemId);
      await this.orderRepo.markAsPaid(orderId);
    });
  }
}
```
*Note: The actual implementation of `IUnitOfWork` using Prisma requires setting up Prisma Client extensions and AsyncLocalStorage to intercept the queries and route them to the active transaction client.*

## 5. Active Record vs Data Mapper

TypeORM allows two patterns: Active Record (`User.save()`) and Data Mapper (`userRepository.save(user)`).

- **❌ NEVER**: Use Active Record in an Enterprise application. It tightly couples your Domain Entity to the database connection. You cannot test your business logic without a live database.
- **✅ ALWAYS**: Use the Data Mapper pattern (Repositories) to keep Entities pure.

---

**Execution Protocol**
1. **The Leak Rule**: If you import `@prisma/client` or `typeorm` inside your `users.service.ts` (Domain Layer), you have violated the architecture. ORM imports belong strictly in the `/repositories` or `/infrastructure` folders.
2. **Read Models vs Write Models (CQRS)**: The strict Repository/Mapper pattern is designed to protect complex business rules during WRITES (Commands). However, for simple READS (e.g., getting a list of 10,000 users for an admin table), mapping 10,000 rows to Domain Entities is a massive performance bottleneck. For pure reads, it is acceptable to bypass the Domain and query the DB directly, returning raw DTOs (CQRS).

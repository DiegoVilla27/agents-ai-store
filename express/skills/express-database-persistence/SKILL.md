---
name: express-database-persistence
description: Design patterns for database connection lifecycles, connection pool management, database transactions, and database client singletons in Express.js.
author: Diego Villanueva
trigger: When configuring databases (Prisma, TypeORM, Mongoose), establishing repository boundaries, or handling database transactions.
---

# Express.js Database & Persistence Architecture

Express does not come with a built-in database layer. You must define clear architectural boundaries, manage database connection lifecycles, and use repositories to separate persistence details from business rules.

---

## 1. Database Client Singleton Pattern

Re-instantiating database clients (like Prisma Client, Sequelize, Mongoose, or pg Pool) on every module import or request exhausts database connection pools, causing connection timeouts under load.

**❌ NEVER** initialize a new database client in multiple files or inside request handler functions.
**✅ ALWAYS** declare the database client as a singleton instance and export it globally.

```typescript
// ✅ ALWAYS: Use a singleton database connection helper
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

---

## 2. Repository Pattern Boundaries

The Repository Pattern separates domain business logic from the concrete persistence details (SQL, MongoDB, local memory). The application layer interacts with abstract interfaces (ports), and the infrastructure layer provides implementation adapters.

**❌ NEVER** write database queries (e.g. `prisma.user.findUnique()`) directly inside Express controllers or use cases.
**✅ ALWAYS** wrap persistence calls in repository classes implementing Domain Interfaces.

```typescript
// 🟢 Domain Layer: Repository Port (Interface)
export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}

// 🟡 Infrastructure Layer: Repository Adapter
import { IUserRepository } from '../../domain/repositories/IUserRepository';
import { User } from '../../domain/entities/User';
import { prisma } from '../client';

export class PrismaUserRepository implements IUserRepository {
  async findById(id: string): Promise<User | null> {
    const record = await prisma.user.findUnique({ where: { id } });
    if (!record) return null;
    return User.reconstitute(record.id, record.email, record.password);
  }

  async save(user: User): Promise<void> {
    await prisma.user.upsert({
      where: { id: user.getId() },
      update: { email: user.getEmail() },
      create: { id: user.getId(), email: user.getEmail(), password: user.getPassword() },
    });
  }
}
```

---

## 3. Database Transaction Boundaries

When a write operation mutates multiple database tables (or documents), it must execute within a transactional block to ensure data consistency (Atomicity).

**❌ NEVER** run multiple independent write operations in sequence without a transactional scope when they are part of a single business operation.
**✅ ALWAYS** orchestrate transactions using Unit of Work boundaries or ORM-specific transaction blocks.

```typescript
// ✅ ALWAYS: Enforce atomic transactions for multi-aggregate operations
import { prisma } from '../client';

export class OrderPersistenceService {
  async createOrderAndDeductStock(orderData: any, stockUpdates: any[]): Promise<void> {
    // Wrap operations inside an atomic transaction block
    await prisma.$transaction(async (tx) => {
      await tx.order.create({
        data: orderData
      });

      for (const update of stockUpdates) {
        await tx.product.update({
          where: { id: update.productId },
          data: { stock: { decrement: update.quantity } }
        });
      }
    });
  }
}
```

---

## 4. Connection Pool & Shutdown Management

Unclosed database connections hang Node processes during hot reloads or application updates, leading to connection leaks.

**❌ NEVER** forget to close database clients when the application receives termination signals.
**✅ ALWAYS** capture termination signals (`SIGINT`, `SIGTERM`) and close active connections cleanly.

```typescript
// server.ts
import { prisma } from './infrastructure/persistence/client';

const gracefulShutdown = async () => {
  console.log('Shutting down database connections...');
  await prisma.$disconnect();
  console.log('Database disconnected successfully.');
  process.exit(0);
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
```

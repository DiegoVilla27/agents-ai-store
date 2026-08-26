---
name: nextjs-drizzle-orm
description: The ultimate architectural standard for High-Performance Edge-Compatible Persistence in Next.js with Drizzle ORM, Drizzle Kit Migrations, Type-Safe Relations, and Serverless Connections.
author: Diego Villanueva
trigger: When configuring Drizzle ORM in Next.js, building type-safe database schemas, writing relational queries, or running Edge/Serverless database queries.
---

# Enterprise Next.js Persistence with Drizzle ORM

While traditional heavy ORMs struggle with high cold starts in serverless environments, **Drizzle ORM** provides zero-overhead, SQL-like query syntax, automatic TypeScript type inference, and 100% compatibility with Edge runtimes (Cloudflare Workers, Vercel Edge, Neon, PlanetScale, Supabase).

---

## 1. Schema Definition with Relations (`src/db/schema.ts`)

```bash
npm install drizzle-orm @neondatabase/serverless pg
npm install -D drizzle-kit @types/pg
```

```typescript
// src/db/schema.ts
import { pgTable, text, timestamp, uuid, varchar, integer, boolean } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

// 1. Users Table
export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  fullName: varchar('full_name', { length: 100 }).notNull(),
  role: varchar('role', { length: 20 }).default('USER').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// 2. Orders Table
export const orders = pgTable('orders', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  totalAmountInCents: integer('total_amount_in_cents').notNull(),
  isPaid: boolean('is_paid').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// 3. Relational Schema Mapping
export const usersRelations = relations(users, ({ many }) => ({
  orders: many(orders),
}));

export const ordersRelations = relations(orders, ({ one }) => ({
  user: one(users, {
    fields: [orders.userId],
    references: [users.id],
  }),
}));

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Order = typeof orders.$inferSelect;
```

---

## 2. Serverless Database Client Singleton (`src/db/index.ts`)

```typescript
// src/db/index.ts
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';
import * as schema from './schema';

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql, { schema });
```

---

## 3. High-Performance Relational Queries in Server Components

```tsx
// src/features/users/services/user.service.ts
import { db } from '@/db';
import { eq, desc } from 'drizzle-orm';
import { users } from '@/db/schema';

export async function getUserWithRecentOrders(userId: string) {
  // Ultra-fast relational query with automatic type inference!
  return await db.query.users.findFirst({
    where: eq(users.id, userId),
    with: {
      orders: {
        orderBy: (orders, { desc }) => [desc(orders.createdAt)],
        limit: 5,
      },
    },
  });
}
```

---

## 4. Drizzle Kit Migration Configuration (`drizzle.config.ts`)

```typescript
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './drizzle/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  strict: true,
  verbose: true,
});
```

### Run Migrations:
```bash
npx drizzle-kit generate # Generate SQL migration file
npx drizzle-kit migrate  # Apply migrations to database
```

---

**Execution Protocol**
1. **Always export TypeScript types using `$inferSelect` and `$inferInsert`**: Keeps domain models synchronized with database schemas.
2. **Use `db.query` relational queries for complex joins**: Eliminates manual boilerplate SQL joins.
3. **Use atomic transactions for multi-row operations**: `await db.transaction(async (tx) => { ... })`.

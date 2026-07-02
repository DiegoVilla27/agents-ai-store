---
name: nextjs-orm-prisma
description: The ultimate architectural standard for Database Integration, Connection Pooling, Query Optimization, and Type-Safe DALs using Prisma ORM in Next.js.
author: Diego Villanueva
trigger: When defining database schemas, executing Prisma queries, handling database connections, or designing the Data Access Layer (DAL).
---

# Next.js + Prisma ORM Architecture

Prisma is the premier ORM for Next.js due to its unmatched end-to-end type safety. However, without strict architectural boundaries, developers will accidentally exhaust database connections, over-fetch data, and tightly couple the UI to the database schema.

## 1. The Connection Pool Singleton (CRITICAL)

In development, Next.js clears the Node.js cache on every hot reload. If you simply `new PrismaClient()` in a file, Next.js will create hundreds of new database connections until the database crashes (Connection Exhaustion).

You MUST use the `globalThis` singleton pattern to preserve the connection across HMR reloads.

```typescript
// ✅ ALWAYS: db.ts (The Singleton Pattern)
import { PrismaClient } from '@prisma/client';

const prismaClientSingleton = () => {
  return new PrismaClient({
    // Enable query logging in development
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  });
};

declare global {
  var prismaGlobal: undefined | ReturnType<typeof prismaClientSingleton>;
}

// Preserve connection in development, but create new in production
export const db = globalThis.prismaGlobal ?? prismaClientSingleton();

if (process.env.NODE_ENV !== 'production') globalThis.prismaGlobal = db;
```

## 2. The Data Access Layer (DAL) Boundary

**NEVER** import `db` directly into a Next.js Server Component or Server Action. This breaks the Single Responsibility Principle, makes testing impossible, and risks leaking sensitive database rows to the client.

Always abstract Prisma calls behind a Repository or Service function (Data Access Layer).

```typescript
// ❌ ATROCIOUS: Calling Prisma directly in a component
export default async function Page() {
  const users = await db.user.findMany(); // Architectural violation
  return <UserList users={users} />;
}

// ✅ ALWAYS: Abstract into a DAL (lib/dal/users.ts)
import 'server-only';
import { db } from '@/lib/db';

export async function getActiveUsers() {
  return await db.user.findMany({
    where: { status: 'ACTIVE' },
    select: { id: true, name: true, avatar: true }, // NEVER fetch the password hash!
  });
}
```

## 3. Query Optimization (`select` vs `include`)

By default, Prisma returns every column in a table. If a table has a `bio` column with 10,000 characters, fetching 100 users will download 1 Megabyte of text just to render their names in a dropdown.

- **`select`**: Strictly defines which columns to return. Use this 90% of the time.
- **`include`**: Joins related tables but brings back ALL columns from both tables. Use with extreme caution.

```typescript
// ❌ ATROCIOUS: Over-fetching (Selects password, bio, timestamps, etc.)
const users = await db.user.findMany({ include: { posts: true } });

// ✅ ALWAYS: Surgical fetching (Select only what the UI needs)
const users = await db.user.findMany({
  select: {
    id: true,
    email: true,
    posts: {
      where: { published: true },
      select: { title: true, slug: true },
      take: 5, // Pagination is mandatory on relations!
    },
  },
});
```

## 4. Extracting Inferred Types (Payloads)

When you use `select` or `include`, Prisma dynamically generates a return type. DO NOT try to write this TypeScript interface manually. Use `Prisma.UserGetPayload`.

```typescript
// ✅ ALWAYS: Infer complex types from Prisma
import { Prisma } from '@prisma/client';

// 1. Define the query shape
const userWithPosts = Prisma.validator<Prisma.UserDefaultArgs>()({
  select: { id: true, name: true, posts: { select: { title: true } } }
});

// 2. Extract the Type
export type UserWithPosts = Prisma.UserGetPayload<typeof userWithPosts>;

// 3. Use it in your React Components
export function UserProfile({ user }: { user: UserWithPosts }) {
  return <div>{user.posts[0].title}</div>;
}
```

## 5. Transactions (`$transaction`)

If you are creating a user and their initial profile settings, both operations MUST succeed, or both must fail. If you don't use a transaction and the second query fails, you will have an orphaned user in your database.

```typescript
// ✅ ALWAYS: Use Interactive Transactions for multi-step mutations
export async function registerUser(data: RegisterDTO) {
  return await db.$transaction(async (tx) => {
    // 1. Check if user exists
    const existing = await tx.user.findUnique({ where: { email: data.email } });
    if (existing) throw new Error("Email taken");

    // 2. Create the user
    const user = await tx.user.create({ data: { email: data.email } });

    // 3. Create the profile linked to the user
    await tx.profile.create({ data: { userId: user.id, plan: 'FREE' } });

    return user;
  });
}
```

## 6. The Edge Constraint (Middleware)

The standard `@prisma/client` uses a Rust binary (`query-engine`) that CANNOT run in V8 isolates (Next.js Edge Middleware). 

- **If you need DB access in Middleware**: You MUST use Prisma Accelerate (connection pooling proxy) or an HTTP-based driver (like `@prisma/adapter-neon` with `@neondatabase/serverless`) combined with `@prisma/client/edge`.

---

**Execution Protocol**
1. **Never use `db.$queryRaw` unless strictly necessary**: It bypasses Prisma's type safety and opens you up to SQL Injection if you don't use the `Prisma.sql` template literal correctly. Always exhaust the standard Prisma Client API before dropping to raw SQL.
2. **Post-Schema Updates**: Every time you modify `schema.prisma`, you MUST run `npx prisma generate` to rebuild the TypeScript definitions in `node_modules/@prisma/client`.
3. **Database Indexes**: Prisma makes querying easy, but it does not magically make the database fast. ALWAYS define `@@index([column])` in your `schema.prisma` for columns that are frequently used in `where` or `orderBy` clauses.

---
name: nextjs-caching-isr
description: The ultimate architectural standard for Next.js Cache Mechanisms, Incremental Static Regeneration (ISR), and On-Demand Revalidation.
author: Diego Villanueva
trigger: When optimizing page load speeds, implementing background data fetching, handling stale data, or configuring Next.js caching behavior.
---

# Next.js Caching & ISR Architecture

Next.js is built around aggressive caching mechanisms designed to eliminate database load and serve pages globally from CDNs. However, if mismanaged, you will serve stale data to your users or accidentally blow up your database. 

**CRITICAL NOTE FOR NEXT.JS 15**: In Next.js 14, `fetch` was cached by default. **In Next.js 15, `fetch` requests are NOT cached by default**. You must explicitly opt-in to caching.

## 1. The Four Cache Mechanisms

You must understand the pipeline:
1. **Request Memoization** (Server, Lifetime of 1 render pass): Deduplicates identical `fetch` requests in the same React tree.
2. **Data Cache** (Server, Persistent across requests): Stores the actual response from `fetch` globally across all users.
3. **Full Route Cache** (Server, Persistent): Stores the fully rendered HTML payload of a page.
4. **Router Cache** (Client, In-Memory): Caches payloads in the browser as the user navigates.

## 2. Request Memoization (Deduplication)

If you fetch the current user in `layout.tsx`, and fetch them again in `page.tsx`, Next.js intercepts the second fetch and returns the result from memory.

- **`fetch`**: Automatically memoized.
- **Direct DB Queries**: Are NOT automatically memoized. You MUST use React's `cache` function to prevent duplicate DB hits.

```tsx
// ✅ ALWAYS: Memoize direct DB queries
import { cache } from 'react';
import { db } from '@/lib/db';

export const getUser = cache(async (id: string) => {
  // If called 5 times in the same render, the DB is only hit ONCE.
  return await db.user.findUnique({ where: { id } });
});
```

## 3. Time-Based Revalidation (ISR)

Incremental Static Regeneration (ISR) is the pattern of serving static (cached) content instantly to users, but regenerating it in the background if it's older than a specific time.

- The first user after the time expires gets the **stale** data instantly.
- The server regenerates the page in the background.
- The next user gets the fresh data.

```tsx
// ✅ ALWAYS: Use ISR for data that updates periodically but doesn't need instant sync
export async function getBlogPosts() {
  const res = await fetch('https://api.example.com/posts', {
    // Cache the response, but regenerate in background if older than 1 hour (3600s)
    next: { revalidate: 3600 } 
  });
  return res.json();
}
```

## 4. On-Demand Revalidation (The Gold Standard)

Time-based ISR is insufficient for enterprise applications (e.g., an admin updates a product price, they expect to see it instantly, not in 1 hour). You must use **On-Demand Revalidation**.

- **Tags**: Apply a unique tag to a fetch request.
- **Server Actions/Webhooks**: Call `revalidateTag` when a mutation occurs.

```tsx
// 1. Tag your fetch request
export async function getProducts() {
  const res = await fetch('https://api.example.com/products', {
    cache: 'force-cache',
    next: { tags: ['products-list'] } // Tags are arbitrary strings
  });
  return res.json();
}

// 2. Invalidate it instantly on mutation (Server Action)
"use server";
import { revalidateTag } from 'next/cache';

export async function updateProductPrice(id: string, price: number) {
  await db.updatePrice(id, price);
  
  // Instantly purges the Data Cache and Route Cache globally!
  revalidateTag('products-list'); 
}
```

## 5. Caching Direct Database Queries

The `fetch` API has caching built-in via the `next` object, but if you query a database directly (e.g., using Prisma or Drizzle), you must use Next.js's `unstable_cache`.

```tsx
// ✅ ALWAYS: Cache expensive database queries
import { unstable_cache } from 'next/cache';

export const getDashboardStats = unstable_cache(
  async (userId: string) => {
    return await db.runHeavyAnalyticsQuery(userId);
  },
  ['dashboard-stats'], // Cache key parts
  { 
    revalidate: 60, // Regenerate every minute
    tags: ['analytics'] // Allows manual purging
  }
);
```

## 6. Route Segment Config

Sometimes you want to opt an entire page out of caching entirely, making it run strictly at Request Time (SSR).

```tsx
// ✅ ALWAYS: Explicitly declare dynamic routes if they rely on headers/cookies
export const dynamic = 'force-dynamic'; // Disables Full Route Cache

export default async function DashboardPage() {
  // This page will NEVER be statically generated at build time
  return <Dashboard />
}
```

---

**Execution Protocol**
1. **Never use `no-store` globally**: A 100% dynamic app is slow and expensive. Identify what parts of the page can be cached (e.g., the navigation bar, footer) and isolate the dynamic parts (e.g., the user profile) using React `<Suspense>`.
2. **`revalidatePath` vs `revalidateTag`**: Use `revalidatePath('/blog')` for simple, single-page purges. Strongly prefer `revalidateTag('blog-posts')` for enterprise apps, as it can purge the data across multiple different routes simultaneously (e.g., purging the list on `/blog` and the sidebar on `/about`).
3. **Cookies & Headers**: The moment you call `cookies()` or `headers()` inside a Server Component, Next.js automatically opts that route out of static generation and makes it fully dynamic. You cannot cache personalized data statically.

---
name: nextjs-15-async-request-apis
description: The ultimate architectural standard for Next.js 15 Async Request APIs, React 19 compatibility, async cookies()/headers()/params, and unstable_after() background execution.
author: Diego Villanueva
trigger: When developing with Next.js 15+, migrating async request headers/cookies/params, executing background work with after(), or using React 19 features in Next.js.
---

# Enterprise Next.js 15 Async Request APIs Architecture

Next.js 15 introduces major architectural changes, making runtime request data (`cookies()`, `headers()`, `params`, and `searchParams`) **asynchronous Promises** to prepare the server for Partial Prerendering (PPR) and concurrent rendering optimizations.

---

## 1. Async `cookies()` and `headers()`

**❌ NEVER** access `cookies()` or `headers()` synchronously in Next.js 15.
**✅ ALWAYS** `await` them before reading or mutating values.

```tsx
// src/app/api/user/route.ts or Server Component
import { cookies, headers } from 'next/headers';

export async function GET() {
  // Await cookies and headers in Next.js 15
  const cookieStore = await cookies();
  const token = cookieStore.get('session_token')?.value;

  const headerList = await headers();
  const userAgent = headerList.get('user-agent');

  return Response.json({ authenticated: Boolean(token), userAgent });
}
```

---

## 2. Async `params` and `searchParams` in Layouts, Pages, and Route Handlers

In Next.js 15, route parameters are passed as asynchronous Promises to allow dynamic streaming without blocking parent layout rendering.

```tsx
// src/app/products/[id]/page.tsx
interface PageProps {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export default async function ProductPage({ params, searchParams }: PageProps) {
  // Await params and searchParams before consumption
  const { id } = await params;
  const resolvedSearchParams = await searchParams;
  const viewMode = resolvedSearchParams.view ?? 'grid';

  const product = await getProductById(id);

  return (
    <main>
      <h1>{product.title}</h1>
      <p>Viewing in: {viewMode}</p>
    </main>
  );
}
```

### Dynamic Metadata with Async Params:

```tsx
// src/app/products/[id]/page.tsx
import { Metadata } from 'next';

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const product = await getProductById(id);

  return {
    title: `${product.title} | Enterprise Store`,
    description: product.description,
  };
}
```

---

## 3. Background Work with `unstable_after()` (`after()`)

In traditional serverless routes, background tasks (logging analytics, sending telemetry, syncing caches) get aborted when the HTTP response closes. **`after()`** schedules work to execute *after* the response has streamed to the user without blocking TTFB (Time to First Byte).

```tsx
// src/app/api/checkout/route.ts
import { unstable_after as after } from 'next/server';
import { logAnalyticsEvent } from '@/lib/analytics';
import { sendSlackNotification } from '@/lib/notifications';

export async function POST(request: Request) {
  const body = await request.json();

  // 1. Process payment synchronously
  const order = await processOrder(body);

  // 2. Schedule non-blocking background tasks after response closes!
  after(async () => {
    await logAnalyticsEvent('order_completed', { orderId: order.id });
    await sendSlackNotification(`New Enterprise Order: $${order.total}`);
  });

  // 3. Immediate instant response to the client
  return Response.json({ success: true, orderId: order.id });
}
```

---

## 4. Next.js 15 Fetch Caching Default Change

In Next.js 14 and below, `fetch()` cached responses by default (`cache: 'force-cache'`).
In **Next.js 15**, `fetch()` defaults to **`no-store` (uncached)** to align with developer expectations and prevent accidental caching of user-specific data.

```tsx
// Opt-in explicitly to caching in Next.js 15:
const cachedData = await fetch('https://api.acme.com/data', {
  cache: 'force-cache',
  next: { tags: ['global-settings'], revalidate: 3600 },
});
```

---

**Execution Protocol**
1. **Always type `params` and `searchParams` as `Promise<T>`**: Enforces clean Next.js 15 and TypeScript compatibility.
2. **Use `after()` for secondary side-effects**: Keep response latencies under 50ms by offloading telemetry to background hooks.
3. **Explicitly declare `cache: 'force-cache'` on public static fetches**: Prevents redundant upstream API strain in Next.js 15.

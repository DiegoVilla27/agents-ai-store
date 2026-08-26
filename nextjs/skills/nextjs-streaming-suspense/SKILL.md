---
name: nextjs-streaming-suspense
description: The ultimate architectural standard for Progressive SSR, Partial Prerendering (PPR), Instant Loading States (loading.tsx), Granular Suspense Boundaries, and Streaming AI in Next.js.
author: Diego Villanueva
trigger: When configuring progressive SSR, Partial Prerendering (PPR), streaming data with Suspense, creating skeleton loading states, or streaming AI tokens in Next.js.
---

# Enterprise Next.js Streaming, Suspense & Partial Prerendering (PPR)

Traditional SSR blocks the entire page until the slowest database query completes. Next.js **Streaming SSR**, **React Suspense**, and **Partial Prerendering (PPR)** stream static HTML immediately from the edge while streaming slow dynamic components progressively over an open HTTP chunked connection.

---

## 1. Instant Loading States with `loading.tsx`

Next.js automatically wraps `page.tsx` inside a React `<Suspense fallback={<Loading />}>` boundary when a sibling `loading.tsx` is present.

```tsx
// src/app/dashboard/loading.tsx
import { Skeleton } from '@/components/ui/skeleton';

export default function DashboardLoading() {
  return (
    <div className="space-y-6 p-8">
      <Skeleton className="h-10 w-48 rounded-lg" />
      <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
        <Skeleton className="h-32 rounded-xl" />
        <Skeleton className="h-32 rounded-xl" />
        <Skeleton className="h-32 rounded-xl" />
      </div>
      <Skeleton className="h-96 w-full rounded-2xl" />
    </div>
  );
}
```

---

## 2. Granular Component-Level Suspense Boundaries

Avoid wrapping entire pages in a single Suspense boundary. Isolate slow external API calls into dedicated Server Components:

```tsx
// src/app/dashboard/page.tsx
import { Suspense } from 'react';
import { UserGreeting } from '@/features/dashboard/components/user-greeting';
import { FastMetricsCards } from '@/features/dashboard/components/fast-metrics-cards';
import { SlowExternalAnalyticsChart } from '@/features/dashboard/components/slow-external-analytics-chart';
import { ChartSkeleton } from '@/components/skeletons';

export default function DashboardPage() {
  return (
    <div className="space-y-8 p-8">
      {/* 1. Fast Server Component: Renders instantly */}
      <UserGreeting />

      {/* 2. Fast DB Metrics: Renders in < 20ms */}
      <FastMetricsCards />

      {/* 3. Slow 3rd-party integration: Streamed progressively over HTTP! */}
      <Suspense fallback={<ChartSkeleton />}>
        <SlowExternalAnalyticsChart />
      </Suspense>
    </div>
  );
}
```

---

## 3. Partial Prerendering (PPR) in Next.js 15

PPR combines static shell generation at build time with dynamic streaming on request:

```typescript
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    ppr: 'incremental', // Enable Partial Prerendering incrementally
  },
};

export default nextConfig;
```

```tsx
// src/app/store/page.tsx
export const experimental_ppr = true; // Static Shell + Dynamic Streamed Content

export default function StorePage() {
  return (
    <div>
      {/* Pre-rendered static shell (Served in 0ms from Edge CDN) */}
      <StoreHeader />
      <StaticFeaturedBanner />

      {/* Dynamic personalized cart & user recommendations (Streamed) */}
      <Suspense fallback={<CartBadgeSkeleton />}>
        <UserLiveCartBadge />
      </Suspense>
    </div>
  );
}
```

---

## 4. Streaming AI Completions with the Vercel AI SDK

```tsx
// src/app/api/chat/route.ts
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: openai('gpt-4o'),
    messages,
  });

  return result.toDataStreamResponse();
}
```

---

**Execution Protocol**
1. **Never block fast UI behind slow database queries**: Isolate slow widgets inside independent `<Suspense>` boundaries.
2. **Design pixel-perfect Skeletons**: Ensure Skeleton component dimensions exactly match the resolved widget dimensions to eliminate Cumulative Layout Shift (CLS = 0).
3. **Use Partial Prerendering for e-commerce and marketing pages**: Serves static navigation/hero from edge while streaming live prices/stock.

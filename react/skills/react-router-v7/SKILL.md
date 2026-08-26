---
name: react-router-v7
description: The ultimate architectural standard for React Router v7 Typed Data Loaders, Actions, Nested Layouts, Typegen, and SPA/SSR Routing.
author: Diego Villanueva
trigger: When configuring routing in modern React applications, building nested layouts, handling data loaders, executing form actions, or upgrading to React Router v7.
---

# Enterprise React Router v7 Architecture

React Router v7 represents the official unification of React Router and Remix. It brings declarative, type-safe data loading, server/client actions, nested layout hierarchies, and automatic code-splitting into standard React SPA and full-stack applications.

---

## 1. Route Configuration (`react-router.config.ts` & `routes.ts`)

In React Router v7, route configurations provide end-to-end type safety.

```typescript
// app/routes.ts
import { type RouteConfig, index, layout, route, prefix } from '@react-router/dev/routes';

export default [
  // Public Root Layout
  layout('layouts/public-layout.tsx', [
    index('routes/home.tsx'),
    route('about', 'routes/about.tsx'),
    route('login', 'routes/login.tsx'),
  ]),

  // Protected App Dashboard with Nested Navigation
  layout('layouts/dashboard-layout.tsx', [
    ...prefix('dashboard', [
      index('routes/dashboard-home.tsx'),
      route('orders', 'routes/orders.tsx'),
      route('orders/:orderId', 'routes/order-detail.tsx'),
      route('settings', 'routes/settings.tsx'),
    ]),
  ]),
] satisfies RouteConfig;
```

---

## 2. Type-Safe Data Loading (`loader`)

**❌ NEVER** fetch page-level data inside `useEffect` in routed components.
**✅ ALWAYS** use route `loader` functions to fetch before the component renders, eliminating loading waterfalls.

```tsx
// app/routes/order-detail.tsx
import type { Route } from './+types/order-detail';
import { useLoaderData } from 'react-router';
import { db } from '@/lib/db';

// 1. Loader Function (Runs in parallel with code download)
export async function loader({ params }: Route.LoaderArgs) {
  const order = await db.getOrderById(params.orderId);
  if (!order) {
    throw new Response('Order Not Found', { status: 404 });
  }
  return { order };
}

// 2. Component (Receives fully typed data automatically via Typegen)
export default function OrderDetailPage({ loaderData }: Route.ComponentProps) {
  const { order } = loaderData;

  return (
    <article className="p-6">
      <h1 className="text-2xl font-bold">Order #{order.id}</h1>
      <p className="text-gray-600">Customer: {order.customerName}</p>
      <p className="text-lg font-semibold mt-4">Total: ${order.totalAmount}</p>
    </article>
  );
}
```

---

## 3. Data Mutations via Actions (`action`)

Route actions handle form submissions, validate payloads, and automatically revalidate active page loaders:

```tsx
// app/routes/order-detail.tsx
import type { Route } from './+types/order-detail';
import { Form, redirect } from 'react-router';
import { db } from '@/lib/db';

export async function action({ request, params }: Route.ActionArgs) {
  const formData = await request.formData();
  const status = formData.get('status') as string;

  await db.updateOrderStatus(params.orderId, status);

  // Automatic revalidation of loaders happens out-of-the-box!
  return { success: true };
}

export function OrderStatusForm({ orderId, currentStatus }: { orderId: string; currentStatus: string }) {
  return (
    <Form method="post" className="flex gap-4 items-center">
      <select name="status" defaultValue={currentStatus} className="border p-2 rounded">
        <option value="PENDING">Pending</option>
        <option value="SHIPPED">Shipped</option>
        <option value="DELIVERED">Delivered</option>
      </select>
      <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded">
        Update Status
      </button>
    </Form>
  );
}
```

---

## 4. Pending UI & Optimistic Navigation (`useNavigation`)

Provide instant visual feedback during route transitions:

```tsx
import { useNavigation } from 'react-router';

export function GlobalProgressBar() {
  const navigation = useNavigation();
  const isNavigating = Boolean(navigation.location);

  if (!isNavigating) return null;

  return (
    <div className="fixed top-0 left-0 right-0 h-1 bg-blue-600 animate-pulse z-50" />
  );
}
```

---

## 5. Error Boundaries (`ErrorBoundary`)

Every route file can export an `ErrorBoundary` to catch runtime or loader errors without crashing the parent layout:

```tsx
import type { Route } from './+types/order-detail';
import { isRouteErrorResponse } from 'react-router';

export function ErrorBoundary({ error }: Route.ErrorBoundaryProps) {
  if (isRouteErrorResponse(error)) {
    return (
      <div className="p-8 text-center">
        <h2 className="text-xl font-bold text-red-600">{error.status} {error.statusText}</h2>
        <p className="text-gray-600 mt-2">{error.data}</p>
      </div>
    );
  }

  return (
    <div className="p-8 text-center text-red-600">
      <h2>Unexpected Application Error</h2>
      <p>{(error as Error).message}</p>
    </div>
  );
}
```

---

**Execution Protocol**
1. **Always use route `loader` for data fetching**: Eliminate waterfall `useEffect` fetch calls.
2. **Always use `<Form>` for mutations**: Guarantees automatic cache invalidation and re-rendering.
3. **Always declare `ErrorBoundary` on critical feature routes**: Isolates failures gracefully.
4. **Use Typegen `Route.ComponentProps`**: Guarantees 100% type safety between loaders, actions, and JSX.

---
name: next-routes
description: The ultimate architectural standard for Advanced Next.js Routing: Parallel Routes, Intercepting Routes (Modals), Streaming, and Middleware.
author: Diego Villanueva
trigger: When building complex layouts, URL-driven modals, streaming UIs, or configuring Edge Middleware.
---

# Next.js Advanced Routing Architecture

The Next.js App Router is a powerful, nested routing engine. Mastering it means understanding that the URL is the ultimate state manager.

## 1. Intercepting Routes (The "Instagram Modal" Pattern)

Intercepting routes allow you to load a route from another part of your application within the current layout (usually as a Modal). 

**The Goal**: When a user clicks a photo in the feed, it opens in a Modal (`/photo/123`). If they copy the URL and send it to a friend, or hit refresh, the friend sees the full, standalone page (`/photo/123`), NOT a modal over an empty background.

- **`(.)`**: Match segments on the same level.
- **`(..)`**: Match segments one level above.
- **`(...)`**: Match segments from the root `app` directory.

```text
// ✅ ALWAYS: Directory structure for Intercepting Routes
app/
├── feed/
│   ├── page.tsx          # Feed page with <Link href="/photo/123">
│   └── @modal/           # Parallel route slot for the modal
│       ├── default.tsx   # Returns null when no modal is open
│       └── (..)photo/    # INTERCEPTOR: Triggers when navigating to /photo/* from /feed
│           └── [id]/page.tsx # Renders the Modal UI
└── photo/
    └── [id]/page.tsx     # STANDALONE: Renders the full page (hard refresh)
```

## 2. Parallel Routes (Dashboards & Conditional UIs)

Parallel routes (`@folder`) allow you to render multiple pages simultaneously within the same layout, and manage their loading and error states independently.

```tsx
// ✅ ALWAYS: Parallel Route Layout (app/dashboard/layout.tsx)
export default function DashboardLayout({
  children, // The main page.tsx
  team,     // The @team/page.tsx
  analytics // The @analytics/page.tsx
}: {
  children: React.ReactNode;
  team: React.ReactNode;
  analytics: React.ReactNode;
}) {
  return (
    <div className="grid">
      <main>{children}</main>
      <aside>
        {team}
        {analytics}
      </aside>
    </div>
  );
}
```

**CRITICAL RULE (`default.tsx`)**: If the URL changes (e.g., the user clicks a link inside `@team` that navigates to `/dashboard/settings`), Next.js doesn't know what to render inside `@analytics` because it doesn't have a `settings` route. You MUST provide a `default.tsx` file inside every parallel route to act as a fallback, otherwise the app will crash with a 404.

## 3. Streaming UI (Progressive Rendering)

If a page takes 3 seconds to fetch data, the user should not stare at a blank white screen for 3 seconds.

- **`loading.tsx`**: Automatically wraps the `page.tsx` in a `<Suspense>` boundary. It streams the shell of the page instantly while the server finishes fetching the data.
- **Granular `<Suspense>`**: For massive pages, don't wait for the slowest query. Fetch fast data at the page level, and wrap slow components in their own Suspense boundaries.

```tsx
// ✅ ALWAYS: Granular Streaming for slow data
import { Suspense } from 'react';
import { SkeletonCard } from '@/components/ui/skeleton';
import { SlowProductRecommendations } from './SlowRecommendations';

export default function ProductPage({ params }) {
  // Fast query
  const product = await db.getProduct(params.id); 

  return (
    <article>
      <h1>{product.title}</h1>
      
      {/* 
        This boundary streams HTML instantly. 
        The server keeps the connection open and streams the Recommendations 
        when they finish 5 seconds later.
      */}
      <Suspense fallback={<SkeletonCard />}>
        <SlowProductRecommendations productId={product.id} />
      </Suspense>
    </article>
  );
}
```

## 4. Middleware (Edge Routing & Auth)

`middleware.ts` runs at the Edge, BEFORE a request is completed. It is used for Auth redirects, i18n routing, and manipulating request headers.

- **The Edge Constraint**: Middleware does NOT run in a Node.js environment. You cannot use heavy Node modules (like `bcrypt`, `pg`, or standard ORMs). 
- **The Matcher**: ALWAYS configure the `config.matcher` to ignore static files and images. If your middleware runs on every `.png` request, you will destroy your site's performance and skyrocket your hosting bill.

```typescript
// ✅ ALWAYS: Optimize Middleware Execution
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('auth-token');
  
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}

// ❌ NEVER let middleware run on static assets
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
```

## 5. Route Handlers (`route.ts`)

Route Handlers replace the old `/pages/api` directory. They allow you to create custom request handlers for a given route using the Web Request and Response APIs.

- **Mutations**: Do NOT use Route Handlers for form submissions. Use **Server Actions** instead.
- **When to use**: Use Route Handlers ONLY for Webhooks (e.g., Stripe events), OAuth callbacks, dynamic image generation (OG images), or public REST APIs consumed by third parties.

```typescript
// ✅ ALWAYS: Route Handlers for Webhooks
import { NextResponse } from 'next/server';
import { verifyStripeSignature } from '@/lib/stripe';

export async function POST(request: Request) {
  const payload = await request.text();
  const signature = request.headers.get('stripe-signature');
  
  try {
    const event = verifyStripeSignature(payload, signature);
    await processPayment(event);
    return NextResponse.json({ received: true });
  } catch (err) {
    return NextResponse.json({ error: 'Webhook Error' }, { status: 400 });
  }
}
```

---

**Execution Protocol**
1. **Dynamic Segments**: Use `[id]` for required params (e.g. `/users/1`). Use `[...slug]` for catch-all (e.g. `/docs/a/b/c`). Use `[[...slug]]` for optional catch-all (matches `/docs` as well).
2. **Route Groups `(folder)`**: Use route groups to bypass massive root layouts. If your `app/layout.tsx` has a huge navigation bar, put your marketing pages inside `app/(marketing)/layout.tsx` and your app inside `app/(app)/layout.tsx`. The URL will still be `/pricing`, ignoring the `(marketing)` folder name.
3. **Hard Navigation**: If you need to force a hard reload (bypassing the client-side router cache), use `window.location.href = '/path'` instead of `router.push('/path')`.
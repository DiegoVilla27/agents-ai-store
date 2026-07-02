---
name: next-core
description: The ultimate architectural standard for Next.js 15+ App Router, Server Components, Data Fetching, and Server Actions.
author: Diego Villanueva
trigger: When building Next.js applications, defining routes, fetching data, handling mutations, or optimizing SEO.
---

# Next.js 15 (App Router) Architecture

Next.js 15 represents the maturity of the App Router. The mental model has shifted entirely: **Everything is a Server Component by default**. The Server is the single source of truth for routing, data, and initial rendering. Client-side JavaScript is a premium resource only used when strict interactivity is required.

## 1. The App Router File System Strictness

The `app/` directory uses reserved filenames to automatically generate layouts, error boundaries, and suspense boundaries.

- `layout.tsx`: The UI shell that wraps the route and its children. It DOES NOT unmount on navigation (state is preserved).
- `page.tsx`: The unique UI for that specific route.
- `loading.tsx`: Automatically wraps the `page.tsx` in a React `<Suspense>` boundary.
- `error.tsx`: Automatically wraps the route in a React Error Boundary. MUST be a `"use client"` component.

```text
// ✅ ALWAYS: Advanced routing patterns
app/
├── (auth)/             # Route Group: Bypasses the URL path, grouping related routes
│   ├── login/page.tsx  # URL: /login (NOT /auth/login)
│   └── layout.tsx      # Applies ONLY to auth routes
├── dashboard/
│   ├── @modal/         # Parallel Route: Renders simultaneously with the dashboard page
│   ├── [teamId]/       # Dynamic Route: accessible via params.teamId
│   └── page.tsx
└── _components/        # Private Folder: Ignored by the router entirely
```

## 2. Server Components vs Client Components

- **Server Components (Default)**: They execute on the backend, send HTML to the browser, and send ZERO JavaScript to the client. They can be `async` and can talk directly to databases.
- **Client Components (`"use client"`)**: They run on both the server (for initial HTML) and the client (hydration). They are the only place you can use `useState`, `useEffect`, `onClick`, or Browser APIs (`window`).

```tsx
// ✅ ALWAYS: Push "use client" as far down the tree as possible
import { InteractiveButton } from './InteractiveButton'; // This is a "use client" file

// This is a Server Component (no directive needed)
export default async function ProductPage({ params }) {
  const product = await db.getProduct(params.id); // Direct DB access!

  return (
    <article>
      <h1>{product.title}</h1>
      {/* Pass data down to the interactive leaf node */}
      <InteractiveButton productId={product.id} />
    </article>
  );
}
```

## 3. Data Fetching & Caching (Next 15 Paradigm)

In Next 15, `fetch` requests are **NOT cached by default** anymore (unlike Next 14). You must be explicit about caching strategies to avoid blowing up your backend.

- **`cache: 'force-cache'`**: Static data (like a blog post).
- **`next: { revalidate: 3600 }`**: Incremental Static Regeneration (ISR). Regenerates in the background every hour.
- **`next: { tags: ['products'] }`**: On-demand invalidation. The gold standard for enterprise apps.

```tsx
// ✅ ALWAYS: Be explicit with caching and tags
export async function getProducts() {
  const res = await fetch('https://api.example.com/products', {
    next: { 
      tags: ['products-list'], // Can be invalidated by Server Actions
      revalidate: 86400 // Cache for 24 hours as a fallback
    }
  });
  return res.json();
}
```

## 4. Server Actions (Mutations)

Do NOT create `app/api/.../route.ts` files just to handle a form submission. Next.js 15 uses **Server Actions**, which are RPC (Remote Procedure Call) functions executed on the server but called directly from the client.

- **`"use server"`**: Marks the function to be executed securely on the backend.
- **`revalidateTag` / `revalidatePath`**: Instantly purges the Next.js cache so the user sees fresh data immediately after a mutation.

```tsx
// ✅ ALWAYS: Server Actions for mutations (actions.ts)
"use server";
import { revalidateTag } from 'next/cache';
import { redirect } from 'next/navigation';

export async function createPost(formData: FormData) {
  const title = formData.get('title');
  
  await db.insertPost({ title });
  
  // 1. Purge the cache for the posts list
  revalidateTag('posts-list');
  // 2. Redirect the user back to the list
  redirect('/posts');
}
```

## 5. Modern Forms (`useActionState`)

Combine Server Actions with React 19's `useActionState` to handle form validation errors and loading states without any `useState` or `useEffect`.

```tsx
// ✅ ALWAYS: useActionState for form handling
"use client";
import { useActionState } from 'react';
import { createPost } from './actions';

export function PostForm() {
  // state will contain errors if the Server Action fails
  const [state, formAction, isPending] = useActionState(createPost, null);

  return (
    <form action={formAction}>
      <input name="title" required />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Saving...' : 'Save'}
      </button>
      {state?.error && <p className="text-red-500">{state.error}</p>}
    </form>
  );
}
```

## 6. SEO & Metadata API

Never use raw `<head>` or `<title>` tags. Next.js manages the `<head>` automatically to avoid streaming hydration mismatches.

```tsx
// ✅ ALWAYS: Use the Metadata API
import type { Metadata } from 'next';

// Static Metadata (in layout.tsx or page.tsx)
export const metadata: Metadata = {
  title: 'My Enterprise App',
  description: 'A highly scalable Next.js application.',
};

// Dynamic Metadata (e.g., for [id]/page.tsx)
export async function generateMetadata({ params }): Promise<Metadata> {
  const post = await getPost(params.id);
  return { title: post.title };
}
```

---

**Execution Protocol**
1. **Never leak secrets**: If a file is marked `"use client"`, any environment variable it uses MUST be prefixed with `NEXT_PUBLIC_`. If it is a server-only variable (like `DATABASE_URL`), it will be undefined on the client.
2. **`server-only` package**: To prevent accidental leakage of sensitive backend logic to the client, ALWAYS import the `server-only` package at the top of files that talk to databases or use secret keys. If a developer accidentally imports it into a `"use client"` file, the build will crash, saving your app from a security breach.
3. **Link Prefetching**: By default, `<Link href="...">` prefetchs the route in the background as soon as it enters the viewport. If you have hundreds of links (e.g., a massive table), set `prefetch={false}` to avoid DDOS'ing your own server.
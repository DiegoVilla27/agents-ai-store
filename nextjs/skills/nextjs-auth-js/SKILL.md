---
name: nextjs-auth-js
description: The ultimate architectural standard for authentication, session management, route protection, and RBAC using Auth.js (NextAuth v5) in Next.js 15.
author: Diego Villanueva
trigger: When implementing authentication, configuring OAuth providers, protecting routes, or managing user sessions.
---

# Auth.js (NextAuth v5) Architecture

Auth.js (formerly NextAuth.js) v5 represents a massive architectural shift to support the Next.js App Router and Edge environments. It moves away from the heavy reliance on React Context (`SessionProvider`) and embraces Server Components and Server Actions.

## 1. The Core Setup (The Split Config Pattern)

Many database adapters (like Prisma or standard Postgres drivers) rely on Node.js APIs and will crash if run inside Next.js Edge Middleware. You MUST split your Auth.js configuration into two files.

- `auth.config.ts`: Contains providers and callbacks (runs on the Edge).
- `auth.ts`: Combines the config with your Database Adapter (runs only in Node).

```typescript
// ✅ ALWAYS: Step 1 - Edge-compatible config (auth.config.ts)
import type { NextAuthConfig } from 'next-auth';
import GitHub from 'next-auth/providers/github';

export default {
  providers: [GitHub],
  callbacks: {
    // Control access via middleware here
    authorized({ auth, request: { nextUrl } }) {
      const isLoggedIn = !!auth?.user;
      const isOnDashboard = nextUrl.pathname.startsWith('/dashboard');
      if (isOnDashboard) return isLoggedIn;
      return true;
    },
  },
} satisfies NextAuthConfig;
```

```typescript
// ✅ ALWAYS: Step 2 - Node-only config with Adapter (auth.ts)
import NextAuth from 'next-auth';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { db } from '@/lib/db';
import authConfig from './auth.config';

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(db),
  session: { strategy: 'jwt' }, // Required if using credentials or middleware
  ...authConfig,
});
```

## 2. Server-Side Authentication (The `auth()` Function)

In Next.js 15, you must authenticate users on the server whenever possible. The universal `auth()` function replaces the old, cumbersome `getServerSession`.

- **Server Components & Actions**: Use `auth()` directly. It is deduplicated automatically.

```tsx
// ✅ ALWAYS: Secure Server Actions
"use server";
import { auth } from '@/auth';

export async function deleteUser(id: string) {
  const session = await auth();
  if (!session?.user || session.user.role !== 'admin') {
    throw new Error('Unauthorized');
  }
  await db.deleteUser(id);
}
```

```tsx
// ✅ ALWAYS: Read session in Server Components
import { auth, signOut } from '@/auth';

export default async function Navbar() {
  const session = await auth();

  return (
    <nav>
      {session ? (
        <form action={async () => { "use server"; await signOut(); }}>
          <button>Sign Out {session.user.name}</button>
        </form>
      ) : (
        <a href="/login">Sign In</a>
      )}
    </nav>
  );
}
```

## 3. Protecting Routes via Middleware

Never protect standard pages by putting `if (!session) redirect()` inside every single `page.tsx`. This causes a flash of unauthenticated content and is impossible to maintain.

- Use Edge Middleware to protect routes instantly before the server even starts rendering the page.

```typescript
// ✅ ALWAYS: Global route protection via Middleware (middleware.ts)
import NextAuth from 'next-auth';
import authConfig from './auth.config';

// Initialize NextAuth with the Edge-compatible config
export const { auth: middleware } = NextAuth(authConfig);

export const config = {
  // Protects all routes except api, static files, and images
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

## 4. Enriching the Session Object (Callbacks)

By default, Auth.js only returns `name`, `email`, and `image` to the client for security reasons. To pass custom data (like the user's `id` or `role`), you must map it through the JWT and Session callbacks.

```typescript
// ✅ ALWAYS: Map custom fields through JWT to Session
callbacks: {
  async jwt({ token, user }) {
    // 'user' is only passed the first time the token is created
    if (user) {
      token.id = user.id;
      token.role = user.role;
    }
    return token;
  },
  async session({ session, token }) {
    // Inject the token data into the public session
    if (token && session.user) {
      session.user.id = token.id as string;
      session.user.role = token.role as string;
    }
    return session;
  }
}
```

## 5. Strict TypeScript Definitions

If you add custom fields like `role` to the session, TypeScript will complain. You MUST augment the NextAuth types.

```typescript
// ✅ ALWAYS: Augment Types (types/next-auth.d.ts)
import { DefaultSession } from 'next-auth';

declare module 'next-auth' {
  interface Session {
    user: {
      id: string;
      role: 'admin' | 'user';
    } & DefaultSession['user'];
  }

  interface User {
    role: 'admin' | 'user';
  }
}
```

---

**Execution Protocol**
1. **Client Components**: If you *must* access the session inside a `"use client"` component, use the `useSession()` hook. However, prefer passing session data down from a Server Component as props to avoid wrapping the whole app in `<SessionProvider>`.
2. **Environment Variables**: Auth.js v5 automatically infers `AUTH_URL` and `AUTH_SECRET` if they are defined in `.env`. Do not manually pass them into the `NextAuth` config object unless you have a custom multi-tenant setup.
3. **Credentials Provider Warning**: Avoid the Credentials provider if possible. If you use it, you are responsible for hashing passwords (e.g., `bcryptjs`), and you MUST set `session: { strategy: 'jwt' }` because Auth.js refuses to save passwords in a database session table.

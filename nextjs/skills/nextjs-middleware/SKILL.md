---
name: nextjs-middleware
description: The ultimate architectural standard for Next.js Edge Middleware, global request interception, security headers, and routing logic.
author: Diego Villanueva
trigger: When configuring middleware.ts, implementing global auth guards, setting up A/B testing, or manipulating request/response headers.
---

# Next.js Edge Middleware Architecture

Middleware in Next.js is not a standard Node.js Express middleware. It runs on the **Edge Runtime** (a stripped-down V8 isolate). It executes before a request is completed, making it the perfect place for global authentication, i18n redirects, and A/B testing. 

However, because it runs on the Edge, it is the #1 source of deployment crashes if not understood correctly.

## 1. The Edge Runtime Constraint (CRITICAL)

The Edge Runtime does NOT support standard Node.js APIs (`fs`, `crypto`, `path`) or native C++ addons.

- **❌ NEVER** import `bcrypt`, `pg`, or standard database ORMs into `middleware.ts`. It will crash during the build or at runtime.
- **✅ ALWAYS** use Edge-compatible libraries. If you need to verify a JWT, use `jose` instead of `jsonwebtoken`. If you need database access, use an HTTP-based driver (like Upstash Redis or Prisma Accelerate via fetch).

```typescript
// ❌ ATROCIOUS: This will crash the Edge Runtime
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

// ✅ ALWAYS: Edge-compatible token verification
import { jwtVerify } from 'jose';

export async function middleware(req: NextRequest) {
  const token = req.cookies.get('token')?.value;
  if (token) {
    const secret = new TextEncoder().encode(process.env.JWT_SECRET);
    const { payload } = await jwtVerify(token, secret);
  }
}
```

## 2. Matcher Optimization (Saving Server Costs)

Middleware runs on *every single request* by default. If you don't filter it, your middleware will execute hundreds of times per page load to serve every `.png`, `.css`, and `.js` file. This will destroy your latency and skyrocket your hosting bill (e.g., Vercel Edge Function limits).

```typescript
// ✅ ALWAYS: Strictly filter static assets and APIs
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files (e.g., .svg, .png)
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\.png$).*)',
  ],
};
```

## 3. Redirect vs Rewrite vs Next

You must understand the difference in routing mutations:

- **`NextResponse.redirect()`**: Changes the URL in the browser. Use for Auth guards (unauthenticated user trying to access `/dashboard` -> redirects to `/login`).
- **`NextResponse.rewrite()`**: Keeps the URL the same in the browser, but serves content from a different path. Use for A/B testing or legacy URL masking.
- **`NextResponse.next()`**: Allows the request to proceed normally.

```typescript
export function middleware(req: NextRequest) {
  const url = req.nextUrl;

  // REDIRECT: User sees /login in their browser bar
  if (!isAuthenticated && url.pathname.startsWith('/admin')) {
    return NextResponse.redirect(new URL('/login', req.url));
  }

  // REWRITE: User sees /home, but we serve /home-variant-b
  if (url.pathname === '/home' && abTestCookie === 'B') {
    return NextResponse.rewrite(new URL('/home-variant-b', req.url));
  }
}
```

## 4. Header Manipulation (The RSC Communication Hack)

Server Components (RSC) cannot easily access the current URL path directly. The standard architectural pattern is to read the URL in the Middleware and pass it down via custom headers.

```typescript
// ✅ ALWAYS: Inject data for Server Components via headers
export function middleware(req: NextRequest) {
  const requestHeaders = new Headers(req.headers);
  
  // Inject the current pathname
  requestHeaders.set('x-url-pathname', req.nextUrl.pathname);

  // Pass it forward
  return NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });
}
```
*In your Server Component: `const path = headers().get('x-url-pathname');`*

## 5. Security Headers (CSP)

Middleware is the best place to inject strict Content Security Policy (CSP) headers globally, protecting your app from XSS attacks.

```typescript
// ✅ ALWAYS: Inject Security Headers globally
export function middleware(req: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  const cspHeader = `
    default-src 'self';
    script-src 'self' 'nonce-${nonce}' 'strict-dynamic';
    style-src 'self' 'unsafe-inline';
    img-src 'self' blob: data:;
  `.replace(/\s{2,}/g, ' ').trim();

  const response = NextResponse.next();
  response.headers.set('Content-Security-Policy', cspHeader);
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  
  return response;
}
```

## 6. Middleware Composition (The Chain Pattern)

Next.js only allows ONE `middleware.ts` file. If you have Auth logic, i18n logic, and A/B Testing logic, do NOT write a 500-line spaghetti function. Use a compose/chaining pattern.

```typescript
// ✅ ALWAYS: Chain independent middleware functions
export function middleware(req: NextRequest) {
  const authResponse = authMiddleware(req);
  if (authResponse) return authResponse; // Halt and redirect if auth fails

  const i18nResponse = intlMiddleware(req);
  if (i18nResponse) return i18nResponse;

  return NextResponse.next();
}
```

---

**Execution Protocol**
1. **Never throw errors**: If your middleware throws an unhandled error, the entire site will crash with a 500 error for that user. Always wrap external Edge calls (like Upstash) in `try/catch` and fallback gracefully to `NextResponse.next()`.
2. **Speed is everything**: Middleware adds latency to the initial HTML request. If your middleware takes 100ms to execute, your TTFB (Time to First Byte) increases by 100ms. Keep logic minimal, avoid external fetch calls if possible, and rely on Edge-optimized databases if needed.

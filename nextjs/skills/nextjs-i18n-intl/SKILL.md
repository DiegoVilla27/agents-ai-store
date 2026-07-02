---
name: nextjs-i18n-intl
description: The ultimate architectural standard for App Router Internationalization (i18n), type-safe translations, localized routing, and static rendering using next-intl.
author: Diego Villanueva
trigger: When implementing multi-language support, routing with locales, formatting dates/currencies, or defining translation keys.
---

# Next.js i18n Architecture (`next-intl`)

Internationalization in the Next.js App Router is vastly different from the Pages Router. There is no built-in i18n routing. `next-intl` is the enterprise standard for bridging this gap, providing type-safe translations, localized routing, and seamless Server Component integration.

## 1. The Core Paradigm: The URL is the Source of Truth

Never rely exclusively on a cookie or React Context to determine the active language. The URL must ALWAYS dictate the language (e.g., `/es/about` vs `/en/about`).

- **The `[locale]` segment**: Your entire application (except `api` routes) must be nested inside a dynamic `app/[locale]/` directory.

```text
// ✅ ALWAYS: Directory structure for i18n
app/
├── [locale]/
│   ├── layout.tsx       # Receives { params: { locale } }
│   ├── page.tsx         # The localized home page
│   └── about/page.tsx   # /es/about or /en/about
├── api/                 # API routes do not need localization
└── middleware.ts        # Intercepts /about and redirects to /[locale]/about
```

## 2. Edge Middleware (Locale Detection)

When a user visits `https://yoursite.com/dashboard`, the middleware must detect their preferred language (via the `Accept-Language` header or a saved cookie) and redirect them to `https://yoursite.com/en/dashboard`.

```typescript
// ✅ ALWAYS: Configure next-intl middleware
import createMiddleware from 'next-intl/middleware';

export default createMiddleware({
  locales: ['en', 'es', 'fr'],
  defaultLocale: 'en',
  // Options: 'always' (forces /en/path) or 'as-needed' (hides default locale /path)
  localePrefix: 'always' 
});

export const config = {
  // Skip all internal paths, static files, and APIs
  matcher: ['/((?!api|_next|.*\\..*).*)']
};
```

## 3. Server Components vs Client Components

You must use the correct API depending on where the component renders.

- **Server Components (`getTranslations`)**: It is an `async` function. It fetches translations on the server without sending the dictionary to the client.
- **Client Components (`useTranslations`)**: It is a synchronous React hook. The translations are passed via the `<NextIntlClientProvider>`.

```tsx
// ✅ ALWAYS: Server Components (async)
import { getTranslations } from 'next-intl/server';

export default async function ProfilePage() {
  const t = await getTranslations('Profile');
  return <h1>{t('title')}</h1>; // Renders "My Profile"
}
```

```tsx
// ✅ ALWAYS: Client Components (hook)
"use client";
import { useTranslations } from 'next-intl';

export function InteractiveButton() {
  const t = useTranslations('Actions');
  return <button onClick={() => alert()}>{t('save')}</button>;
}
```

## 4. Localized Navigation (The Wrapper)

If a user is on `/es/dashboard` and clicks a `<Link href="/settings">`, they should go to `/es/settings`, not `/settings` (which would trigger a middleware redirect).

- **NEVER use `next/link` or `next/navigation` directly.**
- **ALWAYS use the `next-intl/navigation` wrappers.**

```tsx
// ✅ ALWAYS: Create a localized navigation file (navigation.ts)
import { createSharedPathnamesNavigation } from 'next-intl/navigation';

export const locales = ['en', 'es', 'fr'] as const;
export const { Link, redirect, usePathname, useRouter } = createSharedPathnamesNavigation({ locales });

// In your component:
// import { Link } from '@/navigation'; 
// <Link href="/settings">Settings</Link> -> automatically outputs href="/es/settings"
```

## 5. Type-Safe Translations (TypeScript)

A missing translation key should break the build, not crash the app in production. You MUST provide a global TypeScript definition for your translation dictionaries.

```typescript
// ✅ ALWAYS: Define global types (global.d.ts)
type Messages = typeof import('./messages/en.json');

declare interface IntlMessages extends Messages {}
```
*If you type `t('nonExistentKey')`, TypeScript will now throw an error.*

## 6. Static Rendering (SSG) Optimization

By default, any page inside `app/[locale]/` becomes dynamically rendered (SSR) because `[locale]` is a dynamic URL parameter. To keep your pages static and blazingly fast, you MUST use `unstable_setRequestLocale` and `generateStaticParams`.

```tsx
// ✅ ALWAYS: Opt back into static rendering
import { unstable_setRequestLocale } from 'next-intl/server';

export function generateStaticParams() {
  return [{ locale: 'en' }, { locale: 'es' }];
}

export default function AboutPage({ params: { locale } }) {
  // Tells Next.js to statically generate this page for each locale
  unstable_setRequestLocale(locale);
  
  return <div>...</div>;
}
```

## 7. Rich Text and Plurals (ICU Format)

Do not concatenate strings (e.g., `t('hello') + ' ' + name + '!'`). Different languages have different sentence structures. Use the ICU MessageFormat syntax.

```json
// en.json
{
  "Cart": {
    "items": "You have {count, plural, =0 {no items} one {1 item} other {# items}} in your cart.",
    "boldText": "This is <bold>important</bold> text."
  }
}
```

```tsx
// ✅ ALWAYS: Use rich text and variables in translations
const t = useTranslations('Cart');

// "You have 3 items in your cart."
<p>{t('items', { count: 3 })}</p> 

// "This is <strong>important</strong> text."
<p>{t.rich('boldText', { bold: (chunks) => <strong>{chunks}</strong> })}</p>
```

---

**Execution Protocol**
1. **Client Provider Scope**: Do NOT pass the entire `messages.json` object to the `<NextIntlClientProvider>` in your root layout. This forces the browser to download translations for the entire app on the first load. Pass only the namespaces you actually need in Client Components.
2. **Date and Currency Formatting**: Never use raw JavaScript `Intl.DateTimeFormat`. Always use `next-intl`'s `format.dateTime` and `format.number` to ensure the formatting perfectly matches the current URL locale without hydration mismatches.

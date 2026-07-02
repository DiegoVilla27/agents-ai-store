---
name: nextjs-seo-metadata
description: The ultimate architectural standard for Search Engine Optimization, Dynamic Metadata, Structured Data (JSON-LD), and OpenGraph generation in Next.js 15.
author: Diego Villanueva
trigger: When optimizing pages for SEO, managing social share cards, defining sitemaps, or creating structured data.
---

# Next.js 15 SEO & Metadata Architecture

Next.js 15 App Router completely removes the legacy `next/head` component. Metadata is now strictly handled via exported `metadata` objects and `generateMetadata` functions on the server. This guarantees that web crawlers receive a fully populated `<head>` instantly, without waiting for client-side JavaScript hydration.

## 1. The Death of `<Head>` (Static Metadata)

You must never attempt to inject `<title>` or `<meta>` tags directly into the JSX of your layout or page. You must export a `Metadata` object.

```tsx
// ✅ ALWAYS: Define base metadata in the root layout (app/layout.tsx)
import type { Metadata } from 'next';

export const metadata: Metadata = {
  // The %s is replaced by the specific page's title
  title: {
    template: '%s | Acme Enterprise',
    default: 'Acme Enterprise - The Future of B2B',
  },
  description: 'Acme provides industry-leading B2B solutions.',
  metadataBase: new URL('https://acme.com'), // Required for relative OG image URLs
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://acme.com',
    siteName: 'Acme Enterprise',
    images: [{ url: '/og-default.jpg', width: 1200, height: 630 }],
  },
  twitter: {
    card: 'summary_large_image',
    site: '@acmecorp',
  },
};
```
*If a child page exports `title: 'Pricing'`, the final browser title will be "Pricing | Acme Enterprise".*

## 2. Dynamic Metadata (`generateMetadata`)

For dynamic routes (e.g., `/products/[id]`), the metadata depends on external data. Use the async `generateMetadata` function.

**CRITICAL PERFORMANCE RULE**: You will fetch the product in `generateMetadata` and then fetch it AGAIN in the `Page` component. This is expected and correct. Next.js automatically memoizes identical `fetch` requests during the render pass, so the database/API is only hit ONCE.

```tsx
// ✅ ALWAYS: Generate dynamic SEO tags for dynamic routes
import type { Metadata, ResolvingMetadata } from 'next';

type Props = { params: { id: string } };

export async function generateMetadata(
  { params }: Props,
  parent: ResolvingMetadata
): Promise<Metadata> {
  const product = await fetchProduct(params.id); // Deduplicated automatically!
  
  // Optionally read the parent metadata to merge images
  const previousImages = (await parent).openGraph?.images || [];

  return {
    title: product.name,
    description: product.shortSummary,
    openGraph: {
      images: [product.coverImageUrl, ...previousImages],
    },
    alternates: {
      canonical: `/products/${product.slug}`, // Prevent duplicate content SEO penalties
    },
  };
}

export default async function ProductPage({ params }: Props) {
  const product = await fetchProduct(params.id); // Does NOT trigger a second network request
  return <h1>{product.name}</h1>;
}
```

## 3. Structured Data (JSON-LD)

To get rich snippets in Google Search (like star ratings, price, or recipe cards), you MUST inject JSON-LD. Never use outdated Microdata attributes in your HTML.

```tsx
// ✅ ALWAYS: Inject Schema.org JSON-LD in Server Components
export default async function ProductPage({ params }) {
  const product = await getProduct(params.id);

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    image: product.image,
    description: product.description,
    offers: {
      '@type': 'Offer',
      price: product.price,
      priceCurrency: 'USD',
      availability: product.inStock ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
    },
  };

  return (
    <section>
      {/* Inject JSON-LD safely into the DOM */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <h1>{product.name}</h1>
    </section>
  );
}
```

## 4. Programmatic Sitemaps (`sitemap.ts`)

Never maintain a static `sitemap.xml` file for a dynamic site. Next.js natively supports `sitemap.ts` files that dynamically generate the XML based on your database.

```typescript
// ✅ ALWAYS: Generate massive sitemaps programmatically (app/sitemap.ts)
import { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const products = await db.product.findMany({ select: { slug: true, updatedAt: true } });
  
  const productUrls = products.map((product) => ({
    url: `https://acme.com/products/${product.slug}`,
    lastModified: product.updatedAt,
    changeFrequency: 'weekly' as const,
    priority: 0.8,
  }));

  return [
    {
      url: 'https://acme.com',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    ...productUrls,
  ];
}
```

## 5. Dynamic OpenGraph Images (`@vercel/og`)

Do not design 500 different sharing images manually. Use Next.js ImageResponse to generate them on the fly using HTML and CSS.

```tsx
// ✅ ALWAYS: Generate OG Images dynamically (app/og/route.tsx)
import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const title = searchParams.get('title') || 'Default Title';

  return new ImageResponse(
    (
      <div style={{ display: 'flex', background: 'black', width: '100%', height: '100%', color: 'white', alignItems: 'center', justifyContent: 'center', fontSize: 128, fontWeight: 'bold' }}>
        {title}
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
```

---

**Execution Protocol**
1. **Robots.txt**: Create `app/robots.ts` alongside your `sitemap.ts` to dynamically dictate crawling rules based on your environment (e.g., `Disallow: /` in staging, `Allow: /` in production).
2. **Canonical URLs**: Always define canonical URLs in `generateMetadata` for pages that might be accessed via multiple paths (e.g., parameterized URLs like `?sort=price` or `?ref=twitter`) to prevent Google from penalizing you for duplicate content.
3. **No Index**: For private routes (like User Dashboards or Admin Panels), ensure you export `metadata = { robots: { index: false, follow: false } }`.

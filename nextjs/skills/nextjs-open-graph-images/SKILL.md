---
name: nextjs-open-graph-images
description: The ultimate architectural standard for Dynamic Open Graph & Twitter Social Image Generation in Next.js with @vercel/og, ImageResponse, Edge Runtime, and Satori JSX Canvas.
author: Diego Villanueva
trigger: When generating dynamic social share preview cards, configuring opengraph-image.tsx or twitter-image.tsx, using ImageResponse in Next.js, or styling edge images with Tailwind/Satori.
---

# Enterprise Next.js Dynamic Open Graph & Social Cards Architecture

Hardcoded static social preview images kill click-through rates (CTR) on Twitter, LinkedIn, and Slack. Next.js natively generates **Dynamic Open Graph Images** on demand at the Edge using **`ImageResponse` (`@vercel/og`)** and JSX/CSS.

---

## 1. Dynamic Route OpenGraph Generator (`opengraph-image.tsx`)

By placing `opengraph-image.tsx` inside a dynamic route segment (e.g. `src/app/blog/[slug]/opengraph-image.tsx`), Next.js automatically injects `<meta property="og:image">` pointing to the dynamically generated SVG/PNG.

```tsx
// src/app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from 'next/og';
import { getPostBySlug } from '@/features/blog/services';

// 1. Force Edge Runtime for instant sub-50ms image rendering
export const runtime = 'edge';

// 2. Image metadata specifications
export const alt = 'Article Social Preview';
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = 'image/png';

interface OpenGraphProps {
  params: Promise<{ slug: string }>;
}

export default async function Image({ params }: OpenGraphProps) {
  const { slug } = await params;
  const post = await getPostBySlug(slug);

  return new ImageResponse(
    (
      <div
        style={{
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'flex-start',
          justifyContent: 'space-between',
          backgroundColor: '#09090b',
          backgroundImage:
            'radial-gradient(circle at 25px 25px, #27272a 2%, transparent 0%), radial-gradient(circle at 75px 75px, #27272a 2%, transparent 0%)',
          backgroundSize: '100px 100px',
          padding: '80px',
          fontFamily: 'sans-serif',
        }}
      >
        {/* Brand Tag */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            backgroundColor: '#18181b',
            border: '1px solid #3f3f46',
            borderRadius: '9999px',
            padding: '10px 24px',
            color: '#a1a1aa',
            fontSize: 20,
            fontWeight: 600,
          }}
        >
          🌌 Enterprise Architecture Hub
        </div>

        {/* Dynamic Title */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div
            style={{
              fontSize: 64,
              fontWeight: 800,
              color: '#ffffff',
              lineHeight: 1.1,
              letterSpacing: '-0.02em',
              maxWidth: '1000px',
            }}
          >
            {post.title}
          </div>
          <div
            style={{
              fontSize: 28,
              color: '#71717a',
              maxWidth: '900px',
            }}
          >
            {post.summary}
          </div>
        </div>

        {/* Author / Metadata Footer */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            width: '100%',
            borderTop: '1px solid #27272a',
            paddingTop: '32px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{ color: '#ffffff', fontSize: 24, fontWeight: 700 }}>
              {post.authorName}
            </div>
            <div style={{ color: '#52525b', fontSize: 24 }}>•</div>
            <div style={{ color: '#a1a1aa', fontSize: 22 }}>{post.readTimeMinutes} min read</div>
          </div>
          <div style={{ color: '#38bdf8', fontSize: 22, fontWeight: 600 }}>
            enterprise.dev
          </div>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}
```

---

## 2. Reusing the Same Generator for Twitter Cards (`twitter-image.tsx`)

Re-export the OpenGraph image directly for Twitter cards:

```tsx
// src/app/blog/[slug]/twitter-image.tsx
export { default, size, contentType, runtime, alt } from './opengraph-image';
```

---

**Execution Protocol**
1. **Always export `runtime = 'edge'`**: Leverages WebAssembly and Vercel Edge compute for instant rendering.
2. **Standard 1200x630 dimensions**: Guarantees crisp rendering across Facebook, Twitter Large Cards, and LinkedIn feeds.
3. **Use Flexbox styling**: Satori (the underlying SVG engine) uses CSS Flexbox; grid layouts are not supported.
4. **Cache generated images automatically**: Edge responses are cached by the CDN based on the route URL.

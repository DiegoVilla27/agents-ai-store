---
name: nextjs-web-vitals-analytics
description: The ultimate architectural standard for Next.js Core Web Vitals Optimization (INP, LCP, CLS), next/font Zero-Layout Shift, next/image AVIF Pipelines, and Speed Insights.
author: Diego Villanueva
trigger: When optimizing Core Web Vitals in Next.js, improving Google Lighthouse scores, eliminating layout shifts (CLS), setting up next/font or next/image pipelines, or tracking INP.
---

# Enterprise Next.js Core Web Vitals Optimization

Google Search ranking explicitly penalizes slow, shifting websites. An Enterprise Next.js Architect ensures 100/100 Lighthouse performance, sub-1.2s **Largest Contentful Paint (LCP)**, sub-100ms **Interaction to Next Paint (INP)**, and zero **Cumulative Layout Shift (CLS = 0)**.

---

## 1. Zero-Layout Shift Fonts with `next/font`

**❌ NEVER** link external Google Fonts via `<link href="https://fonts.googleapis.com...">` in HTML. It causes Flash of Unstyled Text (FOUT) and layout shifts.
**✅ ALWAYS** use **`next/font`** to download font files at build time and self-host them with zero layout shift.

```tsx
// src/app/fonts.ts
import { Inter, Plus_Jakarta_Sans } from 'next/font/google';

export const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});

export const jakartaSans = Plus_Jakarta_Sans({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-heading',
});
```

```tsx
// src/app/layout.tsx
import { inter, jakartaSans } from './fonts';
import './globals.css';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${jakartaSans.variable}`}>
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
```

---

## 2. High-Performance Media Pipeline with `next/image`

### Rules for Perfect Image LCP:
1. **The `priority` Prop**: ALWAYS add `priority` to the primary above-the-fold Hero image. This disables lazy loading and emits a `<link rel="preload">` in the HTML head.
2. **Modern Format Negotiation**: Configure AVIF and WebP in `next.config.ts`.
3. **Explicit Dimensions**: Always provide `width` and `height` or `fill` with `sizes` to reserve layout space (CLS = 0).

```typescript
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  images: {
    formats: ['image/avif', 'image/webp'],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'assets.enterprise.com',
      },
    ],
  },
};

export default nextConfig;
```

```tsx
// src/components/hero-banner.tsx
import Image from 'next/image';

export function HeroBanner() {
  return (
    <div className="relative h-[500px] w-full overflow-hidden rounded-3xl">
      <Image
        src="https://assets.enterprise.com/hero.jpg"
        alt="Enterprise Cloud Architecture"
        fill
        priority // Preloads immediately for sub-second LCP!
        sizes="(max-width: 768px) 100vw, (max-width: 1200px) 80vw, 1200px"
        className="object-cover"
      />
    </div>
  );
}
```

---

## 3. Real-Time Web Vitals Telemetry (`useReportWebVitals`)

```tsx
// src/app/_components/web-vitals.tsx
'use client';

import { useReportWebVitals } from 'next/web-vitals';

export function WebVitalsReporter() {
  useReportWebVitals((metric) => {
    // Metric names: FCP, LCP, CLS, FID, TTFB, INP
    if (process.env.NODE_ENV === 'production') {
      const body = JSON.stringify(metric);
      const url = '/api/telemetry/vitals';

      // Send via non-blocking Beacon API
      if (navigator.sendBeacon) {
        navigator.sendBeacon(url, body);
      } else {
        fetch(url, { body, method: 'POST', keepalive: true });
      }
    }
  });

  return null;
}
```

---

## 4. Third-Party Script Optimization (`next/script`)

```tsx
import Script from 'next/script';

// Offload heavy Google Analytics / Tag Manager to run after page is interactive
<Script
  src="https://www.googletagmanager.com/gtag/js?id=G-XXXXX"
  strategy="afterInteractive" // 'beforeInteractive' | 'afterInteractive' | 'lazyOnload' | 'worker'
/>
```

---

**Execution Protocol**
1. **Always add `priority` to above-the-fold images**: Drastically reduces LCP.
2. **Never use standard `<img>` tags**: Always use `next/image` to prevent uncompressed PNG/JPEG delivery.
3. **Use `strategy="lazyOnload"` for chat widgets and secondary scripts**: Prevents blocking main thread INP responsiveness.
4. **Self-host fonts via `next/font`**: Eliminates external font DNS lookups and layout shifting.

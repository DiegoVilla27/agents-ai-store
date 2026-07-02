---
name: web-performance
description: A senior architect's compendium for achieving perfect Core Web Vitals, sub-second loads, and 60fps rendering in modern web applications.
author: Diego Villanueva
trigger: When optimizing page load speed, analyzing Core Web Vitals (LCP, CLS, INP), configuring bundlers, or debugging main-thread blocking.
---

# Web Performance & Core Web Vitals Mastery

You are the guardian of user retention. Every millisecond counts. Performance is not a feature you add at the end; it is a foundational architectural constraint. Your mandate is to achieve 90+ Lighthouse scores and, more importantly, stellar Field Data (CRUX) metrics for real users on slow networks and mid-tier devices.

## 1. Core Web Vitals (The Unforgiving Metrics)

You must master the "Big Three":

- **LCP (Largest Contentful Paint)**: *Target < 2.5s*. Measures loading performance. It marks the point when the page's main content has likely loaded.
- **CLS (Cumulative Layout Shift)**: *Target < 0.1*. Measures visual stability. A zero-CLS score is the only acceptable score.
- **INP (Interaction to Next Paint)**: *Target < 200ms*. Measures responsiveness. Replaces FID. It measures the latency of every tap, click, or keyboard interaction.

## 2. Decimating LCP (Loading Speed)

The LCP element (usually a Hero image or an `<h1>`) must be the browser's highest priority.

- **`fetchpriority="high"`**: Explicitly tell the browser to download the hero image immediately.
- **NEVER Lazy-Load Above-the-Fold**: Using `loading="lazy"` on an LCP image is an architectural failure. Only lazy-load images below the fold.
- **Preload Critical Assets**: Use `<link rel="preload">` for late-discovered critical resources (like Web Fonts or background images defined in CSS).
- **Server-Side Rendering (SSR) / Static Site Generation (SSG)**: For content-heavy pages, ship pre-rendered HTML to reduce the time the browser spends parsing JS before rendering the LCP text.

## 3. Annihilating CLS (Visual Stability)

Elements shifting while the user reads or clicks is a catastrophic UX failure.

- **Explicit Dimensions**: ALWAYS provide `width` and `height` attributes to `<img>` and `<video>` tags so the browser can calculate the aspect ratio and reserve space.
- **Dynamic Content Placeholders**: If fetching an ad, a banner, or a dynamic list, reserve the space using `min-height` or CSS `aspect-ratio` on the parent container.
- **Web Fonts**: Use `font-display: swap` or `font-display: optional` to prevent invisible text flashes (FOIT). Consider `size-adjust` to match fallback font metrics with web font metrics.

## 4. Conquering INP (Main Thread Responsiveness)

The Main Thread is single-lane traffic. Do not block it.

- **Yield to the Main Thread**: Break up long, synchronous JavaScript tasks (anything > 50ms). Use `setTimeout(..., 0)` or the newer `scheduler.yield()` API to let the browser process user inputs between heavy calculations.
- **Web Workers**: Offload heavy computations (data parsing, cryptography, complex filtering) to a separate thread via Web Workers.
- **Debounce & Throttle**: Never bind expensive DOM updates directly to `scroll`, `resize`, or `mousemove` events.
- **React Rendering Optimization**: Prevent wasteful re-renders. Use `memo`, `useMemo`, and `useCallback` judiciously. If a component tree takes 300ms to render, INP will fail.

## 5. Asset & Bundle Optimization

Ship less code, ship it faster.

- **Route-Based Code Splitting**: Never serve the Admin panel JS to a user on the Landing page. Use dynamic imports (`React.lazy()` or equivalent).
- **Component-Level Splitting**: Lazily load heavy, below-the-fold components (e.g., complex charts, mapping libraries, heavy modals).
- **Modern Formats**: Serve images in **WebP** or **AVIF**. Serve videos in **WebM/MP4**. Serve modern JavaScript (ES Modules) without legacy polyfills unless strictly necessary.
- **Tree-Shaking**: Ensure your bundler (Vite, Webpack, Rollup) is eliminating dead code. Avoid importing entire libraries (e.g., `import * as _ from 'lodash'`); import specifically what you need.

## 6. Resource Hints & The Critical Rendering Path

Control the browser's download queue.

- **Preconnect (`rel="preconnect"`)**: Establish early network connections to critical third-party domains (e.g., API servers, CDNs).
- **DNS-Prefetch (`rel="dns-prefetch"`)**: Cheaper fallback for domains used later in the page lifecycle.
- **Defer/Async Scripts**: Third-party scripts (Analytics, Chatbots) must NEVER block the parser. Use `defer` (executes after parsing, in order) or `async` (executes ASAP, no order).

## 7. Caching & Edge Delivery

- **Immutable Caching**: Hashed assets (`main-[hash].js`) must be cached aggressively (`Cache-Control: public, max-age=31536000, immutable`).
- **Edge CDNs**: Serve HTML and static assets as close to the user as possible (Cloudflare, Vercel Edge, AWS CloudFront).

---

**Execution Protocol**
1. **Lab Data is a Guide, Field Data is Truth**: Lighthouse scores are isolated "lab" tests. You must monitor Real User Monitoring (RUM) data (CrUX) to know your true metrics.
2. **Performance Budgets**: Enforce bundle size limits in CI. If a PR pushes the main bundle over 200KB (gzipped), the build must fail.
3. **No Third-Party Bloat**: Question every third-party SDK. A 500KB marketing script can instantly destroy a perfect performance score.

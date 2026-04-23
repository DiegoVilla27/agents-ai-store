---
name: web-performance
description: >
  Deep dive into Core Web Vitals and frontend optimization techniques.
  Trigger: When optimizing page speed, reducing bundle size, or fixing layout shifts (LCP, CLS, INP).
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Core Web Vitals (REQUIRED)

Achieve "Good" scores in the metrics that matter to Google and users.

| Metric | Target | Solution |
|--------|--------|----------|
| **LCP** (Largest Contentful Paint) | < 2.5s | Use `fetchpriority="high"`, optimize images. |
| **CLS** (Cumulative Layout Shift) | < 0.1 | Reserves space with `aspect-ratio` or fixed sizes. |
| **INP** (Interaction to Next Paint) | < 200ms | Yield to main thread, use `Web Workers` for heavy tasks. |

---

## Resource Loading (REQUIRED)

Tell the browser what is important before it even knows.

```html
<!-- ✅ ALWAYS: Preconnect and FetchPriority for LCP -->
<link rel="preconnect" href="https://api.myapp.com" />
<img src="hero.webp" fetchpriority="high" alt="Hero Image" />

<!-- ❌ NEVER: Loading="lazy" for above-the-fold content -->
<!-- Lazy loading the hero image is a common mistake that kills LCP. -->
```

---

## Bundle Optimization (REQUIRED)

Keep the initial payload small.

```typescript
// ✅ ALWAYS: Route-based code splitting
const AdminPanel = lazy(() => import("./AdminPanel"));

// ✅ ALWAYS: Tree-shaking and modern formats
// Use ES Modules and ensure 'sideEffects: false' in package.json.

// ❌ NEVER: Importing giant libraries for small features
// Avoid 'import { _ } from "lodash"'; use 'import debounce from "lodash/debounce"'.
```

---

## Execution Protocol (REQUIRED)

1. **Audit**: Run a Lighthouse/PageSpeed Insights report in "Mobile" mode.
2. **Prioritize**: Fix CLS first (it's often the easiest "win").
3. **Minimize**: Identify and remove unused JS/CSS using the "Coverage" tab in DevTools.
4. **Compress**: Use modern formats (WebP, AVIF) and Brotli/Gzip compression.

---

## Uncompromising Constraints

- **Mobile First**: Performance must be optimized for mid-range mobile devices on 4G, not just M3 MacBooks.
- **Zero CLS**: Any layout shift caused by dynamic content is considered a bug.
- **Critical Path**: Above-the-fold content must be interactive within the first 1.5s.

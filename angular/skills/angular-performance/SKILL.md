---
name: angular-performance
description: The ultimate architectural standard for Enterprise Angular Performance Zoneless Change Detection, NgOptimizedImage, esbuild/Vite Budgets, and Core Web Vitals (LCP, CLS, INP).
author: Diego Villanueva
trigger: When optimizing performance, eliminating Zone.js overhead, configuring images, reducing bundle sizes, or improving Core Web Vitals.
---

# Enterprise Angular Performance Architecture (v18 & v19+)

In an enterprise web application, performance directly correlates with conversion rates, SEO ranking, and user retention. You MUST architect applications to achieve **95+ Lighthouse scores**, sub-second Largest Contentful Paint (LCP), near-zero Cumulative Layout Shift (CLS), and optimal Interaction to Next Paint (INP).

---

## 1. 100% Zoneless Performance (`provideExperimentalZonelessChangeDetection`)

The single largest performance win in modern Angular is removing `zone.js`.

- **Zero Monkey-Patching Overhead**: Browser events execute with zero interceptor latency.
- **-100KB Bundle Reduction**: Instant initial script parse speedup.
- **Fine-Grained Signal Scheduling**: Angular checks only components whose Signals have emitted new values.

```typescript
// app.config.ts
import { ApplicationConfig, provideExperimentalZonelessChangeDetection } from '@angular/core';

export const appConfig: ApplicationConfig = {
  providers: [
    // ✅ ALWAYS: Enable Zoneless change detection
    provideExperimentalZonelessChangeDetection(),
  ],
};
```

---

## 2. Image Optimization (`NgOptimizedImage`)

Unoptimized images are the #1 cause of poor LCP and CLS scores.

**❌ NEVER** use standard `<img src="...">` for critical content images.
**✅ ALWAYS** use the `NgOptimizedImage` directive (`ngSrc`).

```html
<!-- 1. LCP Hero Image: Preloaded automatically via 'priority' -->
<img ngSrc="hero-banner.webp" width="1200" height="600" priority alt="Hero Product" />

<!-- 2. Lazy Loaded Image: Generates layout-safe dimensions to prevent CLS -->
<img ngSrc="avatar.webp" width="150" height="150" alt="User Profile" />

<!-- 3. Responsive Container Fill Mode -->
<div class="banner-container" style="position: relative; width: 100%; aspect-ratio: 16/9;">
  <img ngSrc="responsive-banner.webp" fill alt="Promo" />
</div>
```

---

## 3. Component Lazy Loading with `@defer`

Any component that is below the fold, hidden inside a tab/modal, or heavy (charts, rich editors, video players) MUST be loaded using `@defer`.

```html
<!-- Below-the-fold chart only downloads JS chunk when scrolled into view -->
@defer (on viewport) {
  <app-heavy-analytics-chart [data]="metrics()" />
} @placeholder {
  <div class="chart-skeleton" style="height: 320px; background: #1e1e2f; border-radius: 12px;"></div>
} @loading (minimum 200ms) {
  <app-spinner />
}
```

---

## 4. Method Calls in Templates (Banned Anti-Pattern)

**❌ NEVER** bind a component method in a template expression:

```html
<!-- ❌ DISASTROUS: Runs on EVERY render cycle, causing massive CPU waste -->
<div [class.active]="checkIfUserIsActive(user)">
  <span>{{ calculateTax(item.price) }}</span>
</div>
```

**✅ ALWAYS** use **Signals (`computed()`)** or **Pure Pipes**:

```html
<!-- ✅ ALWAYS: Computed Signal (Memoized) or Pure Pipe -->
<div [class.active]="user.isActive()">
  <span>{{ item.price | taxCalculator }}</span>
</div>
```

---

## 5. Strict Bundle Budgets (`angular.json`)

Enforce strict bundle thresholds with the new esbuild/Vite application builder:

```json
"budgets": [
  {
    "type": "initial",
    "maximumWarning": "400kb",
    "maximumError": "700kb"
  },
  {
    "type": "anyComponentStyle",
    "maximumWarning": "2kb",
    "maximumError": "4kb"
  }
]
```

---

**Execution Protocol**
1. **Always enforce `ChangeDetectionStrategy.OnPush`**: Ensures fine-grained change detection and Zoneless compatibility.
2. **Always set explicit `width` and `height` on images**: Prevents CLS layout shifts.
3. **Always use pure pipes or computed signals instead of template functions**: Guarantees memoization.
4. **Always defer below-the-fold content**: Lowers initial bundle download and execution time.
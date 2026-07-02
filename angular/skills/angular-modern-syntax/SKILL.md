---
name: angular-modern-syntax
description: The ultimate architectural standard for Angular 17+ Modern Syntax @if/@for/@switch Control Flow, and @defer Deferrable Views for granular lazy loading.
author: Diego Villanueva
trigger: When building templates, rendering lists, optimizing initial bundle sizes, or lazy-loading heavy components.
---

# Enterprise Angular Modern Syntax (v17+)

Angular 17 introduced a fundamentally new template engine. The old structural directives (`*ngIf`, `*ngFor`) relied on the framework parsing HTML attributes, which was slow and cumbersome.

The new **Built-in Control Flow** (`@`) is natively understood by the Angular compiler, resulting in drastically reduced bundle sizes and up to 90% faster runtime performance.

## 1. The `@if` Block (And Aliasing)

**❌ NEVER** use `*ngIf`.
**✅ ALWAYS** use `@if`.

```html
<!-- ✅ ALWAYS: Use @if, @else if, and @else -->
@if (user.role === 'ADMIN') {
  <app-admin-panel />
} @else if (user.role === 'MODERATOR') {
  <app-mod-panel />
} @else {
  <app-guest-view />
}

<!-- ✅ ALWAYS: Use the 'as' syntax to unwrap Signals/Observables safely -->
@if (userProfile(); as profile) {
  <h1>Welcome, {{ profile.name }}</h1>
}
```

## 2. The `@for` Block & The `track` Mandate

**❌ NEVER** use `*ngFor`.
**✅ ALWAYS** use `@for`.

In the past, developers forgot to use `trackBy` in `*ngFor`, causing Angular to destroy and recreate thousands of DOM nodes whenever a list updated, destroying performance. In `@for`, the `track` property is **MANDATORY**.

```html
<!-- ✅ ALWAYS: Track by a unique primitive ID -->
@for (item of cartItems(); track item.id) {
  <app-cart-item [item]="item" />
} @empty {
  <!-- ✅ ALWAYS: Use @empty instead of checking items.length === 0 -->
  <div class="empty-cart-message">Your cart is empty.</div>
}
```

**Implicit Variables in `@for`**:
You can easily access loop metadata.
```html
@for (item of list(); track item.id; let i = $index, e = $even) {
  <div [class.bg-grey]="e">Item {{ i }}: {{ item.name }}</div>
}
```
*(Available variables: `$index`, `$first`, `$last`, `$even`, `$odd`, `$count`)*.

## 3. The `@switch` Block

**❌ NEVER** use `[ngSwitch]` and `*ngSwitchCase`.
**✅ ALWAYS** use `@switch`. It uses strict equality (`===`) and doesn't require importing `NgSwitch` from `CommonModule`.

```html
@switch (paymentStatus()) {
  @case ('SUCCESS') {
    <app-success-receipt />
  }
  @case ('PENDING') {
    <app-loading-spinner />
  }
  @default {
    <app-error-retry />
  }
}
```

## 4. Deferrable Views (`@defer`) (The Enterprise Secret)

Historically, you could only lazy-load code at the Route level. If you had a massive 2MB PDF Viewer component on a page, the user had to download that 2MB just to load the page, even if they never scrolled down to see it.

Angular 17 introduced **Deferrable Views**. You can now lazy load *individual components* on demand. 

**✅ ALWAYS** use `@defer` to lazy-load heavy UI components (Charts, Maps, Rich Text Editors, Video Players, or anything "below the fold").

### A. The 4 Stages of `@defer`

```html
@defer (on viewport) {
  <!-- 1. The Heavy Component: The JS is downloaded only when triggered -->
  <app-heavy-3d-chart />
} @placeholder (minimum 500ms) {
  <!-- 2. Placeholder: Shown immediately on page load. MUST be fast/lightweight. -->
  <div class="skeleton-box">Scroll down to see chart</div>
} @loading (minimum 1s; after 200ms) {
  <!-- 3. Loading: Shown while the JS chunk is being downloaded over the network. -->
  <app-spinner />
} @error {
  <!-- 4. Error: Shown if the network fails to download the JS chunk. -->
  <div class="error">Failed to load the chart. Check connection.</div>
}
```
*(Note: Adding `minimum` prevents UI flickering by ensuring the state stays visible for at least that duration).*

### B. Defer Triggers

You can trigger the download based on various events:

- `on idle` (Default): Downloads when the browser is completely idle (via `requestIdleCallback`). Ideal for things below the fold.
- `on viewport`: Downloads ONLY when the `@placeholder` scrolls into the user's screen.
- `on interaction`: Downloads when the user clicks/focuses the placeholder.
- `on hover`: Downloads when the user hovers over the placeholder.
- `on timer(5s)`: Downloads after 5 seconds.
- `when customCondition()`: Downloads when a Signal/boolean becomes true.

### C. Prefetching (Premium UX)

For the absolute best User Experience, you want the JS to be already downloaded *before* the user interacts with it. 

**✅ ALWAYS** combine a hard trigger (like `interaction`) with a soft prefetch trigger (like `hover`).

```html
<!-- 
  PREMIUM UX: 
  When the user hovers over the button, we secretly download the JS in the background.
  When they actually click it, it renders instantly because the JS is already there!
-->
@defer (on interaction(showButton); prefetch on hover(showButton)) {
  <app-massive-video-player />
} @placeholder {
  <button #showButton>Play Video</button>
}
```

---

**Execution Protocol**
1. **Never `@defer` critical UI**: Do not lazy-load the primary Header, Hero Image, or LCP (Largest Contentful Paint) elements. It will hurt your Core Web Vitals and SEO.
2. **`@defer` boundaries**: Everything inside a `@defer` block (Components, Pipes, Directives) is bundled into a separate JS file. If you use a `DatePipe` inside a `@defer`, and nowhere else, the `DatePipe` will be lazy-loaded too!
3. **Tracking by Index**: Using `track $index` is allowed for simple string/number arrays, but **NEVER** use it for objects or items that can be reordered/deleted, as it destroys the state of the child components. Always track by a unique database ID.

---
name: angular-ssr-hydration
description: The ultimate architectural standard for Enterprise Angular SSR Non-Destructive Hydration, Incremental Hydration (@defer), withEventReplay, and TransferState.
author: Diego Villanueva
trigger: When configuring SSR, optimizing SEO, setting up Incremental Hydration, fixing hydration errors, or managing TransferState.
---

# Enterprise Angular SSR & Incremental Hydration (v18 & v19+)

Server-Side Rendering (SSR) is critical for Search Engine Optimization (SEO), Core Web Vitals (LCP/INP), and instant initial page renders. Angular provides **Non-Destructive Hydration** and **Incremental Hydration** to eliminate layout shift, avoid duplicate network calls, and activate JavaScript only when needed.

---

## 1. Global SSR & Hydration Setup (`app.config.ts`)

Enable hydration with **Event Replay** in `app.config.ts`:

```typescript
// app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideClientHydration, withEventReplay, withIncrementalHydration } from '@angular/platform-browser';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withFetch()), // Mandatory: withFetch uses native browser fetch & HTTP TransferState caching
    provideClientHydration(
      withEventReplay(), // Replays user clicks performed before JS was loaded
      withIncrementalHydration() // Angular 19+ Incremental Hydration via @defer
    ),
  ],
};
```

---

## 2. Incremental Hydration with `@defer (hydrate ...)` (Angular 19+)

Historically, all HTML sent by the server had to be hydrated simultaneously upon boot, consuming CPU and delaying Time to Interactive (TTI).

With **Incremental Hydration**, the server renders the full HTML for SEO, but JavaScript and event listeners are loaded and activated **only when triggered by user interaction or viewport scroll**.

```html
<main>
  <!-- 1. Critical Header: Hydrated immediately on page load -->
  <header>
    <h1>Enterprise Portal</h1>
  </header>

  <!-- 2. Comment Section: Server renders HTML, but JS hydrates only when scrolled into view -->
  @defer (hydrate on viewport) {
    <app-comments-feed [postId]="postId()" />
  } @placeholder {
    <div class="comments-skeleton">Loading comments...</div>
  }

  <!-- 3. Heavy Analytics Widget: Server renders HTML, JS hydrates only on user hover/interaction -->
  @defer (hydrate on interaction; hydrate on hover) {
    <app-analytics-dashboard [userId]="userId()" />
  } @placeholder {
    <div class="dashboard-placeholder">Hover or click to activate analytics</div>
  }
</main>
```

### Supported Hydration Triggers:
- `hydrate on viewport` — Hydrate when DOM enters viewport.
- `hydrate on interaction` — Hydrate when clicked/focused.
- `hydrate on hover` — Hydrate when mouse moves over element.
- `hydrate on idle` — Hydrate when browser reaches `requestIdleCallback`.
- `hydrate when condition()` — Hydrate when Signal boolean evaluates to true.

---

## 3. The Golden Rule of SSR: Browser APIs

Node.js has no `window`, `document`, `navigator`, or `localStorage`.

**❌ NEVER** access browser-specific globals in constructors or `ngOnInit`.
**✅ ALWAYS** use `afterNextRender()` or `isPlatformBrowser(inject(PLATFORM_ID))`.

```typescript
import { Component, PLATFORM_ID, inject, afterNextRender } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export class SafeSsrComponent {
  private readonly platformId = inject(PLATFORM_ID);

  constructor() {
    // ✅ ALWAYS: Browser-only initialization using afterNextRender
    afterNextRender(() => {
      const storedTheme = localStorage.getItem('app-theme');
      console.log('Running in browser:', storedTheme);
    });
  }

  get isBrowser(): boolean {
    return isPlatformBrowser(this.platformId);
  }
}
```

---

## 4. TransferState (Preventing Double API Calls)

When `HttpClient` with `withFetch()` is used, Angular automatically caches HTTP `GET` requests in `TransferState` between Server and Client.

For custom data sources (GraphQL, Firebase, SQLite), use `TransferState` manually:

```typescript
import { Injectable, TransferState, makeStateKey, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformServer } from '@angular/common';

const PROFILE_KEY = makeStateKey<UserProfile>('profile-cache-key');

@Injectable({ providedIn: 'root' })
export class ProfileService {
  private readonly transferState = inject(TransferState);
  private readonly platformId = inject(PLATFORM_ID);

  async getProfile(id: string): Promise<UserProfile> {
    // 1. Client Check: Read from transferred state
    if (this.transferState.hasKey(PROFILE_KEY)) {
      const cached = this.transferState.get(PROFILE_KEY, null);
      this.transferState.remove(PROFILE_KEY); // Clean up memory
      return cached!;
    }

    // 2. Fetch from DB
    const profile = await fetchProfileFromDatabase(id);

    // 3. Server Action: Save into transfer state HTML payload
    if (isPlatformServer(this.platformId)) {
      this.transferState.set(PROFILE_KEY, profile);
    }

    return profile;
  }
}
```

---

## 5. Hydration Error Avoidance Checklist

1. **No Direct DOM Manipulation**: Modifying the DOM using raw `document.getElementById().appendChild()` will break Angular's hydration tree mapping.
2. **Valid HTML Nesting**: Browser auto-correction (e.g. putting a `<div>` inside a `<p>` or putting `<tr>` directly under `<table>` without `<tbody>`) creates DOM mismatches.
3. **Consistent Dates & Random IDs**: Do NOT use `new Date()` or `Math.random()` to generate template content directly during render, as server time and client time will differ, triggering hydration warnings. Use static or transferred values.

---

**Execution Protocol**
1. **Always use `withEventReplay()`**: Prevents missed user interactions during page boot.
2. **Leverage `@defer (hydrate ...)` on below-the-fold content**: Significantly lowers TTI (Time to Interactive).
3. **Always use `provideHttpClient(withFetch())`**: Activates automatic HTTP TransferState caching.
4. **Never manipulate DOM directly**: Always use Angular template bindings to maintain hydration integrity.

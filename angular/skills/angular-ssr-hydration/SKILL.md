---
name: angular-ssr-hydration
description: The ultimate architectural standard for Enterprise Angular SSR Non-Destructive Hydration, TransferState, afterRender, and Browser API safety.
author: Diego Villanueva
trigger: When configuring SSR, optimizing SEO, fixing 'window is not defined' errors, or handling hydration.
---

# Enterprise Angular SSR & Hydration Architecture

Server-Side Rendering (SSR) is critical for Search Engine Optimization (SEO) and perceived load speed (LCP). However, running Angular in a Node.js environment introduces severe architectural constraints.

If you architect SSR poorly, the app will crash on the server, or worse, cause a massive "flicker" when the client takes over (Destructive Hydration).

## 1. Non-Destructive Hydration

Historically, Angular SSR would send HTML to the browser, and when the JavaScript finally loaded, Angular would delete all the HTML and redraw it from scratch, causing the screen to flash white.

Angular 16+ introduced **Non-Destructive Hydration**. Angular reuses the DOM nodes created by the server and simply attaches event listeners to them.

**✅ ALWAYS** enable `provideClientHydration()` in `app.config.ts`.

```typescript
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';

export const appConfig = {
  providers: [
    // withEventReplay() ensures that if a user clicks a button BEFORE Angular 
    // has finished downloading its JS, the click event is captured and replayed!
    provideClientHydration(withEventReplay())
  ]
};
```

## 2. The Golden Rule of SSR: Browser APIs

Node.js does not have a screen. It does not have a DOM.
Therefore, `window`, `document`, `navigator`, and `localStorage` **DO NOT EXIST** on the server. If your component reads them during initialization, the server will crash with a `ReferenceError`.

**❌ NEVER** access browser-specific globals directly in constructors, `ngOnInit`, or class properties.

### A. Safe Platform Checking
If you must execute logic conditionally, use Angular's platform ID.

```typescript
// ✅ ALWAYS: Check the platform before accessing browser APIs
import { Component, PLATFORM_ID, inject, OnInit } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export class TrackingComponent implements OnInit {
  private readonly platformId = inject(PLATFORM_ID);

  ngOnInit() {
    if (isPlatformBrowser(this.platformId)) {
      // Safe to use localStorage here. It will not execute on the server.
      const theme = localStorage.getItem('theme');
    }
  }
}
```

### B. Injecting the Document
If you need to manipulate the `<head>` or read the `document`, **NEVER** use the global `document` variable. Always inject it.

```typescript
import { DOCUMENT } from '@angular/common';

export class SeoService {
  private readonly doc = inject(DOCUMENT); // ✅ Safe for SSR

  setCanonicalUrl(url: string) {
    const link: HTMLLinkElement = this.doc.createElement('link');
    link.setAttribute('rel', 'canonical');
    this.doc.head.appendChild(link);
  }
}
```

## 3. The `afterRender` Lifecycle

If you are using a third-party library that requires the DOM (like D3.js, Chart.js, or Leaflet maps), you cannot initialize it in `ngOnInit`, because `ngOnInit` runs on the server!

**✅ ALWAYS** use the new `afterRender` or `afterNextRender` lifecycle hooks. These hooks **ONLY execute in the browser**, guaranteeing that the DOM is fully rendered and safe to manipulate.

```typescript
import { Component, afterNextRender, ElementRef, viewChild } from '@angular/core';

export class ChartComponent {
  readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('chartCanvas');

  constructor() {
    // ✅ ALWAYS: Initialize DOM-heavy libraries here
    // This will NEVER run on the Node.js server
    afterNextRender(() => {
      const ctx = this.canvas().nativeElement.getContext('2d');
      new ThirdPartyChartLibrary(ctx, { data: [1, 2, 3] });
    });
  }
}
```

## 4. TransferState (Preventing Double API Calls)

If your app fetches the "User Profile" during SSR, the server waits for the DB, renders the HTML, and sends it to the browser. 
When the browser wakes up and runs Angular, it will immediately make a *second* HTTP request to fetch the "User Profile" again. This is a massive waste of resources and causes flickering.

**✅ ALWAYS** transfer state from the Server to the Client.

*Note: If you use the native `HttpClient` with `provideClientHydration()`, Angular caches HTTP GET requests automatically! You don't need TransferState for standard HTTP calls anymore.*

However, if you are using GraphQL, Firebase, or custom data loading, you MUST use `TransferState`:

```typescript
import { TransferState, makeStateKey, Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformServer } from '@angular/common';

const USER_KEY = makeStateKey<User>('user-data');

@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly transferState = inject(TransferState);
  private readonly platformId = inject(PLATFORM_ID);

  async getUser(id: string): Promise<User> {
    // 1. Is the data already in the TransferState? (Browser Side)
    if (this.transferState.hasKey(USER_KEY)) {
      const cachedData = this.transferState.get(USER_KEY, null);
      this.transferState.remove(USER_KEY); // Clean up RAM
      return cachedData!;
    }

    // 2. Fetch the data from the DB/Custom API
    const user = await this.myCustomApi.fetchUser(id);

    // 3. If we are on the server, inject this data into the HTML payload
    if (isPlatformServer(this.platformId)) {
      this.transferState.set(USER_KEY, user);
    }

    return user;
  }
}
```

## 5. SSR & Deferrable Views (`@defer`)

`@defer` blocks (lazy-loaded components) **DO NOT RENDER ON THE SERVER**. 

When the Node.js server encounters a `@defer` block, it instantly renders the `@placeholder` block and sends that to the client.

**Execution Protocol**
1. **Never `@defer` SEO Content**: Do not place H1 tags, critical text, or Hero images inside a `@defer` block. Search engine crawlers will only see your placeholder.
2. **Timeouts on Server**: Do not use `setInterval` without clearing it in `ngOnDestroy`. A runaway interval on the Node.js server will keep the process alive indefinitely, causing memory leaks and eventual server crashes. Use RxJS `timer` or `interval` and ensure they complete.
3. **Absolute URLs**: Relative URLs (`/api/data`) work in the browser, but crash on the server (the server doesn't know what domain it is running on). Ensure you provide a global `API_URL` injection token that resolves to a full absolute URL (`https://api.mycompany.com`) during SSR HTTP calls.

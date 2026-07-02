---
name: angular-pwa
description: The ultimate architectural standard for Enterprise Angular PWAs Service Workers, ngsw-config.json, SwUpdate, SwPush, and Offline Mode UX.
author: Diego Villanueva
trigger: When building offline capabilities, configuring the Service Worker, handling app updates, or integrating push notifications.
---

# Enterprise Angular PWA Architecture

A Progressive Web App (PWA) is not just a website with a manifest. It is a mission-critical architecture that guarantees instant loading, offline resilience, and mobile app-like installation on Android, iOS, and Desktop.

## 1. The Service Worker Brain (`ngsw-config.json`)

When you run `ng add @angular/pwa`, Angular creates the `ngsw-config.json`. This file dictates exactly how the Service Worker intercepts HTTP requests and caches them.

**❌ NEVER** cache sensitive user data (like profile endpoints containing PII) in the Service Worker cache.
**✅ ALWAYS** partition your cache into `assetGroups` (static files) and `dataGroups` (API calls).

### A. Asset Groups (The App Shell)
```json
// ✅ ALWAYS: Cache the core bundle immediately, and lazy-load heavy assets
"assetGroups": [
  {
    "name": "app-shell",
    "installMode": "prefetch", // Downloaded the moment the app opens
    "resources": {
      "files": ["/favicon.ico", "/index.html", "/*.css", "/*.js"]
    }
  },
  {
    "name": "assets",
    "installMode": "lazy", // Downloaded only when requested by the UI
    "updateMode": "prefetch",
    "resources": {
      "files": ["/assets/**", "/*.(svg|jpg|png|webp)"]
    }
  }
]
```

### B. Data Groups (API Caching)
If the user loses connection in the subway, the app should still show the product catalog.

```json
// ✅ ALWAYS: Use specific caching strategies for different APIs
"dataGroups": [
  {
    "name": "product-catalog",
    "urls": ["/api/v1/products/**"],
    "cacheConfig": {
      "strategy": "performance", // Serve from cache FIRST for instant speed, update in background
      "maxSize": 100,
      "maxAge": "1d" // Cache expires after 1 day
    }
  },
  {
    "name": "user-orders",
    "urls": ["/api/v1/orders/**"],
    "cacheConfig": {
      "strategy": "freshness", // Ask the Network FIRST, fallback to cache if offline
      "maxSize": 50,
      "maxAge": "1h",
      "timeout": "3s" // If network takes >3s, serve the cached version immediately
    }
  }
]
```

## 2. Managing App Updates (`SwUpdate`)

Because the Service Worker intercepts all requests for `index.html` and `main.js` and serves them from the cache, **users will never see new deployments of your app automatically**. They would have to close every single tab of the app and reopen it.

**✅ ALWAYS** implement an Update Notification Service that listens to `SwUpdate` and forces a reload when a new version is detected.

```typescript
import { ApplicationRef, inject, Injectable } from '@angular/core';
import { SwUpdate, VersionReadyEvent } from '@angular/service-worker';
import { filter } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class AppUpdateService {
  private readonly swUpdate = inject(SwUpdate);
  private readonly toast = inject(ToastService);

  constructor() {
    if (!this.swUpdate.isEnabled) return;

    // 1. Listen for new versions downloaded in the background
    this.swUpdate.versionUpdates
      .pipe(filter((evt): evt is VersionReadyEvent => evt.type === 'VERSION_READY'))
      .subscribe(() => {
        // Prompt the user
        if (confirm('A new version of the application is available. Update now?')) {
          // Force a hard refresh to load the new JS bundles
          window.location.reload(); 
        }
      });
  }
}
```
*(Remember to call this service in your `app.component.ts` so it initializes).*

## 3. Web Push Notifications (`SwPush`)

To send server-initiated notifications to the user's desktop/phone, you must integrate `SwPush` with VAPID keys.

```typescript
// ✅ ALWAYS: Ask for permission and send the subscription to the backend
export class NotificationService {
  private readonly swPush = inject(SwPush);
  private readonly api = inject(ApiService);
  private readonly VAPID_PUBLIC_KEY = "BEl62i..."; 

  async subscribeToNotifications() {
    try {
      const sub = await this.swPush.requestSubscription({
        serverPublicKey: this.VAPID_PUBLIC_KEY
      });
      // Send the subscription object to your NestJS/Backend server
      await this.api.post('/users/push-subscription', sub);
    } catch (err) {
      console.error('Could not subscribe to notifications', err);
    }
  }
}
```

## 4. Offline UX (Graceful Degradation)

An Enterprise PWA must visually communicate to the user when they lose connection.

**✅ ALWAYS** create a global Signal that tracks the network state, and use it to show an "Offline Mode" banner and disable form submissions.

```typescript
// ✅ ALWAYS: Track network state via Signals
import { Injectable, signal, effect } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class NetworkStateService {
  readonly isOnline = signal(navigator.onLine);

  constructor() {
    window.addEventListener('online', () => this.isOnline.set(true));
    window.addEventListener('offline', () => this.isOnline.set(false));
  }
}

// In your Global Layout Component:
// @if (!networkState.isOnline()) {
//   <div class="offline-banner">You are currently offline. Changes will be saved locally.</div>
// }
```

## 5. The iOS & Safari Limitations

Apple heavily restricts PWAs on iOS.
1. **Manifest Restrictions**: iOS ignores many fields in `manifest.webmanifest`. You MUST include Apple-specific meta tags in `index.html`.
2. **Push Notifications**: Only supported on iOS 16.4+, and ONLY if the user has actively added the PWA to their Home Screen. You cannot ask for Push permission if they are just visiting via Safari.

```html
<!-- ✅ ALWAYS: Include Apple-specific tags in index.html for iOS PWAs -->
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Enterprise App">
<link rel="apple-touch-icon" href="assets/icons/icon-192x192.png">
```

---

**Execution Protocol**
1. **Testing the PWA**: Service Workers only run on `https://` or `localhost`. Running `ng serve` does not activate the Service Worker. To test locally, you MUST run `ng build`, then serve the `dist/` folder using a static server like `npx http-server -p 8080`.
2. **App Shell Architecture**: For maximum perceived performance, ensure your `index.html` contains inline CSS and a `<div class="skeleton"></div>` that draws the basic layout (header, sidebar) immediately before Angular even bootstraps.
3. **Bypass the Cache**: If you need to make an HTTP request that explicitly bypasses the Service Worker cache (e.g., forcing a live database check), append the `ngsw-bypass` header to the Angular `HttpClient` request.

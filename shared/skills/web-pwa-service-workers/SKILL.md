---
name: web-pwa-service-workers
description: The ultimate architectural standard for Progressive Web Apps (PWA), Service Worker Lifecycles, Workbox Offline Caching Strategies, Background Sync, and Web App Manifests.
author: Diego Villanueva
trigger: When building Progressive Web Apps (PWA), writing Service Workers, configuring Workbox caching strategies, or enabling offline functionality for web apps.
---

# Enterprise Progressive Web Apps (PWA) & Service Worker Architecture

Progressive Web Apps bridge the gap between web reach and native mobile capabilities. Utilizing **Service Workers**, **Workbox caching strategies**, and **Web App Manifests**, web applications can install onto home screens, operate seamlessly offline, and sync data in the background.

---

## 1. Web App Manifest Specification (`public/manifest.json`)

```json
{
  "name": "Enterprise Cloud Platform",
  "short_name": "Enterprise",
  "description": "High-performance enterprise cloud orchestration interface",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#09090b",
  "theme_color": "#2563eb",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

---

## 2. Workbox Caching Strategies Architecture

Different asset types require distinct caching algorithms:

| Asset Type | Optimal Strategy | Rationale |
|---|---|---|
| **Static JS/CSS Bundles** | **Cache First** (`CacheFirst`) | Content is versioned with content hashes (`app.[hash].js`). |
| **User Profile / Feed APIs** | **Stale While Revalidate** (`StaleWhileRevalidate`) | Renders instant cached response, then updates UI in background. |
| **Real-time Checkout / Financial API** | **Network First** (`NetworkFirst`) | Must fetch freshest live balance; falls back to cache only on error. |
| **External Google Fonts & Images** | **Cache First** with expiration TTL (30 Days) | Rarely changes; eliminates repeat network roundtrips. |

---

## 3. Production Service Worker with Workbox (`service-worker.ts`)

```typescript
// src/service-worker.ts
/// <reference lib="webworker" />
declare const self: ServiceWorkerGlobalScope;

import { precacheAndRoute } from 'workbox-precaching';
import { registerRoute } from 'workbox-routing';
import { StaleWhileRevalidate, CacheFirst, NetworkFirst } from 'workbox-strategies';
import { ExpirationPlugin } from 'workbox-expiration';
import { CacheableResponsePlugin } from 'workbox-cacheable-response';

// 1. Precache build assets (Injected by bundler manifest)
precacheAndRoute(self.__WB_MANIFEST || []);

// 2. Images & Fonts: Cache First (Max 60 entries, 30 days)
registerRoute(
  ({ request }) => request.destination === 'image' || request.destination === 'font',
  new CacheFirst({
    cacheName: 'static-assets-cache',
    plugins: [
      new CacheableResponsePlugin({ statuses: [0, 200] }),
      new ExpirationPlugin({
        maxEntries: 60,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 Days
      }),
    ],
  })
);

// 3. API Data: Stale While Revalidate
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/v1/'),
  new StaleWhileRevalidate({
    cacheName: 'api-data-cache',
    plugins: [
      new CacheableResponsePlugin({ statuses: [200] }),
      new ExpirationPlugin({
        maxEntries: 100,
        maxAgeSeconds: 24 * 60 * 60, // 24 Hours
      }),
    ],
  })
);

// 4. Offline Fallback Page for Navigation Requests
self.addEventListener('fetch', (event) => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match('/offline.html') as Promise<Response>;
      })
    );
  }
});
```

---

## 4. Service Worker Registration & Update Notification Hook

```tsx
// src/hooks/usePWAUpdate.ts
import { useEffect, useState } from 'react';

export function usePWAUpdate() {
  const [waitingWorker, setWaitingWorker] = useState<ServiceWorker | null>(null);
  const [showReload, setShowReload] = useState(false);

  useEffect(() => {
    if ('serviceWorker' in navigator && process.env.NODE_ENV === 'production') {
      navigator.serviceWorker.register('/sw.js').then((registration) => {
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          if (newWorker) {
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                setWaitingWorker(newWorker);
                setShowReload(true);
              }
            });
          }
        });
      });
    }
  }, []);

  const reloadPage = () => {
    waitingWorker?.postMessage({ type: 'SKIP_WAITING' });
    setShowReload(false);
    window.location.reload();
  };

  return { showReload, reloadPage };
}
```

---

**Execution Protocol**
1. **Never cache non-idempotent mutation requests (POST/PUT/DELETE)**: Only cache idempotent GET requests.
2. **Always provide an explicit `/offline.html` navigation fallback**: Guarantees a polished experience when users lose connection.
3. **Notify users when new versions install**: Avoid silently updating code under active users without prompt.

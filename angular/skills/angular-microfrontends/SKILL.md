---
name: angular-microfrontends
description: The ultimate architectural standard for Enterprise Angular Microfrontends using Native Federation (@angular-architects/native-federation), Dynamic Remotes, and Shared State across independent deployments.
author: Diego Villanueva
trigger: When designing microfrontend architectures, configuring Native Federation, integrating independent remote applications, or sharing dependencies across Angular apps.
---

# Enterprise Angular Microfrontends Architecture (Native Federation)

In large-scale enterprise organizations, monolithic frontends become deployment bottlenecks. **Native Federation** leverages web-native ECMAScript Modules (ESM) and Import Maps, working seamlessly with modern esbuild/Vite tooling without being locked into Webpack.

---

## 1. Setting Up Native Federation in Angular 18/19+

```bash
ng add @angular-architects/native-federation --project shell --type dynamic-host --port 4200
ng add @angular-architects/native-federation --project mfe-orders --type remote --port 4201
```

---

## 2. Remote Configuration (`federation.config.js`)

In the Remote Microfrontend (`mfe-orders`):

```javascript
// projects/mfe-orders/federation.config.js
const { withNativeFederation, shareAll } = require('@angular-architects/native-federation/config');

module.exports = withNativeFederation({
  name: 'mfe-orders',

  // Expose feature routes or standalone components
  exposes: {
    './routes': './projects/mfe-orders/src/app/orders.routes.ts',
    './OrderCard': './projects/mfe-orders/src/app/components/order-card.component.ts',
  },

  shared: {
    ...shareAll({
      singleton: true,
      strictVersion: true,
      requiredVersion: 'auto',
    }),
  },

  skip: [
    'rxjs/ajax',
    'rxjs/fetch',
    'rxjs/testing',
    'rxjs/webSocket',
  ],
});
```

---

## 3. Host / Shell Route Integration

In the Host / Shell application (`shell`):

```typescript
// projects/shell/src/app/app.routes.ts
import { Routes } from '@angular/router';
import { loadRemoteModule } from '@angular-architects/native-federation';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'dashboard',
    pathMatch: 'full',
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.page').then(m => m.DashboardPage),
  },
  {
    path: 'orders',
    // ✅ ALWAYS: Lazy-load remote microfrontends via loadRemoteModule
    loadChildren: () =>
      loadRemoteModule('mfe-orders', './routes').then(m => m.ORDERS_ROUTES),
  },
];
```

---

## 4. Cross-Microfrontend Communication (Shared State Contract)

Microfrontends must NOT tightly couple through direct runtime memory modifications. Instead, use:

1. **URL & Query Parameters**: Primary mechanism for cross-MFE context.
2. **Shared State Library / Event Bus**: A shared singleton library (`@shared/auth-state`) distributed via Native Federation `shared` config.
3. **Custom DOM Events / BroadcastChannel**: For loosely-coupled notifications.

```typescript
// Shared Auth State Token (@shared/auth)
import { signal } from '@angular/core';

export interface UserSession {
  token: string;
  user: { id: string; email: string };
}

// Single instance shared across Host and all Remotes
export const globalSession = signal<UserSession | null>(null);
```

---

## 5. Resilient Microfrontend Error Boundaries

If a remote microfrontend server goes offline, the Host shell must NOT crash:

```typescript
{
  path: 'analytics',
  loadChildren: () =>
    loadRemoteModule('mfe-analytics', './routes')
      .then(m => m.ANALYTICS_ROUTES)
      .catch((err) => {
        console.error('Remote MFE unavailable:', err);
        // Fallback to error boundary component
        return import('./shared/components/mfe-fallback.component').then(m => m.MFE_FALLBACK_ROUTES);
      }),
}
```

---

**Execution Protocol**
1. **Always use Native Federation over Webpack Module Federation**: Native Federation uses standard browser Import Maps and works with esbuild/Vite.
2. **Strictly isolate feature boundaries**: Remotes must never import internal services from other remotes.
3. **Always provide Fallback Error Boundaries in Shell routes**: Guarantees app resilience if a remote deployment is temporarily unavailable.
4. **Enforce `singleton: true` on `@angular/core`, `@angular/common`, and `@angular/router`**: Prevents multiple framework runtime instances in the same browser tab.

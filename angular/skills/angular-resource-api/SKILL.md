---
name: angular-resource-api
description: The ultimate architectural standard for Angular 19+ Resource APIs resource(), rxResource(), httpResource(), Request Triggers, Status Signals, and Abort Controllers.
author: Diego Villanueva
trigger: When fetching asynchronous data, handling API loading/error states, configuring reactive HTTP resources, or migrating from manual async pipes to Angular 19 Resource primitives.
---

# Enterprise Angular Resource API Architecture (v19+)

In Angular 19+, asynchronous data fetching has been elevated to a first-class reactive primitive with the **Resource API** (`resource()`, `rxResource()`, and `httpResource()`). It eliminates the need for manual `BehaviorSubject` loading flags, complex `switchMap` pipelines for standard GET operations, and `toSignal()` boilerplate.

---

## 1. The Core `resource()` Primitive (Promise-Based)

`resource()` connects an asynchronous Promise loader to Angular's reactive signal graph.

```typescript
import { Component, resource, signal, input } from '@angular/core';

interface Product {
  id: string;
  name: string;
  price: number;
}

@Component({
  selector: 'app-product-detail',
  standalone: true,
  template: `
    @if (productResource.isLoading()) {
      <div class="skeleton-loader">Loading product details...</div>
    } @else if (productResource.error()) {
      <div class="error-banner">
        Failed to load product: {{ productResource.error() }}
        <button (click)="productResource.reload()">Retry</button>
      </div>
    } @else if (productResource.value(); as product) {
      <div class="product-card">
        <h1>{{ product.name }}</h1>
        <p>{{ product.price | currency }}</p>
        <button (click)="onRefresh()">Refresh Data</button>
      </div>
    }
  `
})
export class ProductDetailComponent {
  readonly productId = input.required<string>();

  // ✅ ALWAYS: Use resource() for declarative asynchronous data fetching
  readonly productResource = resource({
    // 1. Reactive Request Trigger (Re-fetches whenever this Signal changes)
    request: () => ({ id: this.productId() }),

    // 2. Async Loader Function (Receives request params and AbortSignal)
    loader: async ({ request, abortSignal }) => {
      const response = await fetch(`/api/products/${request.id}`, {
        signal: abortSignal, // Native cancellation on fast navigation or input changes
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return (await response.json()) as Product;
    },
  });

  onRefresh(): void {
    this.productResource.reload(); // Imperative refresh
  }
}
```

---

## 2. The `rxResource()` Primitive (RxJS-Based)

When integrating with existing Angular `HttpClient` or RxJS service architectures, use `rxResource()` from `@angular/core/rxjs-interop`.

```typescript
import { Component, inject, input } from '@angular/core';
import { rxResource } from '@angular/core/rxjs-interop';
import { UserService, User } from '@core/services/user.service';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  template: `
    @switch (userResource.status()) {
      @case ('loading') {
        <app-spinner />
      }
      @case ('error') {
        <app-error-view [error]="userResource.error()" (retry)="userResource.reload()" />
      }
      @case ('resolved') {
        @if (userResource.value(); as user) {
          <app-user-card [user]="user" />
        }
      }
    }
  `
})
export class UserProfileComponent {
  private readonly userService = inject(UserService);
  readonly userId = input.required<string>();

  // ✅ ALWAYS: Use rxResource when working with HttpClient Observables
  readonly userResource = rxResource({
    request: () => ({ id: this.userId() }),
    loader: ({ request }) => this.userService.getUserById(request.id),
  });
}
```

---

## 3. Resource Status Signals Matrix

Every `Resource` instance exposes four high-precision Signals:

| Signal | Type | Description |
|---|---|---|
| `.value()` | `Signal<T \| undefined>` | The resolved data payload. |
| `.status()` | `Signal<ResourceStatus>` | `'idle'` \| `'loading'` \| `'reloading'` \| `'resolved'` \| `'error'` |
| `.isLoading()` | `Signal<boolean>` | True when status is `'loading'` or `'reloading'`. |
| `.error()` | `Signal<unknown>` | Thrown error if loader rejected. |

---

## 4. Mutating and Updating Resource State Locally

You can optimistically update or set local resource data without triggering a full network reload:

```typescript
export class CartComponent {
  readonly cartResource = resource({ /* ... */ });

  addItemOptimistically(newItem: CartItem): void {
    // .update() allows local optimistic state mutations
    this.cartResource.value.update(current => current ? [...current, newItem] : [newItem]);
  }

  clearCart(): void {
    // .set() overwrites the current value signal directly
    this.cartResource.value.set([]);
  }
}
```

---

## 5. Streaming & Real-Time Resources

For WebSocket or Server-Sent Events (SSE), combine signals with resources for live synchronization:

```typescript
readonly liveMetricsResource = resource({
  loader: async ({ abortSignal }) => {
    return new Promise<Metrics>((resolve, reject) => {
      const eventSource = new EventSource('/api/metrics/stream');
      
      abortSignal.addEventListener('abort', () => eventSource.close());
      eventSource.onmessage = (event) => resolve(JSON.parse(event.data));
      eventSource.onerror = (err) => reject(err);
    });
  }
});
```

---

**Execution Protocol**
1. **Always wire `abortSignal`**: In promise-based loaders, pass the provided `abortSignal` to `fetch()` to cancel in-flight requests when parameters change.
2. **Never create manual `loading = signal(false)` flags**: Let `.isLoading()` or `.status()` handle UI loading state.
3. **Use `.reload()` for user-triggered refresh**: Do not hack signal inputs to force a refetch.
4. **Prefer `rxResource()` for Angular HttpClient**: Integrates cleanly with functional interceptors and existing service layers.

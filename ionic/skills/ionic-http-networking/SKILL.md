---
name: ionic-http-networking
description: The ultimate architectural standard for HTTP Communication in Ionic with Angular HttpClient, Capacitor HTTP Plugin, Interceptors, and Offline Queue Architecture.
author: Diego Villanueva
trigger: When making API calls, configuring HTTP interceptors, handling network errors, or implementing offline request queuing.
---

# Enterprise Ionic HTTP & Networking Architecture

HTTP communication in Ionic requires special consideration: mobile networks are unreliable, requests may need to bypass CORS (via native HTTP), and offline resilience is mandatory.

## 1. Dual HTTP Strategy: Angular HttpClient vs Capacitor HTTP

| Feature | Angular `HttpClient` | Capacitor `@capacitor/core` HTTP |
|---|---|---|
| **Runs on** | Browser / WebView | Native layer (bypasses WebView) |
| **CORS** | Subject to CORS | Bypasses CORS entirely |
| **SSL Pinning** | ❌ | ✅ (via native config) |
| **Cookie Handling** | Standard | Native cookie jar |
| **Interceptors** | ✅ Angular interceptors | ❌ (manual) |
| **Best for** | PWA + Development | Production native builds |

### Unified HTTP Service

```typescript
// core/services/api.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Capacitor } from '@capacitor/core';
import { CapacitorHttp, HttpOptions, HttpResponse } from '@capacitor/core';
import { environment } from '@env/environment';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = environment.apiUrl;
  private readonly isNative = Capacitor.isNativePlatform();

  async get<T>(path: string): Promise<T> {
    const url = `${this.baseUrl}${path}`;

    if (this.isNative) {
      const response: HttpResponse = await CapacitorHttp.get({ url });
      return response.data as T;
    }

    return firstValueFrom(this.http.get<T>(url));
  }

  async post<T>(path: string, body: unknown): Promise<T> {
    const url = `${this.baseUrl}${path}`;

    if (this.isNative) {
      const options: HttpOptions = {
        url,
        data: body,
        headers: { 'Content-Type': 'application/json' },
      };
      const response = await CapacitorHttp.post(options);
      return response.data as T;
    }

    return firstValueFrom(this.http.post<T>(url, body));
  }
}
```

## 2. Angular HTTP Interceptors (Functional)

**❌ NEVER** use class-based interceptors.
**✅ ALWAYS** use Angular's functional interceptors with `withInterceptors()`.

### Auth Token Interceptor

```typescript
// core/interceptors/auth.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const secureStorage = inject(SecureStorageService);

  return from(secureStorage.get('access_token')).pipe(
    switchMap(token => {
      if (token) {
        const cloned = req.clone({
          setHeaders: { Authorization: `Bearer ${token}` }
        });
        return next(cloned);
      }
      return next(req);
    })
  );
};
```

### Error Handling Interceptor

```typescript
// core/interceptors/error.interceptor.ts
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const toastCtrl = inject(ToastController);
  const router = inject(Router);

  return next(req).pipe(
    retry({ count: 2, delay: 1000 }), // Retry failed requests twice
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        router.navigateByUrl('/login');
      } else if (error.status === 0) {
        // Network error (offline)
        toastCtrl.create({
          message: 'No internet connection',
          duration: 3000,
          color: 'warning',
          position: 'top',
          icon: 'wifi-outline',
        }).then(toast => toast.present());
      }
      return throwError(() => error);
    })
  );
};
```

### Register Interceptors

```typescript
// app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(
      withInterceptors([authInterceptor, errorInterceptor])
    ),
  ],
};
```

## 3. Network Status Monitoring

```typescript
// core/services/network.service.ts
import { Injectable, signal } from '@angular/core';
import { Network } from '@capacitor/network';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class NetworkService {
  readonly isOnline = signal(true);
  readonly connectionType = signal<string>('unknown');

  async initialize(): Promise<void> {
    if (Capacitor.isNativePlatform()) {
      const status = await Network.getStatus();
      this.isOnline.set(status.connected);
      this.connectionType.set(status.connectionType);

      Network.addListener('networkStatusChange', (status) => {
        this.isOnline.set(status.connected);
        this.connectionType.set(status.connectionType);
      });
    } else {
      // Web fallback
      this.isOnline.set(navigator.onLine);
      window.addEventListener('online', () => this.isOnline.set(true));
      window.addEventListener('offline', () => this.isOnline.set(false));
    }
  }
}
```

## 4. Offline Request Queue

When the app is offline, queue requests and replay them when connectivity is restored:

```typescript
// core/services/offline-queue.service.ts
interface QueuedRequest {
  id: string;
  method: 'POST' | 'PUT' | 'DELETE';
  url: string;
  body: unknown;
  timestamp: number;
}

@Injectable({ providedIn: 'root' })
export class OfflineQueueService {
  private readonly storage = inject(StorageService);
  private readonly network = inject(NetworkService);
  private readonly api = inject(ApiService);
  private readonly QUEUE_KEY = 'offline_request_queue';

  async enqueue(request: Omit<QueuedRequest, 'id' | 'timestamp'>): Promise<void> {
    const queue = await this.getQueue();
    queue.push({
      ...request,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
    });
    await this.storage.set(this.QUEUE_KEY, queue);
  }

  async processQueue(): Promise<void> {
    if (!this.network.isOnline()) return;

    const queue = await this.getQueue();
    const failed: QueuedRequest[] = [];

    for (const request of queue) {
      try {
        await this.api[request.method.toLowerCase()](request.url, request.body);
      } catch {
        failed.push(request);
      }
    }

    await this.storage.set(this.QUEUE_KEY, failed);
  }

  private async getQueue(): Promise<QueuedRequest[]> {
    return (await this.storage.get<QueuedRequest[]>(this.QUEUE_KEY)) ?? [];
  }
}
```

## 5. Loading State Pattern with Signals

```typescript
export class ProductListPage {
  private readonly productService = inject(ProductService);

  readonly products = signal<Product[]>([]);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);

  ionViewWillEnter(): void {
    this.loadProducts();
  }

  private loadProducts(): void {
    this.loading.set(true);
    this.error.set(null);

    this.productService.getAll().pipe(
      finalize(() => this.loading.set(false))
    ).subscribe({
      next: (data) => this.products.set(data),
      error: (err) => this.error.set(err.message),
    });
  }
}
```

---

**Execution Protocol**
1. **Use Capacitor HTTP for native builds**: It bypasses CORS and supports SSL pinning.
2. **Always use functional interceptors**: Class-based interceptors are legacy.
3. **Always monitor network status**: Use `@capacitor/network` and provide visual feedback when offline.
4. **Always implement retry logic**: Mobile networks drop packets. Use `retry()` with exponential backoff.
5. **Always implement offline queuing**: For write operations (POST/PUT/DELETE) that occur while offline.

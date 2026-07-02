---
name: angular-http
description: The ultimate architectural standard for Enterprise Angular HTTP Typed HttpClient, Functional Interceptors, rxResource, and RxJS Caching.
author: Diego Villanueva
trigger: When configuring HttpClient, building API services, writing interceptors, or handling loading/error states for network requests.
---

# Enterprise Angular HTTP Architecture

Network communication is the most volatile part of a frontend application. APIs fail, tokens expire, and connections drop.

Your HTTP layer MUST be strictly typed, resilient, and fully decoupled from the UI.

## 1. Global Configuration (The Fetch API)

In modern Angular (v15+), the `HttpClientModule` class is deprecated. You must configure the client in `app.config.ts`.

**✅ ALWAYS** enable `withFetch()`. It replaces the legacy `XMLHttpRequest` with the native browser `fetch` API, drastically improving Server-Side Rendering (SSR) performance and enabling Edge deployments.

```typescript
// ✅ ALWAYS: Configure HttpClient with Fetch and Functional Interceptors
import { ApplicationConfig } from '@angular/core';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(
      withFetch(), // Mandatory for modern performance/SSR
      withInterceptors([authInterceptor, errorInterceptor])
    )
  ]
};
```

## 2. Strictly Typed Repositories (Services)

A Component should NEVER know that `HttpClient` exists. Components talk to Services. Services talk to the API.

**❌ NEVER** return `Observable<any>`.
**✅ ALWAYS** define interfaces for your DTOs (Data Transfer Objects).

```typescript
// ✅ ALWAYS: Create typed interfaces, including generic wrappers
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
}

export interface User {
  id: string;
  name: string;
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = inject(API_BASE_URL); // Always use an InjectionToken!

  // Strictly typed return
  getUsers(page: number): Observable<PaginatedResponse<User>> {
    return this.http.get<PaginatedResponse<User>>(`${this.baseUrl}/users`, {
      params: { page: page.toString() }
    }).pipe(
      retry(2), // Resilience: Retry failed requests twice before throwing
      catchError(this.handleError)
    );
  }

  private handleError(error: HttpErrorResponse) {
    // Log to Datadog/Sentry here
    console.error('API Failed', error);
    return throwError(() => new Error('Something bad happened; please try again later.'));
  }
}
```

## 3. RxJS Caching & `shareReplay`

If 5 components on the screen all inject `ConfigService` and call `getConfig()`, Angular will make 5 simultaneous HTTP requests to the backend.

**✅ ALWAYS** use `shareReplay(1)` in your services to cache GET requests that don't need to be refetched constantly.

```typescript
@Injectable({ providedIn: 'root' })
export class ConfigService {
  private readonly http = inject(HttpClient);
  
  // The observable is created once and shared. 
  // Subsequent subscribers get the cached value instantly.
  public readonly config$ = this.http.get<AppConfig>('/api/config').pipe(
    shareReplay(1) 
  );
}
```

## 4. Modern Data Fetching: `rxResource` (Angular 19+)

Historically, bridging HTTP Observables with the UI required `AsyncPipe` (`*ngIf="data$ | async"`) and complex RxJS behavior subjects for loading/error states.

Angular 19 introduced `rxResource`. It declaratively handles loading states, error states, and cancellations, returning Signals.

```typescript
// ✅ ALWAYS: Use rxResource for modern declarative data fetching
import { Component, resource } from '@angular/core';
import { rxResource } from '@angular/core/rxjs-interop';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  template: `
    @if (userResource.isLoading()) {
      <spinner />
    } @else if (userResource.error()) {
      <error-message [error]="userResource.error()" />
    } @else if (userResource.value()) {
      <h1>{{ userResource.value()!.name }}</h1>
    }
  `
})
export class UserProfileComponent {
  private readonly userService = inject(UserService);
  readonly userId = input.required<string>(); // Signal Input

  // Automatically fetches data when userId changes, and handles loading/error signals!
  readonly userResource = rxResource({
    request: () => this.userId(), // Reactive trigger
    loader: (id) => this.userService.getUserById(id.request) // The HTTP call
  });
}
```

## 5. Functional Interceptors (Auth & Error Handling)

Interceptors modify HTTP requests before they leave the browser, and intercept responses before they reach your services. 

### A. The Auth Interceptor
Injects the Bearer token into every request (except public routes).

```typescript
// ✅ ALWAYS: Use Functional Interceptors for Auth
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const tokenService = inject(TokenService);
  const token = tokenService.get();

  // Don't intercept calls to external APIs
  if (req.url.startsWith('https://third-party.com')) {
    return next(req);
  }

  if (token) {
    const authReq = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`)
    });
    return next(authReq);
  }

  return next(req);
};
```

### B. The Global Error Interceptor
Catches 401 Unauthorized errors and redirects to login, or catches 500s and shows a global toast notification.

```typescript
// ✅ ALWAYS: Handle global HTTP errors centrally
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const toast = inject(ToastService);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        // Token expired
        router.navigate(['/login']);
      } else if (error.status >= 500) {
        // Server crash
        toast.showError('Critical server error. Our team has been notified.');
      }
      // Re-throw so the local service can handle specific logic if needed
      return throwError(() => error);
    })
  );
};
```

---

**Execution Protocol**
1. **Unsubscribing**: `HttpClient` Observables naturally complete after one emission, meaning they DO NOT cause memory leaks in most cases. However, if you are cancelling a request mid-flight (e.g., in a Typeahead search), you MUST use `switchMap`.
2. **HttpParams**: Do not build URL query strings manually (`/api/users?name=${name}&age=${age}`). ALWAYS use the `HttpParams` class, which handles URL encoding automatically to prevent injection attacks and malformed URLs.
3. **CORS and Credentials**: If your API and Frontend live on different domains and you rely on Cookies (not JWTs), you MUST set `withCredentials: true` in your HTTP requests, otherwise the browser will strip the cookies for security.

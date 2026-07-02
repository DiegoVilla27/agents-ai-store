---
name: angular-di
description: The ultimate architectural standard for Angular Dependency Injection Hierarchical DI, InjectionTokens, Factory Providers, inject() options, and Functional Interceptors.
author: Diego Villanueva
trigger: When configuring providers, creating services, using InjectionTokens, writing Interceptors/Guards, or managing dependency lifecycles.
---

# Enterprise Angular Dependency Injection (DI)

Angular's Dependency Injection system is the backbone of the framework. It is a **Hierarchical DI** system, meaning dependencies can be Singletons (global) or scoped to a specific component tree (local).

Mastering DI is the difference between a tightly coupled monolithic app and a testable, highly modular architecture.

## 1. The `inject()` Function and Resolution Modifiers

As established in the Core standards, constructor injection is banned. You must use `inject()`.

But how do you handle optional dependencies or hierarchical overrides without decorators like `@Optional()` or `@SkipSelf()`? You pass an options object to `inject()`.

```typescript
// ✅ ALWAYS: Use inject options for complex resolution
export class ComplexComponent {
  // 1. Optional: If the service is not provided, return null instead of crashing
  private readonly optionalService = inject(AnalyticsService, { optional: true });

  // 2. SkipSelf: Look for the service in the parent component's providers, ignoring this component's providers
  private readonly parentTheme = inject(ThemeService, { skipSelf: true });

  // 3. Host: Stop searching for the dependency at this component's host element (don't go all the way to root)
  private readonly hostConfig = inject(WidgetConfig, { host: true });
}
```

## 2. Hierarchical Scoping (Singletons vs Local State)

You must understand exactly where a service lives in memory.

### A. The Singleton (`providedIn: 'root'`)
The service is created once and shared across the entire app. Ideal for HTTP clients, Auth state, and global caches.
```typescript
@Injectable({ providedIn: 'root' })
export class GlobalAuthService {}
```

### B. The Component Scope (`providers: [...]`)
The service is created when the Component is mounted, and **destroyed** when the Component unmounts. Ideal for complex forms or local UI state that must be reset when the user leaves the page.
```typescript
@Component({
  selector: 'app-checkout',
  providers: [CheckoutStateService], // ✅ ALWAYS: Scope complex transient state to the component
})
export class CheckoutComponent {
  private readonly state = inject(CheckoutStateService);
}
```

## 3. InjectionTokens (Decoupling Configurations)

**❌ NEVER** inject concrete objects or global browser APIs (`window`, `localStorage`) directly into your services. It makes them impossible to unit test and tightly couples your logic to the browser (breaking Server-Side Rendering / Angular Universal).

**✅ ALWAYS** wrap them in an `InjectionToken`.

```typescript
// ✅ ALWAYS: Create InjectionTokens for configurations and browser APIs
import { InjectionToken, inject } from '@angular/core';

// 1. The Token
export const LOCAL_STORAGE = new InjectionToken<Storage>('Browser Local Storage', {
  providedIn: 'root',
  factory: () => window.localStorage, // Graceful fallback or direct reference
});

export const API_URL = new InjectionToken<string>('Base API URL');

// 2. Providing the value (in app.config.ts)
providers: [
  { provide: API_URL, useValue: 'https://api.enterprise.com/v1' }
]

// 3. Using the token
export class ApiService {
  private readonly storage = inject(LOCAL_STORAGE);
  private readonly baseUrl = inject(API_URL);
}
```

## 4. Advanced Provider Patterns

Angular allows you to swap out implementations without touching the components that consume them. This is the definition of Dependency Inversion.

```typescript
// 1. useClass (Swapping implementations)
// Use the MockLogger in Dev, and DatadogLogger in Prod, but the UI just asks for "LoggerService"
providers: [
  { 
    provide: LoggerService, 
    useClass: environment.production ? DatadogLoggerService : ConsoleLoggerService 
  }
]

// 2. useFactory (Dynamic dependencies)
// Sometimes a service needs to be initialized asynchronously or depends on other tokens
providers: [
  {
    provide: AnalyticsService,
    useFactory: () => {
      const config = inject(APP_CONFIG);
      const http = inject(HttpClient);
      return new AnalyticsService(http, config.analyticsKey);
    }
  }
]

// 3. useExisting (Aliasing)
// Two tokens pointing to the exact same memory instance
providers: [
  { provide: NewApiService, useExisting: LegacyApiService }
]
```

## 5. Functional Interceptors & Guards (No More Classes)

In modern Angular, `HttpInterceptor` and `CanActivate` classes are legacy. They required huge amounts of boilerplate.
You MUST write Interceptors and Guards as pure functions using `inject()`.

```typescript
// ✅ ALWAYS: Use Functional Interceptors
import { HttpInterceptorFn, HttpHandlerFn, HttpRequest } from '@angular/common/http';
import { inject } from '@angular/core';

export const authInterceptor: HttpInterceptorFn = (req: HttpRequest<unknown>, next: HttpHandlerFn) => {
  const authService = inject(AuthService); // Inject works inside functions now!
  const token = authService.getToken();

  if (token) {
    const cloned = req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
    return next(cloned);
  }
  return next(req);
};

// In app.config.ts:
provideHttpClient(withInterceptors([authInterceptor]))
```

## 6. App Initialization (`provideAppInitializer`)

If you need to fetch configuration from a server *before* the application renders, you must use the initializer.
In Angular 16+, `APP_INITIALIZER` was streamlined into `provideAppInitializer`.

```typescript
// ✅ ALWAYS: Block bootstrap until critical config is loaded
import { provideAppInitializer } from '@angular/core';

export const appConfig = {
  providers: [
    provideAppInitializer(() => {
      const configService = inject(ConfigService);
      return configService.loadInitialConfig(); // Returns a Promise or Observable
    })
  ]
};
```

---

**Execution Protocol**
1. **No Circular Dependencies**: If Service A injects Service B, and Service B injects Service A, Angular will crash at runtime with `Circular dependency in DI`. Fix this by extracting the shared logic into a Service C, or using an `InjectionToken`.
2. **ProvidedIn: 'any'**: Avoid this unless absolutely necessary. It creates a new instance for every lazily loaded module, which is an anti-pattern in modern standalone architecture.
3. **Testing with DI**: In Unit Tests, you don't need to import the real services. Use `TestBed.configureTestingModule({ providers: [{ provide: RealService, useValue: mockService }] })` to swap out heavy dependencies for simple mocks.

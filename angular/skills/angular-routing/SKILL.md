---
name: angular-routing
description: The ultimate architectural standard for Enterprise Angular Routing withComponentInputBinding, Functional Guards, CanMatch vs CanActivate, and View Transitions.
author: Diego Villanueva
trigger: When configuring routes, writing guards, passing route parameters, or implementing lazy loading.
---

# Enterprise Angular Routing Architecture (v17+)

Routing is the backbone of an Enterprise application. A poorly structured routing configuration leads to massive bundle sizes, janky navigations, and unmaintainable component logic.

Modern Angular routing is Standalone, Functional, and highly optimized for performance and UX.

## 1. Global Configuration

`RouterModule.forRoot()` is a legacy construct. You MUST configure the router in `app.config.ts` using `provideRouter()`.

**✅ ALWAYS** enable the critical features: Component Input Binding, View Transitions, and Hash-free scrolling.

```typescript
// ✅ ALWAYS: Modern Standalone Router Configuration
import { provideRouter, withComponentInputBinding, withViewTransitions, withInMemoryScrolling } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(
      routes,
      // MANDATORY: Automatically passes Route Params and Query Params into Component @Input() or input()
      withComponentInputBinding(),
      
      // OPTIONAL BUT RECOMMENDED: Animates navigations using the browser's native View Transitions API
      withViewTransitions(),
      
      // MANDATORY: Restores scroll position when hitting the back button
      withInMemoryScrolling({ scrollPositionRestoration: 'enabled' })
    )
  ]
};
```

## 2. Component Input Binding (The End of `ActivatedRoute`)

Historically, developers injected `ActivatedRoute` to read `/users/:id`. This forced the component to manage RxJS subscriptions and made testing a nightmare.

**❌ NEVER** inject `ActivatedRoute` to read basic parameters in new components.
**✅ ALWAYS** rely on `withComponentInputBinding()` to receive route data as Signal Inputs.

```typescript
// Route config: { path: 'users/:userId', component: UserDetailComponent }
// URL: /users/42?tab=activity

import { Component, input } from '@angular/core';

@Component({
  selector: 'app-user-detail',
  standalone: true,
  template: `
    <h1>User: {{ userId() }}</h1>
    <p>Viewing tab: {{ tab() }}</p>
  `
})
export class UserDetailComponent {
  // Angular automatically maps the :userId path parameter here!
  readonly userId = input.required<string>();

  // Angular automatically maps the ?tab= query parameter here!
  readonly tab = input<string>('profile'); 
}
```

## 3. Functional Guards

Class-based guards (`@Injectable() class AuthGuard implements CanActivate`) are deprecated.

**❌ NEVER** use class-based guards.
**✅ ALWAYS** use Functional Guards. They are pure functions that leverage the `inject()` function.

```typescript
// ✅ ALWAYS: Use Functional Guards
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }
  
  // Return a UrlTree to redirect seamlessly
  return router.createUrlTree(['/login']); 
};
```

## 4. The Critical Difference: `CanMatch` vs `CanActivate`

When lazy loading a feature module, many developers make the catastrophic mistake of using `CanActivate` to protect it. 

If you use `CanActivate` on a `loadComponent` or `loadChildren` route, Angular will **DOWNLOAD THE JS BUNDLE FIRST**, and *then* run the guard. This exposes proprietary business logic to unauthorized users.

**❌ NEVER** use `CanActivate` on lazy-loaded routes.
**✅ ALWAYS** use `CanMatch`. It runs *before* the router even tries to match the route, meaning the JS bundle will NEVER be downloaded if the guard returns false.

```typescript
export const routes: Routes = [
  {
    path: 'admin',
    // ✅ ALWAYS: Use CanMatch for lazy routes to prevent bundle downloads
    canMatch: [adminGuard], 
    loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES)
  }
];
```

## 5. Resolvers vs. Component Fetching

Historically, `Resolvers` were used to fetch data (e.g., a User profile) before activating the route. 
**The Problem**: Resolvers block the UI. If the API takes 3 seconds, the user clicks a link and nothing happens for 3 seconds. The app feels broken.

**❌ NEVER** use Resolvers for data that takes more than 100ms to load.
**✅ ALWAYS** let the navigation happen instantly, and fetch the data inside the component using `rxResource` or `@defer` (showing a skeleton loader).

Only use Resolvers if the data is instantaneously available (e.g., reading from a local Redux/Signal store), or if you strictly CANNOT show the page without the data.

```typescript
// If you MUST use a resolver, make it functional:
export const userResolver: ResolveFn<User> = (route) => {
  return inject(UserService).getUser(route.paramMap.get('id')!);
};
```

## 6. Preloading Strategies

Lazy loading is great for initial bundle sizes, but it causes a delay when the user actually navigates, as they have to wait for the chunk to download.

**✅ ALWAYS** configure a preloading strategy to download chunks in the background.

```typescript
import { PreloadAllModules } from '@angular/router';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(
      routes,
      // Downloads all lazy-loaded chunks in the background while the user is idle!
      withPreloading(PreloadAllModules) 
    )
  ]
};
```
*(For massive enterprise apps, you can write a Custom Preloading Strategy that only preloads routes marked with `{ data: { preload: true } }`).*

---

**Execution Protocol**
1. **Magic Strings**: NEVER write raw strings for navigation `router.navigate(['/dashboard', 'users', 123])`. You MUST use an enum or a centralized Route Map constant to prevent broken links when URLs change.
2. **Relative Routing**: When navigating from a child component, use relative routing `router.navigate(['../'], { relativeTo: this.route })` instead of hardcoding the absolute path.
3. **RouterLink**: In HTML templates, ALWAYS use `[routerLink]` directive. NEVER use `(click)="goToPage()"` to execute a `router.navigate()` if the action is just a simple navigation. `routerLink` creates a real `href` which is critical for SEO and allowing users to "Right Click -> Open in New Tab".

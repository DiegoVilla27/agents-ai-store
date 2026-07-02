---
name: angular-performance
description: The ultimate architectural standard for Enterprise Angular Performance OnPush, NgOptimizedImage, RunOutsideAngular, Bundle Budgets, and Core Web Vitals.
author: Diego Villanueva
trigger: When optimizing performance, loading images, configuring change detection, or managing heavy DOM events.
---

# Enterprise Angular Performance Architecture

In an Enterprise application, performance is not an afterthought; it is a strict requirement. A slow application destroys conversion rates and user trust. 

You MUST architect the application to respect Core Web Vitals (LCP, CLS, INP) and maintain a 60fps render cycle.

## 1. Change Detection (`OnPush`)

Angular's default change detection strategy checks the entire component tree (from root to leaves) every time a DOM event fires, a timer ticks, or an HTTP request completes. In a large app, this causes massive CPU spikes.

**❌ NEVER** use `ChangeDetectionStrategy.Default`.
**✅ ALWAYS** set `ChangeDetectionStrategy.OnPush` on every single component.

With `OnPush`, Angular only checks the component if:
1. An `@Input()` reference changes.
2. A `Signal` read in the template updates.
3. An event originates from the component itself (e.g., a button click).

```typescript
// ✅ ALWAYS: Enforce OnPush change detection
import { Component, ChangeDetectionStrategy } from '@angular/core';

@Component({
  selector: 'app-heavy-dashboard',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush, // MANDATORY
  template: `...`
})
export class HeavyDashboardComponent {}
```

## 2. Image Optimization (`NgOptimizedImage`)

Unoptimized images are the #1 cause of terrible LCP (Largest Contentful Paint) and CLS (Cumulative Layout Shift) scores.

**❌ NEVER** use the standard `<img src="...">` tag for content images.
**✅ ALWAYS** use the `NgOptimizedImage` directive (`ngSrc`).

### A. The Core Rules of `NgOptimizedImage`

```html
<!-- 1. LCP Images: The largest image visible on load MUST have 'priority' -->
<!-- 'priority' adds a <link rel="preload"> tag to the document head automatically -->
<img ngSrc="hero-banner.jpg" width="1200" height="600" priority alt="Hero" />

<!-- 2. Standard Images: Lazy loaded by default, prevents CLS -->
<!-- You MUST provide width and height, or the compiler will throw an error -->
<img ngSrc="user-avatar.jpg" width="150" height="150" alt="Avatar" />

<!-- 3. Fill Mode: When you don't know the exact dimensions (e.g., responsive grids) -->
<!-- The parent container MUST have position: relative, absolute, or fixed -->
<div style="position: relative; width: 100%; aspect-ratio: 16/9;">
  <img ngSrc="gallery-image.jpg" fill alt="Gallery" />
</div>

<!-- 4. Placeholders (Angular 17+) -->
<!-- Shows a blurry 20x20 base64 version while the high-res image loads -->
<img ngSrc="high-res.jpg" width="800" height="600" placeholder alt="Photo" />
```

### B. Image Loaders (CDNs)

If you use a CDN (Cloudflare, Imgix, Cloudinary), you must configure a loader in `app.config.ts`. This allows Angular to automatically request resized, WebP/AVIF versions of your images based on the user's screen size (generating `srcset` automatically).

```typescript
// ✅ ALWAYS: Configure a CDN loader for automatic srcset generation
import { provideCloudinaryLoader } from '@angular/common';

export const appConfig: ApplicationConfig = {
  providers: [
    provideCloudinaryLoader('https://res.cloudinary.com/enterprise-app')
  ]
};
```

## 3. Escaping Zone.js (`runOutsideAngular`)

If your app is not yet fully Zoneless (Angular 18+ Experimental), `zone.js` is still intercepting every asynchronous event to trigger Change Detection.

If you listen to high-frequency events like `scroll`, `mousemove`, `drag`, or run a `requestAnimationFrame`, Zone.js will trigger Change Detection 60 times per second, completely freezing the browser UI.

**✅ ALWAYS** run high-frequency events outside of Angular's zone.

```typescript
// ✅ ALWAYS: Escape the Angular Zone for heavy DOM events
import { Component, inject, NgZone, ElementRef, AfterViewInit } from '@angular/core';
import { fromEvent } from 'rxjs';

export class ScrollTrackerComponent implements AfterViewInit {
  private readonly ngZone = inject(NgZone);
  private readonly el = inject(ElementRef);

  ngAfterViewInit() {
    // 1. Leave the Angular Zone
    this.ngZone.runOutsideAngular(() => {
      
      // 2. Attach the high-frequency listener
      fromEvent(this.el.nativeElement, 'scroll').subscribe((e) => {
        const scrollTop = e.target.scrollTop;
        
        // Pure DOM manipulation is fine here, it won't trigger Angular
        if (scrollTop > 500) {
          
          // 3. Re-enter the Zone ONLY when you need to update the UI State
          this.ngZone.run(() => {
            this.showBackToTopButton.set(true);
          });
        }
      });
      
    });
  }
}
```

## 4. Lazy Loading & Code Splitting

Never ship the entire application in a single `main.js` file.

1. **Route-Level Lazy Loading**:
   ```typescript
   // ✅ ALWAYS: Lazy load route components using loadComponent
   export const routes: Routes = [
     { 
       path: 'admin', 
       loadComponent: () => import('./admin/admin.component').then(m => m.AdminComponent) 
     }
   ];
   ```

2. **Component-Level Lazy Loading**: 
   Use `@defer` (as documented in `angular-modern-syntax`) to lazy-load heavy components that live "below the fold" on the same page.

## 5. Bundle Budgets (`angular.json`)

You must enforce strict bundle size limits to prevent developers from accidentally importing massive libraries like `lodash` or `moment.js` (instead of `date-fns`).

```json
// ✅ ALWAYS: Configure strict budgets in angular.json
"budgets": [
  {
    "type": "initial",
    "maximumWarning": "500kb",
    "maximumError": "1mb"
  },
  {
    "type": "anyComponentStyle",
    "maximumWarning": "2kb",
    "maximumError": "4kb"
  }
]
```

---

**Execution Protocol**
1. **Never use method calls in templates**: Binding `<div [class.active]="checkIfActive(user)">` is a catastrophic performance failure. Angular will execute `checkIfActive` on every single change detection cycle. ALWAYS use a `Signal` or a `Pipe` instead.
2. **Memoize Pure Pipes**: Angular Pipes are highly optimized. If you need to filter a list or format a string in the template, write a `@Pipe({ name: 'format', pure: true })`. Angular caches the result and only recalculates if the input arguments change.
3. **Avoid memory leaks**: Refer to the `takeUntilDestroyed` protocol (angular-core) to ensure RxJS subscriptions don't pile up in memory.
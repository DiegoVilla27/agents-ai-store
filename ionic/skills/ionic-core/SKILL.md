---
name: ionic-core
description: The ultimate architectural standard for Ionic Core (v8+) Standalone Components, ion-page Lifecycle, Platform-Adaptive UI, and Angular Signals integration.
author: Diego Villanueva
trigger: When writing Ionic pages, using Ionic UI components, managing page lifecycle, or configuring platform-adaptive behavior.
---

# Enterprise Ionic Core Architecture (v8+)

Ionic v8+ has undergone a complete architectural shift. The legacy `IonicModule.forRoot()` monolith is dead. Modern Ionic is built entirely on **Web Components** consumed via **Angular Standalone imports**, with full compatibility with **Angular Signals** and **Zoneless** rendering.

## 1. Standalone Component Imports

Historically, all Ionic components were available globally via `IonicModule.forRoot()` in a root `AppModule`. This imported the entire Ionic library regardless of which components you used, bloating the bundle.

**❌ NEVER** import `IonicModule` globally.
**✅ ALWAYS** import individual Ionic standalone components directly in each component's `imports` array.

```typescript
// ❌ ATROCIOUS: Legacy Global Import
import { IonicModule } from '@ionic/angular';

@NgModule({
  imports: [IonicModule.forRoot()], // Imports EVERYTHING
})
export class AppModule {}

// ✅ ALWAYS: Modern Standalone Imports
import { Component, ChangeDetectionStrategy } from '@angular/core';
import {
  IonHeader, IonToolbar, IonTitle,
  IonContent, IonList, IonItem, IonLabel
} from '@ionic/angular/standalone';

@Component({
  selector: 'app-contacts',
  standalone: true,
  imports: [IonHeader, IonToolbar, IonTitle, IonContent, IonList, IonItem, IonLabel],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ion-header>
      <ion-toolbar>
        <ion-title>Contacts</ion-title>
      </ion-toolbar>
    </ion-header>
    <ion-content>
      <ion-list>
        @for (contact of contacts(); track contact.id) {
          <ion-item>
            <ion-label>{{ contact.name }}</ion-label>
          </ion-item>
        }
      </ion-list>
    </ion-content>
  `
})
export class ContactsPage {
  readonly contacts = signal<Contact[]>([]);
}
```

## 2. Application Bootstrap (Standalone)

The app MUST be bootstrapped using Angular's standalone `bootstrapApplication` with Ionic providers.

```typescript
// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { RouteReuseStrategy, provideRouter } from '@angular/router';
import { provideIonicAngular, IonicRouteStrategy } from '@ionic/angular/standalone';
import { AppComponent } from './app/app.component';
import { routes } from './app/app.routes';

bootstrapApplication(AppComponent, {
  providers: [
    provideIonicAngular({
      mode: 'md', // Force Material Design, or 'ios' for iOS-only, or omit for adaptive
      animated: true,
    }),
    provideRouter(routes),
    { provide: RouteReuseStrategy, useClass: IonicRouteStrategy },
  ],
});
```

## 3. Page Lifecycle (Critical for Mobile)

Ionic maintains a **navigation stack**. When a user navigates forward, the previous page is NOT destroyed—it is cached in the DOM stack. When they navigate back, the cached page is restored.

This means Angular's `ngOnInit` only fires ONCE per page instance. If you load data in `ngOnInit`, it will be stale when the user navigates back.

**❌ NEVER** rely solely on `ngOnInit` for data that must refresh.
**✅ ALWAYS** use Ionic's lifecycle hooks for mobile-correct behavior.

| Hook | When it fires | Use Case |
|---|---|---|
| `ionViewWillEnter` | Every time page is about to become visible | Refresh data, start polling |
| `ionViewDidEnter` | After page transition animation completes | Start heavy tasks, focus inputs |
| `ionViewWillLeave` | Before page starts leaving | Pause timers, save draft |
| `ionViewDidLeave` | After page is fully hidden | Stop subscriptions, cleanup |

```typescript
import { Component, signal } from '@angular/core';
import { ViewWillEnter, ViewDidLeave } from '@ionic/angular';
import { IonContent, IonList, IonItem, IonLabel } from '@ionic/angular/standalone';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [IonContent, IonList, IonItem, IonLabel],
  template: `
    <ion-content>
      @if (loading()) {
        <ion-spinner />
      } @else {
        <ion-list>
          @for (item of items(); track item.id) {
            <ion-item><ion-label>{{ item.title }}</ion-label></ion-item>
          }
        </ion-list>
      }
    </ion-content>
  `
})
export class DashboardPage implements ViewWillEnter, ViewDidLeave {
  private readonly dataService = inject(DataService);
  readonly items = signal<DashboardItem[]>([]);
  readonly loading = signal(false);

  // ✅ Fires every time user visits or returns to this page
  ionViewWillEnter(): void {
    this.loading.set(true);
    this.dataService.getDashboard().subscribe(data => {
      this.items.set(data);
      this.loading.set(false);
    });
  }

  ionViewDidLeave(): void {
    // Cleanup if needed
  }
}
```

## 4. Platform-Adaptive UI

Ionic automatically renders iOS-style components on iOS and Material Design on Android. You can control this behavior:

### A. Global Mode
Set in `provideIonicAngular()`:
- `mode: 'ios'` → Force iOS look everywhere.
- `mode: 'md'` → Force Material Design everywhere.
- Omit `mode` → Adaptive (recommended for cross-platform apps).

### B. Per-Component Mode
```html
<!-- Force Material Design on a specific button regardless of platform -->
<ion-button mode="md" expand="block">Submit</ion-button>
```

### C. Platform-Specific Logic
```typescript
import { Platform } from '@ionic/angular/standalone';

export class SettingsPage {
  private readonly platform = inject(Platform);

  readonly isIos = this.platform.is('ios');
  readonly isAndroid = this.platform.is('android');
  readonly isMobile = this.platform.is('mobile');
  readonly isPwa = this.platform.is('pwa');
}
```

## 5. Ion-Content & Scroll Management

`ion-content` is the scrollable container in Ionic. It uses native scrolling on mobile for buttery-smooth 60fps performance.

```html
<!-- ✅ Full-screen content with padding -->
<ion-content [fullscreen]="true" class="ion-padding">
  <!-- The duplicate header trick for iOS large title collapse effect -->
  <ion-header collapse="condense">
    <ion-toolbar>
      <ion-title size="large">Settings</ion-title>
    </ion-toolbar>
  </ion-header>

  <!-- Content here -->
</ion-content>
```

### Scroll Events
```typescript
// ✅ Listen to scroll events efficiently
import { IonContent } from '@ionic/angular/standalone';

export class FeedPage {
  @ViewChild(IonContent) content!: IonContent;

  onScroll(event: CustomEvent) {
    const scrollTop = event.detail.scrollTop;
    if (scrollTop > 300) {
      this.showBackToTop.set(true);
    }
  }

  scrollToTop() {
    this.content.scrollToTop(300); // 300ms animation
  }
}
```

## 6. Refresher & Infinite Scroll

```html
<ion-content>
  <!-- Pull-to-refresh (mobile pattern) -->
  <ion-refresher slot="fixed" (ionRefresh)="onRefresh($event)">
    <ion-refresher-content />
  </ion-refresher>

  <ion-list>
    @for (item of items(); track item.id) {
      <ion-item>{{ item.title }}</ion-item>
    }
  </ion-list>

  <!-- Infinite scroll for pagination -->
  <ion-infinite-scroll (ionInfinite)="loadMore($event)">
    <ion-infinite-scroll-content loadingSpinner="crescent" />
  </ion-infinite-scroll>
</ion-content>
```

```typescript
onRefresh(event: RefresherCustomEvent) {
  this.dataService.refresh().subscribe({
    next: (data) => {
      this.items.set(data);
      event.target.complete();
    },
    error: () => event.target.complete()
  });
}

loadMore(event: InfiniteScrollCustomEvent) {
  this.dataService.loadPage(this.page()).subscribe({
    next: (data) => {
      this.items.update(current => [...current, ...data]);
      this.page.update(p => p + 1);
      event.target.complete();
      if (data.length === 0) event.target.disabled = true;
    }
  });
}
```

---

**Execution Protocol**
1. **Always import Ionic components individually**: Tree-shaking depends on it. Never use a barrel import that re-exports all Ionic components.
2. **Always implement `ViewWillEnter`**: Any page that loads data MUST use `ionViewWillEnter`, not just `ngOnInit`.
3. **Always set `ChangeDetectionStrategy.OnPush`**: Ionic v8+ components are fully compatible with OnPush and Signals.
4. **Never nest `ion-content`**: Only one `ion-content` per page. Nesting causes scroll conflicts.

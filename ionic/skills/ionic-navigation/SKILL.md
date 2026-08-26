---
name: ionic-navigation
description: The ultimate architectural standard for Ionic Navigation Stack, IonTabs, Modal/Sheet Patterns, Angular Router integration, and Deep Linking.
author: Diego Villanueva
trigger: When configuring navigation, implementing tabs, presenting modals/action sheets, or managing the Ionic navigation stack.
---

# Enterprise Ionic Navigation Architecture (v8+)

Ionic's navigation model is fundamentally different from standard Angular routing. Ionic uses a **stack-based navigation system** where pages are pushed onto and popped from a stack, preserving previous pages in the DOM for instant back-navigation with zero re-render cost.

## 1. IonRouterOutlet (The Heart of Navigation)

**❌ NEVER** use Angular's standard `<router-outlet>`.
**✅ ALWAYS** use `<ion-router-outlet>` in your root app component. It enables Ionic's stack-based page transitions and caching.

```typescript
// app.component.ts
import { Component } from '@angular/core';
import { IonApp, IonRouterOutlet } from '@ionic/angular/standalone';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [IonApp, IonRouterOutlet],
  template: `
    <ion-app>
      <ion-router-outlet />
    </ion-app>
  `,
})
export class AppComponent {}
```

## 2. Route Configuration with Lazy Loading

ALWAYS lazy-load every page using `loadComponent`. This is critical for mobile performance.

```typescript
// app.routes.ts
import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'tabs',
    pathMatch: 'full',
  },
  {
    path: 'tabs',
    loadComponent: () => import('./layout/tabs/tabs.page').then(m => m.TabsPage),
    children: [
      {
        path: 'home',
        loadComponent: () => import('./features/home/pages/home.page').then(m => m.HomePage),
      },
      {
        path: 'search',
        loadComponent: () => import('./features/search/pages/search.page').then(m => m.SearchPage),
      },
      {
        path: 'profile',
        loadComponent: () => import('./features/profile/pages/profile.page').then(m => m.ProfilePage),
      },
      {
        path: '',
        redirectTo: 'home',
        pathMatch: 'full',
      },
    ],
  },
  {
    path: 'login',
    loadComponent: () => import('./features/auth/pages/login.page').then(m => m.LoginPage),
  },
  {
    path: 'detail/:id',
    loadComponent: () => import('./features/detail/pages/detail.page').then(m => m.DetailPage),
  },
];
```

## 3. Tab Navigation

Tabs are the most common mobile navigation pattern. Ionic provides `ion-tabs` to manage independent navigation stacks per tab.

```typescript
// layout/tabs/tabs.page.ts
import { Component } from '@angular/core';
import { IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel } from '@ionic/angular/standalone';
import { addIcons } from 'ionicons';
import { home, search, person } from 'ionicons/icons';

@Component({
  selector: 'app-tabs',
  standalone: true,
  imports: [IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel],
  template: `
    <ion-tabs>
      <ion-tab-bar slot="bottom">
        <ion-tab-button tab="home">
          <ion-icon name="home" />
          <ion-label>Home</ion-label>
        </ion-tab-button>

        <ion-tab-button tab="search">
          <ion-icon name="search" />
          <ion-label>Search</ion-label>
        </ion-tab-button>

        <ion-tab-button tab="profile">
          <ion-icon name="person" />
          <ion-label>Profile</ion-label>
        </ion-tab-button>
      </ion-tab-bar>
    </ion-tabs>
  `,
})
export class TabsPage {
  constructor() {
    addIcons({ home, search, person });
  }
}
```

### Critical Tab Rules:
1. Each tab has its own navigation stack. Pushing a detail page from Tab 1 does NOT affect Tab 2's stack.
2. **❌ NEVER** use `routerLink` with absolute paths inside tabs. It destroys the tab stack.
3. **✅ ALWAYS** use relative navigation or `NavController` for in-tab navigation.

## 4. Programmatic Navigation

```typescript
import { NavController } from '@ionic/angular/standalone';

export class ProductListPage {
  private readonly navCtrl = inject(NavController);

  // ✅ Push onto the stack (forward navigation with animation)
  goToDetail(productId: string): void {
    this.navCtrl.navigateForward(`/detail/${productId}`);
  }

  // ✅ Pop from the stack (back navigation with animation)
  goBack(): void {
    this.navCtrl.back();
  }

  // ✅ Replace the current page (no back button, like login → dashboard)
  goToRoot(): void {
    this.navCtrl.navigateRoot('/tabs/home');
  }
}
```

## 5. Modal Presentation

Modals are a core mobile pattern. Ionic provides two styles: **full-screen modals** and **bottom sheets**.

```typescript
import { ModalController } from '@ionic/angular/standalone';

export class OrderPage {
  private readonly modalCtrl = inject(ModalController);

  async openFilter(): Promise<void> {
    const modal = await this.modalCtrl.create({
      component: FilterModalComponent,
      componentProps: {
        currentFilters: this.filters(),
      },
      // Bottom sheet style (iOS-native feel)
      breakpoints: [0, 0.5, 0.75, 1],
      initialBreakpoint: 0.5,
      backdropDismiss: true,
      showBackdrop: true,
      handle: true, // Shows the drag handle
    });

    await modal.present();

    // Wait for the modal to close and get the returned data
    const { data, role } = await modal.onDidDismiss<FilterResult>();
    if (role === 'confirm' && data) {
      this.filters.set(data);
      this.applyFilters();
    }
  }
}

// filter-modal.component.ts
export class FilterModalComponent {
  private readonly modalCtrl = inject(ModalController);

  // Receive data from the parent via componentProps
  readonly currentFilters = input.required<FilterResult>();

  cancel(): void {
    this.modalCtrl.dismiss(null, 'cancel');
  }

  apply(): void {
    this.modalCtrl.dismiss(this.buildFilters(), 'confirm');
  }
}
```

## 6. Action Sheets & Alerts

```typescript
import { ActionSheetController, AlertController } from '@ionic/angular/standalone';

export class ItemPage {
  private readonly actionSheetCtrl = inject(ActionSheetController);
  private readonly alertCtrl = inject(AlertController);

  async showOptions(): Promise<void> {
    const actionSheet = await this.actionSheetCtrl.create({
      header: 'Item Options',
      buttons: [
        { text: 'Edit', icon: 'create', handler: () => this.edit() },
        { text: 'Share', icon: 'share', handler: () => this.share() },
        { text: 'Delete', icon: 'trash', role: 'destructive', handler: () => this.confirmDelete() },
        { text: 'Cancel', role: 'cancel' },
      ],
    });
    await actionSheet.present();
  }

  async confirmDelete(): Promise<void> {
    const alert = await this.alertCtrl.create({
      header: 'Delete Item',
      message: 'This action cannot be undone.',
      buttons: [
        { text: 'Cancel', role: 'cancel' },
        { text: 'Delete', role: 'destructive', handler: () => this.deleteItem() },
      ],
    });
    await alert.present();
  }
}
```

## 7. Deep Linking with Capacitor

```typescript
// core/plugins/deep-link.service.ts
import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';
import { App, URLOpenListenerEvent } from '@capacitor/app';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class DeepLinkService {
  private readonly router = inject(Router);

  initialize(): void {
    if (!Capacitor.isNativePlatform()) return;

    App.addListener('appUrlOpen', (event: URLOpenListenerEvent) => {
      // Example: myapp://tabs/detail/123 or https://myapp.com/detail/123
      const slug = event.url.split('.com').pop();
      if (slug) {
        this.router.navigateByUrl(slug);
      }
    });
  }
}
```

---

**Execution Protocol**
1. **Always use `ion-router-outlet`**: Never use Angular's standard `router-outlet` in an Ionic app.
2. **Always lazy-load pages**: Use `loadComponent` for every page route.
3. **Use `NavController` for mobile-correct animations**: `navigateForward()` animates forward, `back()` animates backward, `navigateRoot()` replaces without animation.
4. **Always dismiss modals properly**: Use `modalCtrl.dismiss(data, role)` to return data. Never close modals by navigating away.
5. **Tab navigation is relative**: Within tabs, never use absolute paths that break the tab stack.

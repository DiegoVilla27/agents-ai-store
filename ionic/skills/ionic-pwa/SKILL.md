---
name: ionic-pwa
description: The ultimate architectural standard for Progressive Web Apps (PWA) with Ionic, Angular Service Worker (@angular/pwa), Web App Manifest, and Cache Strategies.
author: Diego Villanueva
trigger: When configuring PWAs, setting up service workers, handling app install prompts, or optimizing web delivery in Ionic.
---

# Enterprise Ionic PWA Architecture

Ionic apps are inherently web applications. With Progressive Web App (PWA) capabilities, your Ionic app can be installed directly from any mobile or desktop browser with offline support and zero App Store fees or approval delays.

---

## 1. Enabling Angular Service Worker

```bash
ng add @angular/pwa
```

This generates `ngsw-config.json`, `manifest.webmanifest`, and registers `provideServiceWorker` in `app.config.ts`.

```typescript
// app.config.ts
import { isDevMode } from '@angular/core';
import { provideServiceWorker } from '@angular/service-worker';

export const appConfig: ApplicationConfig = {
  providers: [
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode(),
      // Register SW immediately after app is stable
      registrationStrategy: 'registerWhenStable:30000',
    }),
  ],
};
```

---

## 2. Advanced Cache Configuration (`ngsw-config.json`)

Configure asset caching (offline shell) and data caching (API requests):

```json
{
  "$schema": "./node_modules/@angular/service-worker/config/schema.json",
  "index": "/index.html",
  "assetGroups": [
    {
      "name": "app-shell",
      "installMode": "prefetch",
      "resources": {
        "files": [
          "/favicon.ico",
          "/index.html",
          "/manifest.webmanifest",
          "/*.css",
          "/*.js"
        ]
      }
    },
    {
      "name": "assets",
      "installMode": "lazy",
      "updateMode": "prefetch",
      "resources": {
        "files": [
          "/assets/**",
          "/*.(svg|cur|jpg|jpeg|png|apng|webp|avif|gif|otf|ttf|woff|woff2)"
        ]
      }
    }
  ],
  "dataGroups": [
    {
      "name": "api-freshness",
      "urls": ["/api/v1/user/**", "/api/v1/feed/**"],
      "cacheConfig": {
        "maxSize": 100,
        "maxAge": "1h",
        "timeout": "3s",
        "strategy": "freshness"
      }
    },
    {
      "name": "api-performance",
      "urls": ["/api/v1/static-data/**"],
      "cacheConfig": {
        "maxSize": 50,
        "maxAge": "7d",
        "strategy": "performance"
      }
    }
  ]
}
```

---

## 3. PWA Update Notification Flow

Notify users when a new version of the app is available on the server:

```typescript
// core/pwa/pwa-update.service.ts
import { Injectable, inject } from '@angular/core';
import { SwUpdate, VersionReadyEvent } from '@angular/service-worker';
import { ToastController } from '@ionic/angular/standalone';
import { filter } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class PwaUpdateService {
  private readonly swUpdate = inject(SwUpdate);
  private readonly toastCtrl = inject(ToastController);

  initialize(): void {
    if (!this.swUpdate.isEnabled) return;

    // Check for updates periodically
    setInterval(() => this.swUpdate.checkForUpdate(), 6 * 60 * 60 * 1000); // 6 hours

    this.swUpdate.versionUpdates
      .pipe(filter((evt): evt is VersionReadyEvent => evt.type === 'VERSION_READY'))
      .subscribe(() => {
        this.promptUserToUpdate();
      });
  }

  private async promptUserToUpdate(): Promise<void> {
    const toast = await this.toastCtrl.create({
      header: 'App Update Available',
      message: 'A new version of the app is available. Reload to update?',
      position: 'bottom',
      buttons: [
        {
          text: 'Reload',
          role: 'confirm',
          handler: () => {
            this.swUpdate.activateUpdate().then(() => document.location.reload());
          },
        },
        { text: 'Later', role: 'cancel' },
      ],
    });
    await toast.present();
  }
}
```

---

## 4. Custom PWA Install Prompt Banner

Capture `beforeinstallprompt` and display a native-styled Ionic prompt:

```typescript
// core/pwa/pwa-install.service.ts
import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class PwaInstallService {
  private deferredPrompt: any = null;
  readonly canInstall = signal(false);

  constructor() {
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      this.deferredPrompt = e;
      this.canInstall.set(true);
    });

    window.addEventListener('appinstalled', () => {
      this.deferredPrompt = null;
      this.canInstall.set(false);
    });
  }

  async promptInstall(): Promise<boolean> {
    if (!this.deferredPrompt) return false;

    this.deferredPrompt.prompt();
    const { outcome } = await this.deferredPrompt.userChoice;
    this.deferredPrompt = null;
    this.canInstall.set(false);
    return outcome === 'accepted';
  }
}
```

---

**Execution Protocol**
1. **Always configure both `assetGroups` and `dataGroups`**: Ensure instant offline shell rendering and proper API caching.
2. **Never force unannounced page reloads on SW update**: Always use `SwUpdate` with a user-friendly Toast prompt.
3. **Customize `manifest.webmanifest` completely**: Include `theme_color`, `background_color`, proper icons (192x192, 512x512 maskable).
4. **Test offline behavior thoroughly**: Verify app functions correctly in Chrome DevTools offline mode.

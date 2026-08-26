---
name: ionic-capacitor
description: The ultimate architectural standard for Capacitor 6+ Native Bridge, Plugin Architecture, Multi-Platform Configuration, and Angular Service Wrapping.
author: Diego Villanueva
trigger: When integrating native device features, configuring Capacitor plugins, accessing the native bridge, or managing platform-specific behavior.
---

# Enterprise Capacitor Architecture (v6+)

Capacitor is Ionic's native bridge, replacing Cordova entirely. It provides modern async/await APIs, first-class TypeScript support, and direct access to native iOS (Swift) and Android (Kotlin/Java) SDKs from your Angular codebase.

## 1. Capacitor Configuration (`capacitor.config.ts`)

The Capacitor configuration file controls all native project settings. ALWAYS use the TypeScript version for type safety.

```typescript
// capacitor.config.ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.enterprise.myapp',
  appName: 'MyApp',
  webDir: 'www', // Angular build output (dist/app/browser for newer Angular)
  server: {
    // Production: Remove this block entirely
    // Development: Enable live reload from your dev server
    url: 'http://192.168.1.100:4200',
    cleartext: true, // Allow HTTP in dev (Android requires this)
  },
  plugins: {
    SplashScreen: {
      launchAutoHide: false, // Manually hide after data loads
      androidScaleType: 'CENTER_CROP',
    },
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#1a1a2e',
    },
    Keyboard: {
      resize: 'body', // Prevents content from being pushed up on iOS
      resizeOnFullScreen: true,
    },
  },
  ios: {
    scheme: 'MyApp', // Custom URL scheme for deep links
  },
  android: {
    buildOptions: {
      keystorePath: undefined, // Set in CI/CD
    },
  },
};

export default config;
```

## 2. Plugin Wrapping Pattern (The Golden Rule)

Components and pages MUST NEVER call Capacitor plugins directly. Every plugin MUST be wrapped in an Angular `@Injectable` service.

**Why?**
1. **Testability**: You can mock the service in tests. You cannot mock a static Capacitor import.
2. **Abstraction**: If a plugin API changes, you update one service, not 50 components.
3. **Platform Safety**: The service handles platform checks internally.

```typescript
// ❌ ATROCIOUS: Direct plugin call in a component
import { Camera, CameraResultType } from '@capacitor/camera';

export class ProfilePage {
  async takePhoto() {
    const photo = await Camera.getPhoto({ resultType: CameraResultType.Uri }); // CRASHES in tests
  }
}

// ✅ ALWAYS: Wrapped in an Injectable Service
// core/plugins/camera.service.ts
import { Injectable } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import { Camera, CameraResultType, CameraSource, Photo } from '@capacitor/camera';

@Injectable({ providedIn: 'root' })
export class CameraService {
  private readonly isNative = Capacitor.isNativePlatform();

  async takePhoto(): Promise<Photo | null> {
    if (!this.isNative) {
      // Graceful web fallback or file input trigger
      console.warn('Camera not available on web. Use file input.');
      return null;
    }

    const permissions = await Camera.checkPermissions();
    if (permissions.camera !== 'granted') {
      const request = await Camera.requestPermissions();
      if (request.camera !== 'granted') {
        throw new Error('Camera permission denied');
      }
    }

    return Camera.getPhoto({
      quality: 90,
      allowEditing: false,
      resultType: CameraResultType.Uri,
      source: CameraSource.Camera,
      width: 1024,
      height: 1024,
    });
  }
}
```

## 3. Plugin Initialization Service

Plugins that require early setup (Push Notifications, Deep Links, App State listeners) MUST be initialized via `APP_INITIALIZER` in a centralized service.

```typescript
// core/plugins/capacitor-init.service.ts
import { Injectable } from '@angular/core';
import { App } from '@capacitor/app';
import { StatusBar, Style } from '@capacitor/status-bar';
import { SplashScreen } from '@capacitor/splash-screen';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class CapacitorInitService {
  async initialize(): Promise<void> {
    if (!Capacitor.isNativePlatform()) return;

    // Configure Status Bar
    await StatusBar.setStyle({ style: Style.Dark });
    await StatusBar.setBackgroundColor({ color: '#1a1a2e' });

    // Listen to App State changes (background/foreground)
    App.addListener('appStateChange', ({ isActive }) => {
      if (isActive) {
        console.log('App resumed from background');
        // Refresh auth token, reconnect WebSocket, etc.
      }
    });

    // Listen to back button (Android)
    App.addListener('backButton', ({ canGoBack }) => {
      if (!canGoBack) {
        App.exitApp();
      }
    });

    // Hide splash screen after initialization
    await SplashScreen.hide({ fadeOutDuration: 300 });
  }
}

// app.config.ts
import { APP_INITIALIZER } from '@angular/core';

export const appConfig: ApplicationConfig = {
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: (init: CapacitorInitService) => () => init.initialize(),
      deps: [CapacitorInitService],
      multi: true,
    },
    // ... other providers
  ],
};
```

## 4. Platform-Safe Service Pattern

When a feature uses native APIs that don't exist on the web, ALWAYS implement a platform-safe pattern:

```typescript
// core/plugins/haptics.service.ts
import { Injectable } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import { Haptics, ImpactStyle, NotificationType } from '@capacitor/haptics';

@Injectable({ providedIn: 'root' })
export class HapticsService {
  private readonly isNative = Capacitor.isNativePlatform();

  async impact(style: ImpactStyle = ImpactStyle.Medium): Promise<void> {
    if (!this.isNative) return; // Silent no-op on web
    await Haptics.impact({ style });
  }

  async notification(type: NotificationType = NotificationType.Success): Promise<void> {
    if (!this.isNative) return;
    await Haptics.notification({ type });
  }

  async vibrate(duration = 300): Promise<void> {
    if (!this.isNative) {
      // Web Vibration API fallback
      if ('vibrate' in navigator) navigator.vibrate(duration);
      return;
    }
    await Haptics.vibrate({ duration });
  }
}
```

## 5. Adding Native Platforms

```bash
# Add iOS and Android native projects
npx cap add ios
npx cap add android

# After building Angular app, sync web assets to native projects
ng build --configuration=production
npx cap sync

# Open native IDEs
npx cap open ios     # Opens Xcode
npx cap open android # Opens Android Studio

# Live reload during development
npx cap run ios --livereload --external
npx cap run android --livereload --external
```

## 6. Permission Handling Architecture

ALWAYS follow this permission flow for any native capability:

```typescript
async requestPermissionSafely(plugin: 'camera' | 'geolocation' | 'notifications'): Promise<boolean> {
  const permissionMap = {
    camera: { check: Camera.checkPermissions, request: Camera.requestPermissions },
    geolocation: { check: Geolocation.checkPermissions, request: Geolocation.requestPermissions },
    notifications: { check: PushNotifications.checkPermissions, request: PushNotifications.requestPermissions },
  };

  const { check, request } = permissionMap[plugin];

  // Step 1: Check current status
  const status = await check();
  const key = Object.keys(status)[0] as string;
  
  if (status[key] === 'granted') return true;
  if (status[key] === 'denied') {
    // User permanently denied → Guide them to Settings
    await this.showSettingsDialog(plugin);
    return false;
  }

  // Step 2: Request permission
  const result = await request();
  return result[key] === 'granted';
}
```

---

**Execution Protocol**
1. **Never call Capacitor plugins from components**: Always use injectable service wrappers.
2. **Always check `Capacitor.isNativePlatform()`**: Before calling any native-only API.
3. **Always handle permissions gracefully**: Check → Request → Guide to Settings if permanently denied.
4. **Always run `npx cap sync`**: After every `ng build` before testing on native devices.
5. **Never commit `server.url` in `capacitor.config.ts`**: It is for development only. Use environment-based config or remove it before production builds.

---
name: ionic-deployment
description: The ultimate architectural standard for Enterprise Mobile CI/CD, Live Updates (OTA), Fastlane, Appflow, Xcode/Android Studio configurations, and Store Releases.
author: Diego Villanueva
trigger: When configuring build pipelines, automating iOS/Android store deployments, setting up Over-The-Air (OTA) updates, or managing signing certificates.
---

# Enterprise Ionic Deployment & CI/CD Architecture

Shipping enterprise hybrid mobile apps requires robust Over-The-Air (OTA) update pipelines, automated Fastlane release workflows, and strict native signing management for Apple App Store and Google Play.

---

## 1. Over-The-Air (OTA) Live Updates (`@capgo/capacitor-updater`)

With OTA live updates, bug fixes and feature updates to the web bundle (HTML/CSS/JS) can be deployed instantly to users' devices **without going through Apple/Google Store review**.

```bash
npm install @capgo/capacitor-updater
npx cap sync
```

```typescript
// core/deployment/live-update.service.ts
import { Injectable, signal } from '@angular/core';
import { CapacitorUpdater } from '@capgo/capacitor-updater';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class LiveUpdateService {
  readonly isUpdating = signal(false);

  async checkForLiveUpdate(): Promise<void> {
    if (!Capacitor.isNativePlatform()) return;

    try {
      // Notify updater that current bundle launched successfully (prevents auto-rollback)
      await CapacitorUpdater.notifyAppReady();

      // Check for remote update package
      const version = await CapacitorUpdater.download({
        url: 'https://updates.enterprise.com/bundles/latest.zip',
        version: '1.2.4',
      });

      if (version) {
        // Set new bundle to be loaded on next app restart
        await CapacitorUpdater.set(version);
        console.log('[LiveUpdate] Update ready for next restart');
      }
    } catch (err) {
      console.warn('[LiveUpdate] Update check skipped or failed:', err);
    }
  }
}
```

---

## 2. Automated Mobile CI/CD with Fastlane

### iOS Fastlane (`ios/fastlane/Fastfile`)

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    setup_ci if ENV['CI']
    match(type: "appstore", readonly: true)
    increment_build_number(xcodeproj: "App.xcodeproj")
    build_app(
      workspace: "App.xcworkspace",
      scheme: "App",
      export_method: "app-store"
    )
    upload_to_testflight(skip_waiting_for_build_processing: true)
  end

  desc "Release to Apple App Store"
  lane :release do
    match(type: "appstore", readonly: true)
    build_app(workspace: "App.xcworkspace", scheme: "App")
    upload_to_app_store(force: true)
  end
end
```

### Android Fastlane (`android/fastlane/Fastfile`)

```ruby
default_platform(:android)

platform :android do
  desc "Build Android App Bundle (.aab) and upload to Google Play Internal Track"
  lane :internal do
    gradle(task: "bundleRelease")
    upload_to_play_store(
      track: 'internal',
      aab: 'app/build/outputs/bundle/release/app-release.aab'
    )
  end
end
```

---

## 3. GitHub Actions CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Build & Deploy Mobile Apps

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Build Web Assets
        run: npm run build -- --configuration=production

      - name: Capacitor Sync
        run: npx cap sync

      - name: Setup Ruby for Fastlane
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Deploy iOS TestFlight
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_KEY }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        run: |
          cd ios
          bundle exec fastlane beta
```

---

## 4. Production Build Optimization Checklist

1. **Angular AOT & Tree-Shaking**: Verify `optimization: true` and `buildOptimizer: true` in `angular.json`.
2. **Capacitor Android Keystore**: Store keystores strictly in CI/CD secrets; never commit `.jks` files to git.
3. **App Icons & Splash Screens**: Generate all platform resolutions automatically:
   ```bash
   npx @capacitor/assets generate --iconBackgroundColor '#1a1a2e' --splashBackgroundColor '#1a1a2e'
   ```

---

**Execution Protocol**
1. **Always use Fastlane match for iOS signing**: Eliminates manual provisioning profile conflicts.
2. **Always call `CapacitorUpdater.notifyAppReady()` on launch**: Prevents automatic rollbacks on successful OTA boots.
3. **Always build Android releases as Android App Bundle (`.aab`)**: Google Play mandates `.aab` for dynamic feature delivery.
4. **Never commit native signing secrets or keystores**: Use CI/CD repository secrets exclusively.

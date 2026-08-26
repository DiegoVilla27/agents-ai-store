---
name: ionic-i18n
description: The ultimate architectural standard for Internationalization (i18n), Transloco/ngx-translate, RTL Layouts, and Device Locale Detection in Ionic.
author: Diego Villanueva
trigger: When configuring multi-language support, managing localization keys, detecting native device locale, or implementing RTL layouts (Arabic/Hebrew) in Ionic.
---

# Enterprise Ionic Internationalization (i18n) Architecture

Global mobile applications must dynamically adapt to the user's native language, currency, number formats, and text direction (LTR / RTL).

---

## 1. Native Device Locale Detection (`@capacitor/device`)

Detect the user's OS language settings and set the active application locale at bootstrap:

```typescript
// core/i18n/locale-detector.service.ts
import { Injectable } from '@angular/core';
import { Device } from '@capacitor/device';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class LocaleDetectorService {
  async getDeviceLanguage(): Promise<string> {
    if (Capacitor.isNativePlatform()) {
      const code = await Device.getLanguageCode(); // e.g. 'es', 'en', 'ar'
      return code.value;
    }
    // Web fallback
    return navigator.language.split('-')[0] || 'en';
  }
}
```

---

## 2. Transloco Standalone Configuration

Transloco is the modern, signal-ready, tree-shakeable translation library for modern Angular and Ionic.

```typescript
// app.config.ts
import { provideTransloco, translocoConfig } from '@jsverse/transloco';
import { isDevMode } from '@angular/core';
import { TranslocoHttpLoader } from './core/i18n/transloco-loader';

export const appConfig: ApplicationConfig = {
  providers: [
    provideTransloco({
      config: translocoConfig({
        availableLangs: ['en', 'es', 'fr', 'ar', 'de'],
        defaultLang: 'en',
        fallbackLang: 'en',
        reRenderOnLangChange: true,
        prodMode: !isDevMode(),
      }),
      loader: TranslocoHttpLoader,
    }),
  ],
};
```

---

## 3. Template Usage with Ionic Components

```html
<ion-header>
  <ion-toolbar>
    <!-- Transloco Pipe with Ionic Title -->
    <ion-title>{{ 'dashboard.title' | transloco }}</ion-title>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding" *transloco="let t">
  <ion-card>
    <ion-card-header>
      <ion-card-title>{{ t('auth.welcome', { name: userName() }) }}</ion-card-title>
    </ion-card-header>
    <ion-card-content>
      <ion-button expand="block">
        {{ t('common.actions.submit') }}
      </ion-button>
    </ion-card-content>
  </ion-card>
</ion-content>
```

---

## 4. Right-To-Left (RTL) Support (Arabic, Hebrew)

Ionic has built-in bidirectional styling (CSS Logical Properties). Setting `dir="rtl"` on `<html>` or `ion-app` automatically mirrors toolbars, back-buttons, list icons, and gestures.

```typescript
// core/i18n/i18n.service.ts
import { Injectable, inject, signal } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { PreferencesService } from '@core/services/preferences.service';
import { LocaleDetectorService } from './locale-detector.service';

const RTL_LANGUAGES = ['ar', 'he', 'fa', 'ur'];

@Injectable({ providedIn: 'root' })
export class I18nService {
  private readonly transloco = inject(TranslocoService);
  private readonly prefs = inject(PreferencesService);
  private readonly detector = inject(LocaleDetectorService);

  readonly currentLang = signal('en');
  readonly isRTL = signal(false);

  async init(): Promise<void> {
    const savedLang = await this.prefs.get<string>('app_language');
    const deviceLang = await this.detector.getDeviceLanguage();
    const activeLang = savedLang || deviceLang || 'en';

    await this.setLanguage(activeLang);
  }

  async setLanguage(lang: string): Promise<void> {
    this.transloco.setActiveLang(lang);
    this.currentLang.set(lang);

    const isRtl = RTL_LANGUAGES.includes(lang);
    this.isRTL.set(isRtl);

    // Apply document-level RTL attributes
    document.documentElement.dir = isRtl ? 'rtl' : 'ltr';
    document.documentElement.lang = lang;

    await this.prefs.set('app_language', lang);
  }
}
```

---

**Execution Protocol**
1. **Always use CSS Logical Properties**: Use `margin-inline-start`, `padding-inline-end` instead of `margin-left` or `padding-right` so RTL flipping is automatic.
2. **Never hardcode user-facing strings**: All text in templates and TypeScript alerts/toasts must use translation keys.
3. **Detect OS locale on first launch**: Set default language seamlessly without forcing manual user selection.
4. **Lazy-load language JSON files**: Never bundle all language files into the main JS bundle.

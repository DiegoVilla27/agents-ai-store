---
name: lit-i18n
description: The definitive standard for internationalization in Lit using @lit/localize for message extraction, localized templates, and runtime/build-time locale switching.
author: Diego Villanueva
trigger: When implementing internationalization in Lit, using @lit/localize, extracting messages, switching locales, or building multi-language web components.
---

# Lit i18n Mastery (@lit/localize)

`@lit/localize` provides first-class internationalization for Lit with static analysis, message extraction, XLIFF support, and two modes: runtime (dynamic switching) and build-time (zero-overhead bundles).

---

## 1. Setup

```bash
npm install @lit/localize
npm install -D @lit/localize-tools
```

### `lit-localize.json` Configuration

```json
{
  "$schema": "https://raw.githubusercontent.com/lit/lit/main/packages/localize-tools/config.schema.json",
  "sourceLocale": "en",
  "targetLocales": ["es", "fr", "de", "ja"],
  "inputFiles": ["src/**/*.ts"],
  "output": {
    "mode": "runtime",
    "outputDir": "src/generated/locales"
  },
  "interchange": {
    "format": "xliff",
    "xliffDir": "xliff/"
  }
}
```

---

## 2. Marking Messages for Translation

### A. `msg()` — Simple Messages

```typescript
import { msg } from '@lit/localize';

render() {
  return html`
    <h1>${msg('Welcome to our platform')}</h1>
    <p>${msg('Sign in to continue')}</p>
    <button>${msg('Get Started')}</button>
  `;
}
```

### B. `msg()` with Expressions

```typescript
render() {
  return html`
    <p>${msg(html`Hello, <strong>${this.userName}</strong>!`)}</p>
    <p>${msg(str`You have ${this.count} notifications`)}</p>
  `;
}
```

### C. `msg()` with Custom IDs

```typescript
// Custom ID for stable translation keys
render() {
  return html`
    <button>${msg('Submit', { id: 'form-submit-button' })}</button>
  `;
}
```

### D. `str` — String-Only Messages (No HTML)

```typescript
import { msg, str } from '@lit/localize';

// For attributes and non-template contexts
render() {
  return html`
    <input
      placeholder=${msg(str`Enter your email`)}
      aria-label=${msg(str`Email address`)}
    >
    <img alt=${msg(str`User avatar for ${this.userName}`)}>
  `;
}
```

---

## 3. Runtime Mode — Dynamic Locale Switching

### A. Configuration

```typescript
// src/localization.ts
import { configureLocalization } from '@lit/localize';
import { sourceLocale, targetLocales } from './generated/locale-codes.js';

export const { getLocale, setLocale } = configureLocalization({
  sourceLocale,
  targetLocales,
  loadLocale: (locale: string) => import(`./generated/locales/${locale}.js`),
});
```

### B. Language Switcher Component

```typescript
import { LitElement, html } from 'lit';
import { customElement, state } from 'lit/decorators.js';
import { getLocale, setLocale } from '../localization.js';

@customElement('locale-switcher')
export class LocaleSwitcher extends LitElement {
  @state() private _currentLocale = getLocale();

  private _locales = [
    { code: 'en', label: 'English', flag: '🇺🇸' },
    { code: 'es', label: 'Español', flag: '🇪🇸' },
    { code: 'fr', label: 'Français', flag: '🇫🇷' },
    { code: 'de', label: 'Deutsch', flag: '🇩🇪' },
    { code: 'ja', label: '日本語', flag: '🇯🇵' },
  ];

  private async _changeLocale(locale: string) {
    await setLocale(locale);
    this._currentLocale = locale;
    localStorage.setItem('locale', locale);
    // Lit automatically re-renders all components using msg()
  }

  render() {
    return html`
      <div class="locale-select" role="radiogroup" aria-label="Language">
        ${this._locales.map(l => html`
          <button
            role="radio"
            aria-checked=${this._currentLocale === l.code}
            @click=${() => this._changeLocale(l.code)}
          >${l.flag} ${l.label}</button>
        `)}
      </div>
    `;
  }
}
```

---

## 4. Build-Time Mode — Zero-Overhead

Build-time mode generates a separate bundle per locale with pre-compiled translations (no runtime lookup):

```json
{
  "output": {
    "mode": "build",
    "outputDir": "src/generated/locales",
    "localeCodesModule": "src/generated/locale-codes.js"
  }
}
```

Benefits:
- ✅ Zero runtime overhead — translations are inlined at build time.
- ✅ Smaller bundle — no translation lookup code shipped.
- Trade-off: Requires a full page reload to switch locales (no dynamic switching).

---

## 5. Extraction & Translation Workflow

```bash
# 1. Extract messages from source code
npx lit-localize extract

# 2. Translators edit generated XLIFF files in xliff/ directory
# Example: xliff/es.xlf, xliff/fr.xlf

# 3. Build translations back into runtime JS modules
npx lit-localize build
```

### XLIFF File Example

```xml
<!-- xliff/es.xlf -->
<xliff version="1.2">
  <file source-language="en" target-language="es">
    <body>
      <trans-unit id="form-submit-button">
        <source>Submit</source>
        <target>Enviar</target>
      </trans-unit>
      <trans-unit id="s7e18f29b">
        <source>Welcome to our platform</source>
        <target>Bienvenido a nuestra plataforma</target>
      </trans-unit>
    </body>
  </file>
</xliff>
```

---

## 6. Pluralization & Complex Messages

```typescript
import { msg, str } from '@lit/localize';

render() {
  const count = this.notificationCount;

  return html`
    <p>
      ${msg(str`${count === 0
        ? 'No notifications'
        : count === 1
          ? '1 notification'
          : `${count} notifications`
      }`)}
    </p>
  `;
}
```

---

## 7. Rules

- ✅ Wrap ALL user-visible strings in `msg()` or `msg(str\`...\`)`.
- ✅ Use `str` for attribute values (placeholder, alt, aria-label).
- ✅ Use custom `id` for stable translation keys across refactors.
- ✅ Persist locale in `localStorage` and restore on page load.
- ✅ Use runtime mode for dynamic apps, build-time mode for static sites.
- ❌ **NEVER** hardcode user-visible strings without `msg()`.
- ❌ **NEVER** concatenate translated strings manually — use template expressions inside `msg()`.
- ❌ **NEVER** forget to run `lit-localize extract` after adding new messages.

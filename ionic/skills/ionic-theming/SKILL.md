---
name: ionic-theming
description: The ultimate architectural standard for Ionic Theming with CSS Custom Properties, Dark/Light Mode, Platform-Specific Styling, and Design Tokens.
author: Diego Villanueva
trigger: When configuring themes, customizing Ionic component styles, implementing dark mode, or creating a design system for an Ionic app.
---

# Enterprise Ionic Theming Architecture (v8+)

Ionic's theming engine is built entirely on **CSS Custom Properties (CSS Variables)**. Every color, size, font, and shadow in Ionic can be customized without touching component internals. This enables enterprise-grade Design Systems with zero CSS hacks.

## 1. Global Theme Configuration (`variables.scss`)

The `src/theme/variables.scss` file is the single source of truth for your app's visual identity.

```scss
// src/theme/variables.scss
:root {
  // Primary Brand Colors
  --ion-color-primary: #4f46e5;
  --ion-color-primary-rgb: 79, 70, 229;
  --ion-color-primary-contrast: #ffffff;
  --ion-color-primary-contrast-rgb: 255, 255, 255;
  --ion-color-primary-shade: #4640ca;
  --ion-color-primary-tint: #6158e8;

  // Secondary
  --ion-color-secondary: #06b6d4;
  --ion-color-secondary-rgb: 6, 182, 212;
  --ion-color-secondary-contrast: #ffffff;
  --ion-color-secondary-contrast-rgb: 255, 255, 255;
  --ion-color-secondary-shade: #05a0bb;
  --ion-color-secondary-tint: #1fbdd8;

  // Success
  --ion-color-success: #10b981;
  --ion-color-success-rgb: 16, 185, 129;
  --ion-color-success-contrast: #ffffff;
  --ion-color-success-contrast-rgb: 255, 255, 255;
  --ion-color-success-shade: #0ea372;
  --ion-color-success-tint: #28c08e;

  // Warning
  --ion-color-warning: #f59e0b;
  --ion-color-warning-rgb: 245, 158, 11;
  --ion-color-warning-contrast: #000000;
  --ion-color-warning-contrast-rgb: 0, 0, 0;
  --ion-color-warning-shade: #d88b0a;
  --ion-color-warning-tint: #f6a823;

  // Danger
  --ion-color-danger: #ef4444;
  --ion-color-danger-rgb: 239, 68, 68;
  --ion-color-danger-contrast: #ffffff;
  --ion-color-danger-contrast-rgb: 255, 255, 255;
  --ion-color-danger-shade: #d23c3c;
  --ion-color-danger-tint: #f15757;

  // Typography
  --ion-font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;

  // Spacing & Radius
  --ion-padding: 16px;
  --ion-margin: 16px;
  --border-radius: 12px;
}
```

## 2. Dark Mode Implementation

Ionic supports dark mode natively using the `prefers-color-scheme` media query and the `.ion-palette-dark` class.

```scss
// Automatic dark mode (follows system preference)
@media (prefers-color-scheme: dark) {
  :root {
    --ion-background-color: #0f0f23;
    --ion-background-color-rgb: 15, 15, 35;

    --ion-text-color: #e2e8f0;
    --ion-text-color-rgb: 226, 232, 240;

    --ion-card-background: #1a1a3e;
    --ion-item-background: #1a1a3e;
    --ion-toolbar-background: #0f0f23;
    --ion-tab-bar-background: #0f0f23;

    --ion-color-primary: #818cf8;
    --ion-color-primary-contrast: #0f0f23;
  }
}
```

### Manual Dark Mode Toggle

```typescript
// core/services/theme.service.ts
@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
  readonly isDark = signal(this.prefersDark.matches);

  constructor() {
    // Listen to system changes
    this.prefersDark.addEventListener('change', (e) => {
      this.isDark.set(e.matches);
      this.applyTheme(e.matches);
    });

    // Apply on init
    this.applyTheme(this.isDark());
  }

  toggle(): void {
    this.isDark.update(v => !v);
    this.applyTheme(this.isDark());
  }

  private applyTheme(dark: boolean): void {
    document.documentElement.classList.toggle('ion-palette-dark', dark);
  }
}
```

## 3. Custom Color Generation

To create a custom color that works with Ionic's `color` property (e.g., `<ion-button color="brand">`), you MUST define the full color set:

```scss
// Add a custom "brand" color
:root {
  --ion-color-brand: #7c3aed;
  --ion-color-brand-rgb: 124, 58, 237;
  --ion-color-brand-contrast: #ffffff;
  --ion-color-brand-contrast-rgb: 255, 255, 255;
  --ion-color-brand-shade: #6d33d1;
  --ion-color-brand-tint: #894def;
}

.ion-color-brand {
  --ion-color-base: var(--ion-color-brand);
  --ion-color-base-rgb: var(--ion-color-brand-rgb);
  --ion-color-contrast: var(--ion-color-brand-contrast);
  --ion-color-contrast-rgb: var(--ion-color-brand-contrast-rgb);
  --ion-color-shade: var(--ion-color-brand-shade);
  --ion-color-tint: var(--ion-color-brand-tint);
}
```

```html
<!-- Now usable on any Ionic component -->
<ion-button color="brand">Custom Brand Button</ion-button>
<ion-badge color="brand">New</ion-badge>
```

## 4. Platform-Specific Styling

Ionic applies platform classes to the `<html>` element: `.plt-ios`, `.plt-android`, `.plt-mobileweb`, etc.

```scss
// Platform-specific overrides
.plt-ios {
  --ion-toolbar-background: rgba(255, 255, 255, 0.9);
  --ion-toolbar-color: #000;

  ion-toolbar {
    --background: rgba(255, 255, 255, 0.9);
    backdrop-filter: blur(20px); // iOS frosted glass effect
  }
}

.plt-android {
  --ion-toolbar-background: var(--ion-color-primary);
  --ion-toolbar-color: #ffffff;
}
```

## 5. Component-Level Theming with CSS Shadow Parts

Ionic Web Components use Shadow DOM. To style internal parts, use `::part()`.

```scss
// Style the internal structure of ion-input
ion-input::part(native) {
  border-radius: var(--border-radius);
  background: var(--ion-card-background);
  padding: 12px 16px;
}

// Style ion-card internal parts
ion-card::part(native) {
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}
```

## 6. Safe Area Insets

Modern devices have notches, dynamic islands, and rounded corners. ALWAYS respect safe areas.

```scss
// Automatically handled by ion-content and ion-toolbar
// But for custom absolutely-positioned elements:
.custom-floating-button {
  position: fixed;
  bottom: calc(16px + var(--ion-safe-area-bottom, 0px));
  right: calc(16px + var(--ion-safe-area-right, 0px));
}

.custom-header {
  padding-top: var(--ion-safe-area-top, 0px);
}
```

---

**Execution Protocol**
1. **Always define the full color set**: `base`, `rgb`, `contrast`, `contrast-rgb`, `shade`, and `tint` for any custom color.
2. **Always use CSS Custom Properties**: Never hardcode colors in component styles. Always reference `var(--ion-color-*)`.
3. **Always handle safe areas**: Use `--ion-safe-area-*` variables for any custom positioned elements.
4. **Always use `::part()`**: For styling Shadow DOM internals. Never use `::ng-deep` (deprecated).
5. **Prefer the system dark mode hook**: Use `@media (prefers-color-scheme: dark)` as the default, with a manual toggle as an override.

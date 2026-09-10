---
name: lit-styling-theming
description: The definitive standard for CSS-in-Lit styling, constructable stylesheets, adoptedStyleSheets, CSS custom property theming, shared styles, and design token integration.
author: Diego Villanueva
trigger: When styling Lit components, using the css tagged template, sharing styles between components, theming with CSS custom properties, or integrating design tokens.
---

# Lit Styling & Theming Mastery

Lit leverages native browser capabilities — Shadow DOM CSS scoping and constructable stylesheets — for zero-runtime-cost, encapsulated component styling. This skill covers production patterns for scalable theming systems.

---

## 1. `static styles` — Constructable Stylesheets

```typescript
import { LitElement, css } from 'lit';

@customElement('my-card')
export class MyCard extends LitElement {
  // ✅ Evaluated ONCE per class, shared across all instances via adoptedStyleSheets
  static styles = css`
    :host {
      display: block;
      contain: content;
      border: 1px solid var(--card-border-color, hsl(214 32% 91%));
      border-radius: var(--card-radius, 0.75rem);
      padding: var(--card-padding, 1.5rem);
      background: var(--card-bg, white);
    }

    h2 {
      margin: 0 0 0.5rem;
      font-size: 1.25rem;
      color: var(--card-title-color, hsl(222 47% 11%));
    }
  `;
}
```

### Multiple Style Sheets

```typescript
static styles = [
  resetStyles,       // Shared reset
  typographyStyles,  // Shared typography
  css`
    /* Component-specific styles */
    :host { display: block; }
  `,
];
```

---

## 2. Shared Styles

Create reusable style modules that multiple components import:

```typescript
// styles/reset.styles.ts
import { css } from 'lit';

export const resetStyles = css`
  *, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }
`;

// styles/typography.styles.ts
export const typographyStyles = css`
  h1, h2, h3, h4, h5, h6 {
    font-family: var(--font-heading, system-ui, sans-serif);
    line-height: 1.2;
    letter-spacing: -0.02em;
  }

  p {
    line-height: 1.6;
    color: var(--color-text-muted, hsl(215 16% 47%));
  }
`;

// styles/button.styles.ts
export const buttonStyles = css`
  button {
    font-family: inherit;
    font-size: var(--btn-font-size, 0.875rem);
    font-weight: 600;
    padding: var(--btn-py, 0.5rem) var(--btn-px, 1rem);
    border: none;
    border-radius: var(--btn-radius, 0.5rem);
    cursor: pointer;
    transition: background-color 150ms ease, transform 150ms ease;
  }

  button:hover { filter: brightness(1.1); }
  button:active { transform: scale(0.98); }
  button:disabled { opacity: 0.5; cursor: not-allowed; }
`;
```

### Using Shared Styles

```typescript
import { resetStyles } from '../styles/reset.styles.js';
import { typographyStyles } from '../styles/typography.styles.js';
import { buttonStyles } from '../styles/button.styles.js';

@customElement('settings-form')
export class SettingsForm extends LitElement {
  static styles = [
    resetStyles,
    typographyStyles,
    buttonStyles,
    css`
      :host { display: block; padding: 1.5rem; }
      /* Component-specific styles only */
    `,
  ];
}
```

---

## 3. CSS Custom Properties as Component API

Custom properties pierce the Shadow DOM boundary — use them as your component's **public styling API**:

```typescript
@customElement('app-button')
export class AppButton extends LitElement {
  static styles = css`
    :host {
      display: inline-flex;
    }

    button {
      /* ═══ Public Styling API (documented) ═══ */
      background: var(--app-btn-bg, hsl(220 90% 56%));
      color: var(--app-btn-color, white);
      font-size: var(--app-btn-font-size, 0.875rem);
      padding: var(--app-btn-padding, 0.5rem 1rem);
      border-radius: var(--app-btn-radius, 0.5rem);
      border: var(--app-btn-border, none);
      font-weight: 600;
      cursor: pointer;
      transition: filter 150ms ease;
    }

    button:hover {
      background: var(--app-btn-bg-hover, var(--app-btn-bg, hsl(221 83% 50%)));
    }
  `;
}
```

### Consumer Theming

```css
/* Theme the button from outside — no Shadow DOM piercing needed */
app-button {
  --app-btn-bg: hsl(142 71% 45%);
  --app-btn-bg-hover: hsl(142 76% 36%);
  --app-btn-radius: 9999px;
  --app-btn-padding: 0.75rem 2rem;
}

/* Context-specific theming */
.danger-zone app-button {
  --app-btn-bg: hsl(0 84% 60%);
  --app-btn-bg-hover: hsl(0 72% 51%);
}
```

### Naming Convention
- ✅ Prefix all CSS custom properties with the component tag name: `--app-button-*`, `--data-table-*`.
- This prevents collisions and makes it clear which component a token belongs to.

---

## 4. Dynamic Styles with `classMap` and `styleMap`

```typescript
import { classMap } from 'lit/directives/class-map.js';
import { styleMap } from 'lit/directives/style-map.js';

render() {
  const classes = classMap({
    'card': true,
    'card--elevated': this.elevated,
    'card--interactive': this.clickable,
  });

  const progressStyle = styleMap({
    width: `${this.progress}%`,
    backgroundColor: this.progress >= 100 ? 'var(--color-success)' : 'var(--color-primary)',
  });

  return html`
    <div class=${classes}>
      <div class="progress-bar" style=${progressStyle}></div>
      <slot></slot>
    </div>
  `;
}
```

---

## 5. `unsafeCSS` — Dynamic CSS Values (⚠️ Restricted)

For injecting dynamic values into `static styles`:

```typescript
import { css, unsafeCSS } from 'lit';

const BREAKPOINT_LG = 1024;

static styles = css`
  @media (min-width: ${unsafeCSS(BREAKPOINT_LG)}px) {
    :host { display: grid; grid-template-columns: 250px 1fr; }
  }
`;
```

### Rules
- ⚠️ `unsafeCSS` bypasses Lit's CSS sanitization.
- ✅ ONLY use with **trusted, static values** (constants, config).
- ❌ **NEVER** pass user input to `unsafeCSS` — CSS injection vulnerability.

---

## 6. Design Token System for Lit

```typescript
// styles/tokens.ts
import { css } from 'lit';

export const designTokens = css`
  :host {
    /* Colors */
    --color-primary: hsl(220 90% 56%);
    --color-primary-hover: hsl(221 83% 50%);
    --color-text: hsl(222 47% 11%);
    --color-text-muted: hsl(215 16% 47%);
    --color-surface: hsl(0 0% 100%);
    --color-border: hsl(214 32% 91%);

    /* Spacing */
    --space-1: 0.25rem;
    --space-2: 0.5rem;
    --space-3: 0.75rem;
    --space-4: 1rem;
    --space-6: 1.5rem;
    --space-8: 2rem;

    /* Typography */
    --font-sans: 'Inter', system-ui, sans-serif;
    --text-sm: 0.875rem;
    --text-base: 1rem;
    --text-lg: 1.125rem;
    --text-xl: 1.25rem;

    /* Effects */
    --radius-sm: 0.375rem;
    --radius-md: 0.5rem;
    --radius-lg: 0.75rem;
    --radius-full: 9999px;
    --shadow-sm: 0 1px 2px hsl(0 0% 0% / 0.05);
    --shadow-md: 0 4px 6px -1px hsl(0 0% 0% / 0.1);

    /* Transitions */
    --ease-snappy: cubic-bezier(0.2, 0.8, 0.2, 1);
    --transition-fast: 150ms var(--ease-snappy);
  }
`;
```

### Usage in Components

```typescript
import { designTokens } from '../styles/tokens.js';

@customElement('my-component')
export class MyComponent extends LitElement {
  static styles = [
    designTokens,
    css`
      .title {
        font-size: var(--text-xl);
        color: var(--color-text);
      }
      .card {
        padding: var(--space-6);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow-md);
      }
    `,
  ];
}
```

---

## 7. Rules

- ✅ **ALWAYS** use `static styles` for optimal performance (shared across instances via `adoptedStyleSheets`).
- ✅ Prefix component-specific CSS custom properties with the tag name.
- ✅ Use shared style modules for cross-component consistency.
- ✅ Use CSS custom properties as the public styling API — they pierce Shadow DOM.
- ❌ **NEVER** use `unsafeCSS` with user-provided values.
- ❌ **NEVER** use `<style>` tags inside `render()` for static styles — they create a new stylesheet per instance.
- ❌ **NEVER** use inline `style` attributes for values that should be CSS custom properties.

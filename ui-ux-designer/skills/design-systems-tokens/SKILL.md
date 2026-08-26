---
name: design-systems-tokens
description: The ultimate architectural standard for Enterprise Design Systems and Multi-Tier Design Tokens (Global, Semantic, Component) with CSS Variables and Figma-to-Code Sync.
author: Diego Villanueva
trigger: When structuring design systems, organizing design tokens, bridging Figma variables to CSS/Tailwind, or creating scalable component libraries.
---

# Enterprise Design Systems & Design Tokens Architecture

A Design System is not just a UI kit; it is the shared contract between Design and Engineering. **Design Tokens** are the atomic, platform-agnostic values (colors, spacing, typography, elevation, motion) that ensure seamless consistency across Web, iOS, Android, and Figma.

---

## 1. The 3-Tier Design Token Architecture

```text
┌─────────────────────────────────────────────────────────┐
│ 1. GLOBAL / PRIMITIVE TOKENS (Raw values)              │
│    color-blue-500: #3b82f6 | space-4: 16px | radius-lg: 12px│
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 2. SEMANTIC / ALIAS TOKENS (Contextual purpose)         │
│    surface-primary: var(--color-blue-500)               │
│    text-muted: var(--color-zinc-400)                    │
│    border-focus: var(--color-indigo-600)                │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 3. COMPONENT-SPECIFIC TOKENS (Scoped overrides)         │
│    button-primary-bg: var(--surface-primary)            │
│    card-padding: var(--space-4)                         │
└─────────────────────────────────────────────────────────┘
```

---

## 2. CSS Custom Properties Token Map (`tokens.css`)

```css
/* src/styles/tokens.css */
:root {
  /* Tier 1: Primitive Palette (HSL for fine-grained alpha blending) */
  --primitive-brand-h: 221;
  --primitive-brand-s: 83%;
  --primitive-brand-l: 53%; /* #2563eb */

  --primitive-radius-sm: 0.375rem; /* 6px */
  --primitive-radius-md: 0.5rem;   /* 8px */
  --primitive-radius-lg: 0.75rem;  /* 12px */
  --primitive-radius-xl: 1rem;     /* 16px */
  --primitive-radius-full: 9999px;

  /* Tier 2: Semantic Tokens (Light Theme Default) */
  --bg-canvas: hsl(0, 0%, 100%);
  --bg-surface: hsl(240, 5%, 96%);
  --bg-elevated: hsl(0, 0%, 100%);

  --text-primary: hsl(240, 10%, 4%);
  --text-secondary: hsl(240, 4%, 46%);
  --text-muted: hsl(240, 5%, 65%);

  --border-subtle: hsl(240, 6%, 90%);
  --border-strong: hsl(240, 6%, 80%);

  --action-primary: hsl(var(--primitive-brand-h), var(--primitive-brand-s), var(--primitive-brand-l));
  --action-primary-hover: hsl(var(--primitive-brand-h), var(--primitive-brand-s), 45%);
  --action-primary-text: hsl(0, 0%, 100%);

  /* Elevation Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
}
```

---

## 3. Tailwind CSS Integration with Semantic Tokens

Map semantic variables into Tailwind utility classes so designers and engineers use the exact same vocabulary:

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        canvas: 'var(--bg-canvas)',
        surface: 'var(--bg-surface)',
        elevated: 'var(--bg-elevated)',
        primary: {
          DEFAULT: 'var(--action-primary)',
          hover: 'var(--action-primary-hover)',
          text: 'var(--action-primary-text)',
        },
      },
      textColor: {
        primary: 'var(--text-primary)',
        secondary: 'var(--text-secondary)',
        muted: 'var(--text-muted)',
      },
      borderColor: {
        subtle: 'var(--border-subtle)',
        strong: 'var(--border-strong)',
      },
      borderRadius: {
        sm: 'var(--primitive-radius-sm)',
        md: 'var(--primitive-radius-md)',
        lg: 'var(--primitive-radius-lg)',
        xl: 'var(--primitive-radius-xl)',
      },
    },
  },
};
```

---

## 4. Component Token Binding (Button Spec)

```tsx
// src/components/ui/button.tsx
import { forwardRef } from 'react';
import { cn } from '@/lib/utils';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center rounded-lg font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 active:scale-95 disabled:pointer-events-none disabled:opacity-50',
          {
            'bg-primary text-primary-text hover:bg-primary-hover shadow-sm': variant === 'primary',
            'bg-surface text-primary hover:bg-surface/80 border border-subtle': variant === 'secondary',
            'border border-strong bg-transparent text-primary hover:bg-surface': variant === 'outline',
            'bg-transparent text-secondary hover:bg-surface hover:text-primary': variant === 'ghost',
            'h-8 px-3 text-xs': size === 'sm',
            'h-10 px-4 text-sm': size === 'md',
            'h-12 px-6 text-base': size === 'lg',
          },
          className
        )}
        {...props}
      />
    );
  }
);
```

---

**Execution Protocol**
1. **Never use raw hex colors in UI components**: Always consume Semantic Tokens (`text-primary`, `bg-surface`).
2. **Synchronize with Figma Variables**: Ensure token naming mirrors Figma collection aliases 1-to-1.
3. **Use HSL or OKLCH for dynamic color theming**: Allows transparent overlays with pure CSS `hsl(var(--token) / 0.5)`.

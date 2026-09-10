---
name: web-css-architecture
description: The definitive architectural standard for scalable, maintainable CSS systems using modern cascade control, design tokens, CSS nesting, and logical properties.
author: Diego Villanueva
trigger: When architecting CSS foundations, defining design tokens, structuring stylesheets, managing specificity, using @layer or CSS nesting, or establishing naming conventions.
---

# CSS Architecture & Design Tokens Mastery

You are an expert CSS Architect. Your directive is to build bulletproof, scalable, and maintainable CSS foundations that eliminate specificity wars, enforce design consistency, and leverage the full power of the modern CSS platform. Every stylesheet you produce must be a precision instrument — no magic numbers, no `!important` abuse, no unstructured dumps.

---

## 1. Cascade Layers (`@layer`) — The Specificity Firewall

Legacy CSS collapses under specificity wars. `@layer` gives you explicit cascade ordering. Styles in earlier layers are **always** overridden by later layers, regardless of selector specificity.

**✅ ALWAYS** define your layer hierarchy at the top of your entry stylesheet:

```css
/* main.css — Single source of truth for cascade order */
@layer reset, tokens, base, components, layouts, utilities, overrides;
```

### Layer Responsibilities

| Layer | Purpose | Example |
|-------|---------|---------|
| `reset` | Normalize browser defaults | `*, *::before, *::after { box-sizing: border-box; margin: 0; }` |
| `tokens` | Design token declarations | `:root { --color-primary: hsl(220 90% 56%); }` |
| `base` | Element-level defaults | `body { font-family: var(--font-sans); }` |
| `components` | Reusable UI components | `.btn { ... }`, `.card { ... }` |
| `layouts` | Page-level layout structures | `.grid-dashboard { ... }` |
| `utilities` | Single-purpose overrides | `.sr-only { ... }`, `.text-center { ... }` |
| `overrides` | Emergency escape hatch (use sparingly) | Third-party library fixes |

```css
@layer reset {
  *, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }
}

@layer base {
  body {
    font-family: var(--font-sans);
    line-height: var(--leading-normal);
    color: var(--color-text);
    background-color: var(--color-surface);
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }
}
```

### Banned Practices
- ❌ **NEVER** use `!important` to win specificity battles. Fix the layer order instead.
- ❌ **NEVER** write styles outside of a `@layer` in a layered architecture — unlayered styles always win, creating unpredictable overrides.

---

## 2. Design Tokens (CSS Custom Properties)

Design tokens are the single source of truth for your visual language. **NEVER** hardcode values like `#1e293b`, `16px`, or `0.3s ease` directly in component styles.

### A. Token Taxonomy

Organize tokens into three tiers:

```css
@layer tokens {
  :root {
    /* ═══ TIER 1: Primitive (Raw Scale) ═══ */
    --gray-50: hsl(210 40% 98%);
    --gray-100: hsl(210 40% 96%);
    --gray-200: hsl(214 32% 91%);
    --gray-700: hsl(215 25% 27%);
    --gray-800: hsl(217 33% 17%);
    --gray-900: hsl(222 47% 11%);
    --gray-950: hsl(229 84% 5%);

    --blue-500: hsl(220 90% 56%);
    --blue-600: hsl(221 83% 50%);

    --radius-sm: 0.375rem;
    --radius-md: 0.5rem;
    --radius-lg: 0.75rem;
    --radius-full: 9999px;

    --spacing-1: 0.25rem;
    --spacing-2: 0.5rem;
    --spacing-3: 0.75rem;
    --spacing-4: 1rem;
    --spacing-6: 1.5rem;
    --spacing-8: 2rem;
    --spacing-12: 3rem;

    /* ═══ TIER 2: Semantic (Intent-Based) ═══ */
    --color-primary: var(--blue-500);
    --color-primary-hover: var(--blue-600);
    --color-text: var(--gray-900);
    --color-text-muted: var(--gray-700);
    --color-surface: var(--gray-50);
    --color-border: var(--gray-200);

    /* ═══ TIER 3: Component (Scoped) ═══ */
    --btn-bg: var(--color-primary);
    --btn-bg-hover: var(--color-primary-hover);
    --btn-radius: var(--radius-md);
    --btn-padding-x: var(--spacing-4);
    --btn-padding-y: var(--spacing-2);
  }
}
```

### B. Token Rules
- **Primitives** define the raw scale (colors, sizes). Components NEVER reference primitives directly.
- **Semantic tokens** map intent (`--color-primary`, `--color-danger`) to primitives.
- **Component tokens** scope variables to specific components (`--btn-bg`, `--card-shadow`).
- ❌ **NEVER** use raw hex/hsl values in component styles. Always reference a token.

---

## 3. CSS Nesting (Native)

Native CSS nesting eliminates preprocessor dependencies for basic nesting. Use it for component scoping.

```css
@layer components {
  .card {
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: var(--spacing-6);

    & .card__title {
      font-size: var(--text-lg);
      font-weight: 700;
      color: var(--color-text);
    }

    & .card__body {
      color: var(--color-text-muted);
      line-height: var(--leading-relaxed);
    }

    &:hover {
      border-color: var(--color-primary);
      box-shadow: 0 0 0 1px var(--color-primary);
    }

    /* Responsive within component context */
    @container (min-width: 400px) {
      display: grid;
      grid-template-columns: auto 1fr;
      gap: var(--spacing-4);
    }
  }
}
```

### Nesting Rules
- ✅ **ALWAYS** use `&` for pseudo-classes, pseudo-elements, and compound selectors.
- ✅ Keep nesting depth **≤ 3 levels**. Deeper nesting indicates a structural problem.
- ❌ **NEVER** nest so deeply that the output selector becomes hyper-specific (`.page .section .card .card__body .card__text span` is a nightmare).

---

## 4. `@scope` — True Component Encapsulation

`@scope` provides proximity-based scoping without Shadow DOM overhead.

```css
@scope (.notification) to (.notification__actions) {
  /* Styles apply ONLY within .notification but stop at .notification__actions */
  p {
    font-size: var(--text-sm);
    color: var(--color-text-muted);
  }
}
```

---

## 5. Logical Properties — RTL/LTR Internationalization

Physical properties (`margin-left`, `padding-right`, `width`) break in right-to-left (RTL) layouts. Logical properties adapt automatically.

| ❌ Physical | ✅ Logical |
|-------------|-----------|
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `padding-top` / `padding-bottom` | `padding-block` |
| `width` | `inline-size` |
| `height` | `block-size` |
| `text-align: left` | `text-align: start` |
| `border-left` | `border-inline-start` |

```css
/* ❌ NEVER: Breaks in RTL languages */
.sidebar {
  margin-left: var(--spacing-4);
  padding-right: var(--spacing-6);
  width: 280px;
}

/* ✅ ALWAYS: Works in all text directions */
.sidebar {
  margin-inline-start: var(--spacing-4);
  padding-inline-end: var(--spacing-6);
  inline-size: 280px;
}
```

---

## 6. Naming Conventions

### BEM (Block Element Modifier)
Use BEM for vanilla CSS/SCSS component class naming:

```css
/* Block */
.card { }

/* Element (double underscore) */
.card__header { }
.card__body { }
.card__footer { }

/* Modifier (double hyphen) */
.card--featured { }
.card--compact { }
.card__header--sticky { }
```

### Rules
- ❌ **NEVER** use IDs for styling (`#header`). IDs have maximum specificity and are unreusable.
- ❌ **NEVER** use tag selectors for components (`div`, `span`). They are fragile to markup changes.
- ✅ **ALWAYS** use meaningful, descriptive class names that communicate purpose, not appearance (`.error-message` not `.red-text`).

---

## 7. File Organization

For non-preprocessor (vanilla CSS) architectures:

```text
styles/
├── main.css                 # Layer declarations + imports
├── tokens/
│   ├── colors.css           # Primitive + semantic color tokens
│   ├── typography.css       # Font families, sizes, weights
│   ├── spacing.css          # Spacing scale
│   └── effects.css          # Shadows, transitions, radii
├── base/
│   ├── reset.css            # Modern CSS reset
│   └── global.css           # Body, html, root defaults
├── components/
│   ├── button.css
│   ├── card.css
│   └── modal.css
├── layouts/
│   ├── grid.css
│   └── sidebar.css
└── utilities/
    ├── sr-only.css
    └── visually-hidden.css
```

---

## 8. Summary of Banned Practices

- `!important` to fix specificity (Use `@layer` ordering).
- Hardcoded hex/rgb values outside tokens (Use `var(--token)`).
- IDs for styling (`#header`).
- Nesting deeper than 3 levels.
- Physical properties in internationalized apps (Use logical properties).
- Inline styles for repeatable patterns (Extract to component classes).
- Tag-only selectors for component styling (`div { ... }`).

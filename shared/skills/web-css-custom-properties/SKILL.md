---
name: web-css-custom-properties
description: The definitive standard for engineering advanced CSS custom properties including @property, typed properties, runtime theming, animation, calculated tokens, and CSS Houdini foundations.
author: Diego Villanueva
trigger: When using @property for typed CSS custom properties, animating custom properties, building runtime theming systems, creating calculated design tokens, or leveraging CSS Houdini APIs.
---

# CSS Custom Properties & Runtime Theming Mastery

You are an expert CSS Custom Properties Engineer. Your directive is to build dynamic, type-safe, and highly performant runtime theming systems using `@property`, typed custom properties, fallback chains, calculated tokens, and CSS Houdini foundations. Custom properties are not just variables — they are the runtime API of your design system.

---

## 1. `@property` — Typed Custom Properties

Regular custom properties (`--my-color: blue`) are untyped strings — the browser can't interpolate them, validate them, or animate them. `@property` registers a property with a type, initial value, and inheritance behavior.

### A. Registration Syntax

```css
/* Register a typed color property */
@property --gradient-start {
  syntax: '<color>';
  inherits: false;
  initial-value: hsl(260 80% 60%);
}

@property --gradient-end {
  syntax: '<color>';
  inherits: false;
  initial-value: hsl(200 90% 50%);
}

/* Register a typed number/percentage property */
@property --progress {
  syntax: '<percentage>';
  inherits: false;
  initial-value: 0%;
}

@property --rotation {
  syntax: '<angle>';
  inherits: false;
  initial-value: 0deg;
}

@property --blur-amount {
  syntax: '<length>';
  inherits: false;
  initial-value: 0px;
}
```

### B. Available Syntax Types

| Syntax | Example Values | Use Case |
|--------|---------------|----------|
| `'<color>'` | `red`, `hsl(...)`, `#fff` | Theme colors, gradients |
| `'<length>'` | `10px`, `2rem`, `5vw` | Sizes, spacing, offsets |
| `'<percentage>'` | `50%`, `100%` | Progress bars, widths |
| `'<angle>'` | `45deg`, `0.5turn` | Rotations, gradients |
| `'<number>'` | `0`, `1`, `0.5` | Opacity, scale factors |
| `'<integer>'` | `1`, `2`, `3` | Counters, grid spans |
| `'<length-percentage>'` | `10px`, `50%` | Flexible sizing |
| `'<transform-function>'` | `rotate(45deg)` | Transform animations |
| `'<custom-ident>'` | `auto`, `none` | State identifiers |

---

## 2. Animating Custom Properties

Regular custom properties **cannot** be animated — they're strings. `@property` typed properties **can** be animated because the browser knows the type.

### A. Animated Gradient

```css
@property --gradient-angle {
  syntax: '<angle>';
  inherits: false;
  initial-value: 0deg;
}

.gradient-rotate {
  background: linear-gradient(var(--gradient-angle), hsl(260 80% 60%), hsl(200 90% 50%));
  animation: rotate-gradient 4s linear infinite;
}

@keyframes rotate-gradient {
  to { --gradient-angle: 360deg; }
}
```

### B. Animated Color Transition (Gradient Morph)

```css
@property --color-a {
  syntax: '<color>';
  inherits: false;
  initial-value: hsl(260 80% 60%);
}

@property --color-b {
  syntax: '<color>';
  inherits: false;
  initial-value: hsl(200 90% 50%);
}

.morph-gradient {
  background: linear-gradient(135deg, var(--color-a), var(--color-b));
  transition: --color-a 600ms ease, --color-b 600ms ease;

  &:hover {
    --color-a: hsl(340 80% 55%);
    --color-b: hsl(30 90% 55%);
  }
}
```

### C. Progress Bar with Animated Width

```css
@property --bar-width {
  syntax: '<percentage>';
  inherits: false;
  initial-value: 0%;
}

.progress-bar {
  block-size: 6px;
  background: var(--color-border);
  border-radius: var(--radius-full);
  overflow: hidden;

  &::after {
    content: '';
    display: block;
    block-size: 100%;
    inline-size: var(--bar-width);
    background: var(--color-primary);
    border-radius: inherit;
    transition: --bar-width 800ms var(--ease-spring);
  }
}

/* Set progress via inline style or JavaScript:
   element.style.setProperty('--bar-width', '75%');
*/
```

### D. Animated Blur

```css
@property --blur-radius {
  syntax: '<length>';
  inherits: false;
  initial-value: 0px;
}

.blur-in {
  backdrop-filter: blur(var(--blur-radius));
  transition: --blur-radius 400ms var(--ease-out);

  &.is-active {
    --blur-radius: 16px;
  }
}
```

---

## 3. Fallback Chains

Custom properties support multi-level fallback chains — essential for resilient component APIs:

```css
.btn {
  /* Chain: Component token → Semantic token → Primitive fallback */
  background: var(--btn-bg, var(--color-primary, hsl(220 90% 56%)));
  color: var(--btn-text, var(--color-primary-text, white));
  border-radius: var(--btn-radius, var(--radius-md, 0.5rem));
  padding: var(--btn-py, var(--spacing-2, 0.5rem)) var(--btn-px, var(--spacing-4, 1rem));
}

/* Override at the component level */
.card .btn {
  --btn-bg: var(--color-surface-alt);
  --btn-text: var(--color-text);
  --btn-radius: var(--radius-sm);
}
```

### Rules
- ✅ **ALWAYS** provide at least one fallback in `var()` for critical visual properties.
- ✅ Chain fallbacks from specific → generic → hardcoded.
- ❌ **NEVER** leave a `var()` without a fallback on properties critical for layout (`width`, `padding`).

---

## 4. Component API Pattern (Custom Property Interface)

Expose a clean API for component customization using custom properties:

```css
/* ═══ Button Component API ═══ */
.btn {
  /* Public API (overridable from outside) */
  --_bg:      var(--btn-bg, var(--color-primary));
  --_bg-hover: var(--btn-bg-hover, var(--color-primary-hover));
  --_text:    var(--btn-text, var(--color-primary-text));
  --_radius:  var(--btn-radius, var(--radius-md));
  --_size:    var(--btn-size, var(--text-sm));
  --_px:      var(--btn-px, var(--spacing-4));
  --_py:      var(--btn-py, var(--spacing-2));

  /* Implementation (uses private _ prefixed tokens) */
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-2);
  background: var(--_bg);
  color: var(--_text);
  font-size: var(--_size);
  font-weight: 600;
  padding: var(--_py) var(--_px);
  border: none;
  border-radius: var(--_radius);
  cursor: pointer;
  transition: background-color 150ms var(--ease-snappy), transform 150ms var(--ease-snappy);

  &:hover { background: var(--_bg-hover); }
  &:active { transform: scale(0.98); }
}

/* Variant: Override only the public API tokens */
.btn--danger {
  --btn-bg: var(--color-danger);
  --btn-bg-hover: var(--color-danger-hover);
}

.btn--ghost {
  --btn-bg: transparent;
  --btn-bg-hover: var(--color-surface-alt);
  --btn-text: var(--color-text);
}

.btn--lg {
  --btn-size: var(--text-base);
  --btn-px: var(--spacing-6);
  --btn-py: var(--spacing-3);
}
```

### Convention
- **Public tokens**: `--component-property` (e.g., `--btn-bg`)
- **Private tokens**: `--_property` (internal implementation detail, prefixed with `_`)
- Consumers override **public** tokens; the component reads **private** tokens that default to the public ones.

---

## 5. Calculated Tokens — Dynamic Design System

Build tokens that derive from a shared base, ensuring mathematical consistency:

```css
:root {
  /* Base spacing unit */
  --base-unit: 0.25rem;

  /* Derived spacing scale */
  --spacing-1:  calc(var(--base-unit) * 1);   /* 0.25rem */
  --spacing-2:  calc(var(--base-unit) * 2);   /* 0.5rem  */
  --spacing-3:  calc(var(--base-unit) * 3);   /* 0.75rem */
  --spacing-4:  calc(var(--base-unit) * 4);   /* 1rem    */
  --spacing-6:  calc(var(--base-unit) * 6);   /* 1.5rem  */
  --spacing-8:  calc(var(--base-unit) * 8);   /* 2rem    */
  --spacing-12: calc(var(--base-unit) * 12);  /* 3rem    */
  --spacing-16: calc(var(--base-unit) * 16);  /* 4rem    */

  /* Modular type scale (ratio: 1.25 — Major Third) */
  --type-ratio: 1.25;
  --text-base: 1rem;
  --text-lg:   calc(var(--text-base) * var(--type-ratio));
  --text-xl:   calc(var(--text-lg)   * var(--type-ratio));
  --text-2xl:  calc(var(--text-xl)   * var(--type-ratio));
  --text-3xl:  calc(var(--text-2xl)  * var(--type-ratio));
  --text-sm:   calc(var(--text-base) / var(--type-ratio));
  --text-xs:   calc(var(--text-sm)   / var(--type-ratio));
}
```

### Dynamic Density (Compact vs. Comfortable)

```css
:root {
  --density: 1; /* 1 = comfortable, 0.75 = compact, 1.25 = spacious */
}

.card {
  padding: calc(var(--spacing-6) * var(--density));
  gap: calc(var(--spacing-4) * var(--density));
}

.table td {
  padding: calc(var(--spacing-2) * var(--density)) calc(var(--spacing-4) * var(--density));
}

/* Compact mode */
[data-density="compact"] {
  --density: 0.75;
}

/* Spacious mode */
[data-density="spacious"] {
  --density: 1.25;
}
```

---

## 6. Scope Inheritance & Isolation

Custom properties inherit by default. Use this strategically:

```css
/* Theme tokens inherit to all descendants */
.sidebar {
  --color-surface: var(--slate-900);
  --color-text: var(--slate-50);
  --color-border: var(--slate-700);

  /* All children (.card, .btn, etc.) inside .sidebar automatically
     pick up the dark surface tokens without ANY code changes */
}

/* Isolation: Stop inheritance for specific components */
.tooltip {
  --color-surface: initial; /* Reset to the :root value */
}
```

### Scoped Component Themes

```css
/* Each section can have its own micro-theme */
.hero {
  --color-primary: hsl(260 80% 60%);
  --color-surface: hsl(260 30% 8%);
  --color-text: hsl(260 20% 95%);
}

.pricing {
  --color-primary: hsl(160 70% 45%);
  --color-surface: hsl(160 15% 6%);
  --color-text: hsl(160 10% 92%);
}

/* Components inside each section adapt automatically */
```

---

## 7. JavaScript ↔ CSS Bridge

### A. Reading Custom Properties

```typescript
// Read computed property value
const value = getComputedStyle(element).getPropertyValue('--color-primary').trim();

// Read from root
const rootValue = getComputedStyle(document.documentElement).getPropertyValue('--spacing-4');
```

### B. Writing Custom Properties

```typescript
// Set on a specific element (scoped)
element.style.setProperty('--progress', '75%');
element.style.setProperty('--card-bg', 'hsl(200 90% 50%)');

// Set on root (global)
document.documentElement.style.setProperty('--color-primary', 'hsl(260 80% 60%)');

// Remove (revert to stylesheet value)
element.style.removeProperty('--color-primary');
```

### C. Reactive Binding Example (Framework-Agnostic)

```typescript
// Mouse-tracking gradient
document.addEventListener('mousemove', (e) => {
  const x = (e.clientX / window.innerWidth) * 100;
  const y = (e.clientY / window.innerHeight) * 100;
  document.documentElement.style.setProperty('--mouse-x', `${x}%`);
  document.documentElement.style.setProperty('--mouse-y', `${y}%`);
});
```

```css
.interactive-bg {
  background: radial-gradient(
    circle at var(--mouse-x, 50%) var(--mouse-y, 50%),
    hsl(260 80% 60% / 0.3) 0%,
    transparent 50%
  );
}
```

---

## 8. CSS Houdini — Paint API Foundations

For custom rendering beyond what CSS can express natively:

```javascript
// Register a paint worklet
if ('paintWorklet' in CSS) {
  CSS.paintWorklet.addModule('/paint/noise-background.js');
}
```

```javascript
// paint/noise-background.js
class NoiseBackgroundPainter {
  static get inputProperties() {
    return ['--noise-density', '--noise-color'];
  }

  paint(ctx, size, properties) {
    const density = parseFloat(properties.get('--noise-density').toString()) || 0.1;
    const color = properties.get('--noise-color').toString() || 'rgba(255,255,255,0.05)';

    for (let x = 0; x < size.width; x += 2) {
      for (let y = 0; y < size.height; y += 2) {
        if (Math.random() < density) {
          ctx.fillStyle = color;
          ctx.fillRect(x, y, 1, 1);
        }
      }
    }
  }
}

registerPaint('noise-background', NoiseBackgroundPainter);
```

```css
.noise-panel {
  --noise-density: 0.08;
  --noise-color: hsl(0 0% 100% / 0.04);
  background-image: paint(noise-background);
}
```

> **Note**: CSS Houdini Paint API has limited browser support. Always provide a CSS fallback.

---

## 9. Summary of Banned Practices

- Untyped custom properties for values you want to animate (Use `@property`).
- `var()` without fallback values on layout-critical properties (Always chain fallbacks).
- Exposing internal component tokens as the public API (Use private `--_` prefix convention).
- Hardcoded values when a calculated token (`calc()`) would maintain consistency.
- Inline `style` attribute for theming when custom properties can be scoped via classes.
- Forgetting that custom properties inherit — unintended style leaking.
- Using `getComputedStyle` in tight loops (Cache the result — it triggers style recalculation).

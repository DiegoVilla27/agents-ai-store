---
name: web-css-theming
description: The definitive standard for engineering robust dark/light mode systems, multi-theme architectures, and dynamic theme switching using modern CSS.
author: Diego Villanueva
trigger: When implementing dark mode, light mode, theme switching, prefers-color-scheme, color-scheme, color tokens, multi-theme architectures, or semantic color systems.
---

# Dark/Light Mode & Theming System Mastery

You are an expert Theming Architect. Your directive is to build production-grade theming systems that seamlessly support dark/light modes, respect OS preferences, enable runtime theme switching, maintain WCAG contrast compliance across all themes, and scale to unlimited custom brand themes without code duplication.

---

## 1. The `color-scheme` Property

**✅ ALWAYS** declare `color-scheme` to inform the browser of supported themes. This automatically adapts native form controls, scrollbars, and system colors.

```css
:root {
  color-scheme: light dark;
}
```

This single declaration ensures `<input>`, `<select>`, `<textarea>`, scrollbars, and native dialogs automatically match the active theme without manual styling.

---

## 2. Semantic Token Architecture (The Foundation)

A theming system lives and dies by its token architecture. You MUST separate primitive colors from semantic intent.

### A. Three-Layer Token System

```css
@layer tokens {
  /* ═══ LAYER 1: Primitives (Never referenced by components) ═══ */
  :root {
    --slate-50:  hsl(210 40% 98%);
    --slate-100: hsl(210 40% 96%);
    --slate-200: hsl(214 32% 91%);
    --slate-300: hsl(213 27% 84%);
    --slate-400: hsl(215 20% 65%);
    --slate-500: hsl(215 16% 47%);
    --slate-600: hsl(215 19% 35%);
    --slate-700: hsl(215 25% 27%);
    --slate-800: hsl(217 33% 17%);
    --slate-900: hsl(222 47% 11%);
    --slate-950: hsl(229 84% 5%);

    --blue-400:  hsl(213 94% 68%);
    --blue-500:  hsl(220 90% 56%);
    --blue-600:  hsl(221 83% 50%);

    --red-400:   hsl(0 91% 71%);
    --red-500:   hsl(0 84% 60%);
    --red-600:   hsl(0 72% 51%);

    --green-400: hsl(142 69% 58%);
    --green-500: hsl(142 71% 45%);
    --green-600: hsl(142 76% 36%);

    --amber-400: hsl(43 96% 56%);
    --amber-500: hsl(38 92% 50%);
  }

  /* ═══ LAYER 2: Semantic (Theme-aware — Light defaults) ═══ */
  :root {
    /* Surfaces */
    --color-bg:           var(--slate-50);
    --color-surface:      hsl(0 0% 100%);
    --color-surface-alt:  var(--slate-100);
    --color-overlay:      hsl(0 0% 0% / 0.4);

    /* Text */
    --color-text:         var(--slate-900);
    --color-text-muted:   var(--slate-500);
    --color-text-inverse: hsl(0 0% 100%);

    /* Borders & Dividers */
    --color-border:       var(--slate-200);
    --color-border-hover: var(--slate-300);
    --color-divider:      var(--slate-200);

    /* Interactive */
    --color-primary:       var(--blue-500);
    --color-primary-hover: var(--blue-600);
    --color-primary-text:  hsl(0 0% 100%);

    /* Feedback */
    --color-success:      var(--green-500);
    --color-warning:      var(--amber-500);
    --color-danger:       var(--red-500);
    --color-danger-hover: var(--red-600);

    /* Focus */
    --color-focus-ring: var(--blue-500);

    /* Shadows */
    --shadow-color: hsl(215 25% 27% / 0.1);
    --shadow-sm: 0 1px 2px var(--shadow-color);
    --shadow-md: 0 4px 6px -1px var(--shadow-color), 0 2px 4px -2px var(--shadow-color);
    --shadow-lg: 0 10px 15px -3px var(--shadow-color), 0 4px 6px -4px var(--shadow-color);
    --shadow-xl: 0 20px 25px -5px var(--shadow-color), 0 8px 10px -6px var(--shadow-color);
  }
}
```

---

## 3. Dark Mode Implementation

### A. Strategy 1: `prefers-color-scheme` (OS-Driven)

Automatically matches the user's OS preference:

```css
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg:           var(--slate-950);
    --color-surface:      var(--slate-900);
    --color-surface-alt:  var(--slate-800);
    --color-overlay:      hsl(0 0% 0% / 0.7);

    --color-text:         var(--slate-50);
    --color-text-muted:   var(--slate-400);

    --color-border:       var(--slate-700);
    --color-border-hover: var(--slate-600);
    --color-divider:      var(--slate-800);

    --color-primary:       var(--blue-400);
    --color-primary-hover: var(--blue-500);

    --color-success:      var(--green-400);
    --color-warning:      var(--amber-400);
    --color-danger:       var(--red-400);
    --color-danger-hover: var(--red-500);

    --shadow-color: hsl(0 0% 0% / 0.5);
  }
}
```

### B. Strategy 2: `data-theme` Attribute (User-Driven Toggle)

Allows user-controlled theme switching independent of OS:

```css
[data-theme="dark"] {
  --color-bg:           var(--slate-950);
  --color-surface:      var(--slate-900);
  --color-surface-alt:  var(--slate-800);
  --color-text:         var(--slate-50);
  --color-text-muted:   var(--slate-400);
  --color-border:       var(--slate-700);
  --color-primary:      var(--blue-400);
  --shadow-color:       hsl(0 0% 0% / 0.5);
}
```

```html
<html data-theme="dark">
```

### C. Strategy 3: Combined (OS Default + User Override)

The production-grade approach — respect OS preference, but let users override:

```javascript
// theme-manager.ts
function getTheme(): 'light' | 'dark' {
  const stored = localStorage.getItem('theme');
  if (stored === 'light' || stored === 'dark') return stored;
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function setTheme(theme: 'light' | 'dark'): void {
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem('theme', theme);
}

// Listen for OS changes (only if user hasn't manually set a preference)
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
  if (!localStorage.getItem('theme')) {
    document.documentElement.setAttribute('data-theme', e.matches ? 'dark' : 'light');
  }
});
```

---

## 4. `light-dark()` Function (CSS-Native)

The new CSS `light-dark()` function switches values based on the computed `color-scheme`:

```css
:root {
  color-scheme: light dark;

  --color-text: light-dark(var(--slate-900), var(--slate-50));
  --color-bg:   light-dark(var(--slate-50), var(--slate-950));
  --color-border: light-dark(var(--slate-200), var(--slate-700));
}
```

> **Note**: `light-dark()` is ideal for simple two-theme systems. For multi-theme architectures (brand themes, high-contrast), use the `data-theme` attribute strategy.

---

## 5. `color-mix()` — Dynamic Color Operations

Generate color variants without preprocessors:

```css
:root {
  --color-primary: hsl(220 90% 56%);

  /* Lighten: Mix with white */
  --color-primary-light: color-mix(in oklch, var(--color-primary) 30%, white);

  /* Darken: Mix with black */
  --color-primary-dark: color-mix(in oklch, var(--color-primary) 80%, black);

  /* Transparent variant */
  --color-primary-ghost: color-mix(in srgb, var(--color-primary) 15%, transparent);

  /* Hover state (slightly darker) */
  --color-primary-hover: color-mix(in oklch, var(--color-primary) 85%, black);
}

/* Usage */
.btn-primary {
  background: var(--color-primary);

  &:hover {
    background: var(--color-primary-hover);
  }
}

.badge {
  background: var(--color-primary-ghost);
  color: var(--color-primary);
}
```

### Color Space Rules
- ✅ **ALWAYS** use `oklch` for perceptually uniform mixing (colors look natural).
- ❌ **NEVER** use `srgb` for lightening/darkening — it produces muddy midtones.

---

## 6. Multi-Theme Architecture (Brand Themes)

For applications that support custom brand themes beyond dark/light:

```css
/* ═══ Theme: Ocean Blue ═══ */
[data-theme="ocean"] {
  --color-primary:       hsl(200 85% 50%);
  --color-primary-hover: hsl(200 85% 42%);
  --color-bg:            hsl(200 30% 8%);
  --color-surface:       hsl(200 25% 12%);
  --color-text:          hsl(200 20% 92%);
  --color-border:        hsl(200 20% 22%);
}

/* ═══ Theme: Sunset ═══ */
[data-theme="sunset"] {
  --color-primary:       hsl(15 90% 55%);
  --color-primary-hover: hsl(15 90% 45%);
  --color-bg:            hsl(15 20% 6%);
  --color-surface:       hsl(15 15% 10%);
  --color-text:          hsl(15 10% 92%);
  --color-border:        hsl(15 15% 20%);
}
```

Components reference semantic tokens — they automatically adapt:

```css
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  color: var(--color-text);
  /* Works in light, dark, ocean, sunset — zero changes needed */
}
```

---

## 7. Theme Transitions

Smooth transitions when switching themes:

```css
:root {
  transition:
    background-color 300ms var(--ease-out),
    color 300ms var(--ease-out);
}

/* Apply to major surface elements */
body,
.card,
.sidebar,
.header {
  transition:
    background-color 300ms var(--ease-out),
    color 200ms var(--ease-out),
    border-color 200ms var(--ease-out),
    box-shadow 300ms var(--ease-out);
}

/* ❌ Disable transitions during initial page load (prevents flash) */
.no-transitions * {
  transition: none !important;
}
```

---

## 8. WCAG Contrast Compliance

### Minimum Contrast Ratios

| Level | Text Size | Required Ratio |
|-------|-----------|---------------|
| AA | Normal text (< 18px) | 4.5:1 |
| AA | Large text (≥ 18px bold / ≥ 24px) | 3:1 |
| AAA | Normal text | 7:1 |
| AAA | Large text | 4.5:1 |
| AA | UI components & graphical objects | 3:1 |

### High Contrast Mode

```css
@media (prefers-contrast: more) {
  :root {
    --color-text:    hsl(0 0% 0%);
    --color-bg:      hsl(0 0% 100%);
    --color-border:  hsl(0 0% 0%);
    --color-primary: hsl(220 100% 40%);

    --shadow-sm: none;
    --shadow-md: none;
    --shadow-lg: none;
  }
}

@media (forced-colors: active) {
  /* Windows High Contrast Mode */
  .btn {
    border: 2px solid ButtonText;
  }
}
```

---

## 9. Preventing Flash of Unstyled Theme (FOUT)

Prevent the "white flash" when loading a dark theme:

```html
<!-- Inline in <head> BEFORE any stylesheets -->
<script>
  (function() {
    const theme = localStorage.getItem('theme') ||
      (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    document.documentElement.setAttribute('data-theme', theme);
    document.documentElement.classList.add('no-transitions');
    window.addEventListener('DOMContentLoaded', () => {
      requestAnimationFrame(() => {
        document.documentElement.classList.remove('no-transitions');
      });
    });
  })();
</script>
```

---

## 10. Summary of Banned Practices

- Hardcoded colors in component styles without semantic tokens (Use `var(--color-*)`).
- Using `srgb` for `color-mix()` lightening/darkening (Use `oklch`).
- Ignoring `prefers-color-scheme` (Always respect OS preference as default).
- Dark mode that simply inverts colors (Design intentional dark palettes with proper contrast).
- Forgetting `color-scheme: light dark` declaration (Native controls won't adapt).
- Missing contrast compliance (WCAG AA 4.5:1 minimum).
- Flash of wrong theme on page load (Use inline `<head>` script).
- Theme-switching without transitions (Add smooth `background-color`/`color` transitions).

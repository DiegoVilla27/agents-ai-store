---
name: web-css-responsive
description: The definitive standard for modern responsive design using container queries, fluid typography, intrinsic sizing, CSS Grid/Subgrid, and mobile-first breakpoint strategies.
author: Diego Villanueva
trigger: When implementing responsive layouts, container queries, fluid typography with clamp(), CSS Grid/Subgrid patterns, breakpoint strategies, or adaptive component sizing.
---

# Responsive Design & Fluid Layout Mastery

You are an expert Responsive Design Engineer. Your directive is to build interfaces that fluidly adapt to any viewport and any container context — from 320px mobile to ultrawide monitors — without jarring breakpoint jumps, without horizontal overflow, and without content reflow jank. The viewport is no longer the only context; components must be intelligent enough to adapt to their surroundings.

---

## 1. Mobile-First Breakpoint Strategy

**✅ ALWAYS** write base styles for mobile, then layer up with `min-width` queries. Never write desktop-first and undo with `max-width`.

### A. Standard Breakpoint Scale

```css
/* ═══ Breakpoint tokens ═══ */
:root {
  --bp-sm: 640px;
  --bp-md: 768px;
  --bp-lg: 1024px;
  --bp-xl: 1280px;
  --bp-2xl: 1536px;
}

/* ═══ Mobile-first progressive enhancement ═══ */
.grid-products {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--spacing-4);

  @media (min-width: 640px) {
    grid-template-columns: repeat(2, 1fr);
  }

  @media (min-width: 1024px) {
    grid-template-columns: repeat(3, 1fr);
  }

  @media (min-width: 1280px) {
    grid-template-columns: repeat(4, 1fr);
    gap: var(--spacing-6);
  }
}
```

### B. Banned Breakpoint Practices
- ❌ **NEVER** use `max-width` media queries as the primary strategy (desktop-first).
- ❌ **NEVER** target specific devices (`@media (width: 375px)`). Target content, not devices.
- ❌ **NEVER** use more than 5 breakpoints. If you need more, your layout logic is wrong.

---

## 2. Container Queries — Component-Level Responsiveness

Media queries respond to the **viewport**. Container queries respond to the **parent container**. This is essential for reusable components that live in different layout contexts (sidebar vs. main content vs. modal).

```css
/* Step 1: Declare the containment context */
.card-wrapper {
  container-type: inline-size;
  container-name: card;
}

/* Step 2: Query the container, not the viewport */
.card {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-3);

  @container card (min-width: 400px) {
    flex-direction: row;
    align-items: center;
  }

  @container card (min-width: 600px) {
    & .card__image {
      inline-size: 40%;
    }
    & .card__body {
      inline-size: 60%;
    }
  }
}
```

### Container Query Units

Use container-relative units for truly context-aware sizing:

| Unit | Relative to |
|------|-------------|
| `cqw` | Container's inline-size (width in horizontal writing) |
| `cqh` | Container's block-size (height) |
| `cqi` | Container's inline-size |
| `cqb` | Container's block-size |
| `cqmin` | Smaller of `cqi` / `cqb` |
| `cqmax` | Larger of `cqi` / `cqb` |

```css
@container card (min-width: 500px) {
  .card__title {
    font-size: clamp(1rem, 3cqi, 1.75rem);
  }
}
```

### Rules
- ✅ **ALWAYS** prefer container queries over media queries for reusable components.
- ✅ **ALWAYS** name containers with `container-name` for clarity.
- ❌ **NEVER** use `container-type: size` unless you explicitly need block-axis containment. Use `inline-size` by default.

---

## 3. Fluid Typography (`clamp()`)

Hardcoded `font-size` breakpoints create jarring jumps. `clamp()` creates smooth, linear interpolation between a minimum and maximum size.

### A. The Formula

```
clamp(MIN, PREFERRED, MAX)
```

```css
:root {
  /* ═══ Fluid Type Scale ═══ */
  --text-xs:   clamp(0.75rem,  0.7rem  + 0.25vw, 0.875rem);
  --text-sm:   clamp(0.875rem, 0.83rem + 0.2vw,  1rem);
  --text-base: clamp(1rem,     0.93rem + 0.3vw,  1.125rem);
  --text-lg:   clamp(1.125rem, 1rem    + 0.5vw,  1.375rem);
  --text-xl:   clamp(1.25rem,  1rem    + 1vw,    1.75rem);
  --text-2xl:  clamp(1.5rem,   1.1rem  + 1.5vw,  2.25rem);
  --text-3xl:  clamp(1.875rem, 1.2rem  + 2.5vw,  3rem);
  --text-4xl:  clamp(2.25rem,  1.5rem  + 3vw,    4rem);
  --text-hero: clamp(2.5rem,   1rem    + 5vw,    6rem);
}

h1 { font-size: var(--text-hero); }
h2 { font-size: var(--text-3xl); }
h3 { font-size: var(--text-2xl); }
p  { font-size: var(--text-base); }
```

### B. Fluid Spacing

Apply the same principle to spacing for consistently proportional layouts:

```css
:root {
  --space-xs:  clamp(0.25rem, 0.2rem  + 0.2vw,  0.5rem);
  --space-sm:  clamp(0.5rem,  0.4rem  + 0.4vw,  0.75rem);
  --space-md:  clamp(1rem,    0.8rem  + 0.8vw,  1.5rem);
  --space-lg:  clamp(1.5rem,  1rem    + 1.5vw,  2.5rem);
  --space-xl:  clamp(2rem,    1.5rem  + 2vw,    4rem);
  --space-2xl: clamp(3rem,    2rem    + 3vw,    6rem);
}

.section {
  padding-block: var(--space-2xl);
  padding-inline: var(--space-lg);
}
```

### Rules
- ✅ **ALWAYS** use `rem` for `MIN` and `MAX` to respect user font-size settings.
- ✅ Use `vw` in the preferred value for viewport-relative scaling.
- ❌ **NEVER** use `px` as the minimum — it overrides user accessibility preferences.

---

## 4. CSS Grid & Subgrid

### A. Auto-Fit / Auto-Fill Responsive Grids

The most powerful responsive pattern — no media queries needed:

```css
/* Cards auto-fill available space, minimum 280px each */
.auto-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(280px, 100%), 1fr));
  gap: var(--spacing-6);
}
```

### B. Subgrid — Cross-Component Alignment

Subgrid allows child elements to align to the parent's grid tracks, solving the "misaligned card content" problem:

```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: var(--spacing-6);
}

.card {
  display: grid;
  grid-template-rows: subgrid;
  grid-row: span 3; /* header, body, footer */
  gap: var(--spacing-3);
}

/* All card headers, bodies, and footers align across the row */
.card__header  { align-self: start; }
.card__body    { align-self: stretch; }
.card__footer  { align-self: end; }
```

### C. Named Grid Areas (Complex Layouts)

```css
.dashboard {
  display: grid;
  grid-template-columns: 250px 1fr 300px;
  grid-template-rows: auto 1fr auto;
  grid-template-areas:
    "sidebar header  header"
    "sidebar main    aside"
    "sidebar footer  footer";
  min-block-size: 100dvh;

  @media (max-width: 1023px) {
    grid-template-columns: 1fr;
    grid-template-areas:
      "header"
      "main"
      "aside"
      "footer";
  }
}

.sidebar { grid-area: sidebar; }
.header  { grid-area: header; }
.main    { grid-area: main; }
.aside   { grid-area: aside; }
.footer  { grid-area: footer; }
```

---

## 5. Intrinsic Sizing

Let content dictate sizing instead of hardcoding widths:

| Property | Use Case |
|----------|----------|
| `min-content` | Shrink to the smallest word/element |
| `max-content` | Expand to fit all content without wrapping |
| `fit-content(max)` | Grow with content up to a maximum |
| `min(value, 100%)` | Prevent overflow on small screens |

```css
/* Button that sizes to its content but never exceeds container */
.btn {
  inline-size: fit-content(300px);
}

/* Image that respects container but has a max */
.hero-image {
  inline-size: min(100%, 1200px);
  margin-inline: auto;
}
```

---

## 6. Modern Viewport Units

The `vh` unit is broken on mobile (doesn't account for browser chrome). Use the new units:

| Unit | Meaning |
|------|---------|
| `dvh` | Dynamic viewport height (accounts for URL bar show/hide) |
| `svh` | Small viewport height (URL bar visible) |
| `lvh` | Large viewport height (URL bar hidden) |
| `dvw` | Dynamic viewport width |

```css
.hero {
  min-block-size: 100dvh; /* Full screen on all devices */
  display: grid;
  place-items: center;
}
```

- ❌ **NEVER** use `100vh` for mobile full-screen sections. Use `100dvh`.

---

## 7. Modern Media Query Features

### A. User Preference Queries

```css
/* Respect OS-level dark mode preference */
@media (prefers-color-scheme: dark) { /* ... */ }

/* Reduce motion for users with vestibular disorders */
@media (prefers-reduced-motion: reduce) { /* ... */ }

/* High contrast mode */
@media (prefers-contrast: more) { /* ... */ }

/* Reduce transparency */
@media (prefers-reduced-transparency: reduce) { /* ... */ }

/* Coarse pointer = touch, fine pointer = mouse */
@media (pointer: coarse) {
  .btn { min-block-size: 44px; } /* Larger touch targets */
}
```

### B. Range Syntax (Modern)

```css
/* ❌ LEGACY */
@media (min-width: 640px) and (max-width: 1023px) { }

/* ✅ MODERN range syntax */
@media (640px <= width < 1024px) { }
@media (width >= 1024px) { }
```

---

## 8. Summary of Banned Practices

- `max-width` as primary breakpoint strategy (Use mobile-first `min-width`).
- `100vh` on mobile (Use `100dvh`).
- Hardcoded `font-size` at every breakpoint (Use `clamp()` fluid typography).
- Media queries for component-level responsiveness (Use container queries).
- Device-specific breakpoints (`@media (width: 375px)`).
- Pixel values in `clamp()` min/max (Use `rem` for accessibility).
- Forgetting `min(value, 100%)` guard on fixed-width elements (causes horizontal overflow).

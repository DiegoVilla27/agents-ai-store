---
name: responsive-adaptive-ux
description: The ultimate architectural standard for Responsive & Adaptive UX with CSS Container Queries (@container), Fluid Typography (clamp()), Adaptive Data Tables, and Touch-First Interactivity.
author: Diego Villanueva
trigger: When building responsive layouts, using CSS Container Queries, implementing fluid typography with clamp(), designing mobile-responsive data tables, or optimizing touch interfaces.
---

# Enterprise Responsive & Adaptive UX Architecture

Viewport Media Queries (`@media (min-width: 768px)`) fail in component-driven architectures because a card component does not know if it is inside a full-width page, a narrow sidebar, or a multi-column grid. Modern Responsive UX mandates **CSS Container Queries (`@container`)**, **Fluid Typography (`clamp()`)**, and **Adaptive Data Tables**.

---

## 1. CSS Container Queries (`@container`)

Container Queries allow a component to adapt its layout based on the width of its **parent container**, making components truly reusable everywhere.

```css
/* 1. Define parent as a container context */
.card-wrapper {
  container-type: inline-size;
  container-name: card-container;
}

/* 2. Component adapts to parent container width! */
.user-card {
  display: flex;
  flex-direction: column;
  padding: 1rem;
}

@container card-container (min-width: 400px) {
  .user-card {
    flex-direction: row;
    align-items: center;
    gap: 1.5rem;
    padding: 1.5rem;
  }
}
```

---

## 2. Fluid Typography & Spacing with `clamp()`

**❌ NEVER** write 5 different `@media` breakpoints just to adjust heading font sizes from mobile to 4K screens.
**✅ ALWAYS** use fluid mathematical scaling via **`clamp(min, preferred, max)`**.

```css
:root {
  /* Fluid Body Text: 16px at 320px viewport -> 18px at 1440px viewport */
  --text-body: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);

  /* Fluid H1 Heading: 32px on mobile -> 64px on large displays */
  --text-h1: clamp(2rem, 1.25rem + 3.75vw, 4rem);

  /* Fluid Section Spacing: 32px on mobile -> 96px on desktop */
  --space-section: clamp(2rem, 1rem + 5vw, 6rem);
}

h1 {
  font-size: var(--text-h1);
  line-height: 1.1;
  letter-spacing: -0.02em;
}
```

---

## 3. Adaptive Data Tables (Mobile Stacking vs Desktop Matrix)

Data tables with 8 columns break on smartphone screens.

### The Responsive Table Pattern:
- **Desktop ($\ge 768px$)**: Standard multi-column tabular grid.
- **Mobile ($< 768px$)**: Automatically transform table rows into standalone **Stacked Cards** using CSS data attributes:

```css
@media (max-width: 767px) {
  .responsive-table,
  .responsive-table tbody,
  .responsive-table tr,
  .responsive-table td {
    display: block;
    width: 100%;
  }

  .responsive-table thead {
    display: none; /* Hide header row on mobile */
  }

  .responsive-table tr {
    margin-bottom: 1rem;
    border: 1px solid var(--border-subtle);
    border-radius: 0.75rem;
    padding: 1rem;
  }

  .responsive-table td {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem 0;
    border-bottom: 1px solid var(--border-subtle);
  }

  .responsive-table td::before {
    content: attr(data-label); /* Render column header from data attribute! */
    font-weight: 600;
    color: var(--text-secondary);
  }
}
```

---

## 4. Touch-First Mobile UX Guidelines

1. **Thumb Zone Ergonomics**: Place primary action buttons and navigation in the bottom 40% of the screen (the comfortable reach of the human thumb).
2. **Minimum 48x48px Touch Targets**: Ensure interactive elements have sufficient padding so users do not mis-tap neighboring links.
3. **No Hover-Dependent Critical Features**: Any feature accessible via hover on desktop MUST be accessible via tap/click or persistent icons on mobile.

---

**Execution Protocol**
1. **Use Container Queries for reusable design system components**: Ensures cards format properly inside sidebars, dialogs, and grids.
2. **Scale typography with `clamp()`**: Eliminates jarring font jumps across viewport resizes.
3. **Always provide mobile-friendly table alternatives**: Card stacking or smooth horizontal swipe with visual scroll indicators.

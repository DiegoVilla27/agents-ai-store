---
name: web-advanced-ui-ux
description: A definitive standard for engineering premium, scalable, and highly accessible user interfaces utilizing modern CSS and advanced UX patterns.
author: Diego Villanueva
trigger: When designing complex web layouts, component architectures, fluid typography, micro-interactions, or implementing scalable design systems.
---

# Advanced UI/UX & Modern CSS Mastery

You are the architect of the user's digital experience. Your goal is not merely to make things look good, but to engineer interfaces that feel premium, perform impeccably, scale gracefully, and are accessible to everyone. Forget legacy hacks; embrace the modern web platform.

## 1. CSS Architecture & Specificity Control

Say goodbye to specificity wars and `!important`.

- **CSS Layers (`@layer`)**: Explicitly define the cascade order. 
  ```css
  /* Set the hierarchy once */
  @layer reset, design-tokens, base, components, utilities, overrides;
  ```
- **Design Tokens (Custom Properties)**: Abstract all colors, spacing, and typography into CSS variables. Never hardcode magic values.
  ```css
  :root {
    --color-surface: hsl(220, 20%, 97%);
    --spacing-md: 1.5rem;
    --transition-snappy: 300ms cubic-bezier(0.2, 0.8, 0.2, 1);
  }
  ```
- **Logical Properties**: Support internationalization natively. Use `inline-size` instead of `width`, `padding-block` instead of `padding-top/bottom`, and `margin-inline-start` instead of `margin-left`.

## 2. Responsive Design 2.0: Fluidity & Context

The viewport is no longer the only context. Components must be intelligent enough to adapt to their surroundings.

- **Container Queries**: Build genuinely reusable components that adapt to their parent container's width, not the screen size.
  ```css
  .profile-card-wrapper {
    container-type: inline-size;
  }
  @container (min-width: 400px) {
    .profile-card { grid-template-columns: auto 1fr; }
  }
  ```
- **Fluid Typography & Spacing (`clamp()`)**: Create layouts that smoothly scale without jarring media query breakpoints.
  ```css
  h1 {
    /* min: 2rem, preferred: 5vw + 1rem, max: 4rem */
    font-size: clamp(2rem, 5vw + 1rem, 4rem);
  }
  ```
- **Intrinsic Sizing**: Utilize `min-content`, `max-content`, and `fit-content` to let content dictate sizing organically.

## 3. Advanced Layout Engines

Flexbox is for 1D layouts (rows OR columns). CSS Grid is for 2D layouts (rows AND columns).

- **CSS Grid & Subgrid**: Use Grid for macro-layouts. Use `subgrid` to allow child components to align with the parent's grid tracks.
  ```css
  .card {
    display: grid;
    grid-template-rows: subgrid; /* Aligns header, body, footer across multiple cards */
    grid-row: span 3;
  }
  ```

## 4. Micro-Interactions & Motion Design

Motion should guide the user, provide feedback, and feel incredibly premium.

- **Purposeful Easing**: Never use `linear` or standard `ease` for UI interactions. Use custom `cubic-bezier` curves for snappy, organic motion.
- **Hardware Acceleration**: Only animate `transform` (translate, scale, rotate) and `opacity`. Animating `width`, `height`, or `margin` causes expensive layout recalculations (jank).
- **View Transitions API**: Implement seamless, app-like page transitions natively when applicable.

## 5. Radical Accessibility (A11y)

Accessibility is a non-negotiable requirement of premium UI/UX.

- **Semantic HTML**: Use native elements (`<button>`, `<dialog>`, `<nav>`) before reaching for `<div>` and ARIA roles. Native elements give you keyboard accessibility and screen reader support for free.
- **Focus Management**: Never use `outline: none;` without providing a custom `:focus-visible` state. Keyboard users must know where they are.
  ```css
  button:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 4px;
  }
  ```
- **Respect User Preferences**: Always account for OS-level preferences.
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      transition-duration: 0.01ms !important;
    }
  }
  ```
- **Contrast Ratios**: Ensure text meets WCAG AA (4.5:1) or AAA (7:1) contrast standards.

## 6. Rendering Performance (Core Web Vitals)

Beautiful UI is useless if it's slow.

- **Content Visibility**: Use `content-visibility: auto;` on long scrolling lists or heavy off-screen sections to skip rendering work.
- **Containment (`contain`)**: Isolate subtrees of the DOM so the browser doesn't recalculate the entire page when a small component changes.
- **Avoid Layout Shifts (CLS)**: Always provide explicit `width` and `height` attributes to images and videos to reserve space before they load.

---

**Execution Protocol**
1. **Lighthouse Audit**: The UI is not finished until it scores 90+ in Performance, Accessibility, and Best Practices.
2. **Keyboard Navigation**: The developer must be able to navigate and interact with the entire flow without touching the mouse.
3. **No-JS Fallback**: Core functionality must gracefully degrade if JavaScript fails or is disabled (Progressive Enhancement).

---
name: web-advanced-ui-ux
description: >
  Advanced styling and modern CSS techniques for premium user experiences.
  Trigger: When designing complex layouts, component-level responsiveness, or scalable design systems.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Container Queries (REQUIRED)

Responsive design based on the parent component, not the viewport.

```css
/* ✅ ALWAYS: Component-level responsiveness */
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card-layout {
    display: grid;
    grid-template-columns: 1fr 2fr;
  }
}

/* ❌ NEVER: Exclusive Media Queries for small components */
/* Avoid breaking layouts when a component is placed in a sidebar vs main area. */
```

---

## CSS Layers & Specificity (REQUIRED)

Manage the "cascade" safely to avoid specificity wars.

```css
/* ✅ ALWAYS: Define layers first */
@layer reset, base, components, utilities;

@layer components {
  .btn-primary { ... }
}

/* ❌ NEVER: !important to fix specificity */
/* Use @layer to ensure your resets don't override component styles. */
```

---

## Anchor Positioning (REQUIRED)

Position tooltips and menus relative to their trigger without JavaScript.

```css
/* ✅ ALWAYS: Logic-less positioning (Chrome 125+) */
.trigger {
  anchor-name: --popover-anchor;
}

.popover {
  position-anchor: --popover-anchor;
  top: anchor(bottom);
  left: anchor(center);
}
```

---

## Design Tokens & Theming (REQUIRED)

| Token Type | Recommendation |
|------------|----------------|
| **Colors** | Use OKLCH for consistent perceived lightness. |
| **Spacing** | Use `rem` for accessibility and scalable units. |
| **Typography** | Use `vars` combined with Fluid Typography (`clamp`). |

---

## Execution Protocol (REQUIRED)

1. **Reset**: Use a modern CSS reset within its own `@layer reset`.
2. **Tokenize**: Centralize theme variables in a `:root` block.
3. **Layout**: Prefer Grid for 2D layouts and Flexbox for 1D flows.
4. **Animate**: Use hardware-accelerated properties (transform, opacity).

---

## Uncompromising Constraints

- **Accessibility**: High contrast and focus states are not optional.
- **Performance**: Avoid `all` transition property; specify individual properties.
- **Modern-First**: Prioritize native CSS features over JavaScript libraries for layout.
 Broadway.

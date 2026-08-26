---
name: motion-design-principles
description: The ultimate architectural standard for Motion Design, Animation Curves (Spring Physics, Cubic Bézier), Choreography, and prefers-reduced-motion Accessibility.
author: Diego Villanueva
trigger: When animating user interfaces, defining spring curves, designing transition choreography, staggering list animations, or implementing prefers-reduced-motion.
---

# Enterprise Motion Design & Animation Architecture

Motion in UI design is not decoration; it is functional communication. Motion explains spatial relationships, reinforces cause-and-effect physics, and directs user attention. An Enterprise Visual Architect uses **Spring Physics**, **Choreographed Staggering**, and **Duration Thresholds**.

---

## 1. The Physics of UI Motion: Springs vs Cubic Bézier

Linear animations feel robotic and unnatural because real-world objects have mass, friction, and inertia.

| Motion Type | Mathematical Curve | Best Used For |
|---|---|---|
| **Spring Physics** | `damping: 20, stiffness: 300, mass: 1` | Interactive elements, drag-and-drop, gesture releases |
| **Ease-Out (Deceleration)** | `cubic-bezier(0.16, 1, 0.3, 1)` (Expo Out) | Elements entering the screen (dialogs, toasts) |
| **Ease-In (Acceleration)** | `cubic-bezier(0.7, 0, 0.84, 0)` (Expo In) | Elements exiting the screen (closing modals) |
| **Standard Ease** | `cubic-bezier(0.2, 0, 0, 1)` | In-place property changes (colors, borders) |

---

## 2. Duration Guidelines (The Human Perception Thresholds)

- **Micro-interactions (Hover, Active Click, Toggle)**: `100ms - 150ms`. Faster than 100ms feels abrupt; slower than 200ms feels laggy.
- **Medium Transitions (Dropdowns, Tooltips, Accordions)**: `200ms - 300ms`.
- **Large Transitions (Modal Open, Page Route Change, Drawer Slide)**: `350ms - 500ms`.
- **Over 500ms**: Strictly reserved for loading animations or celebratory confetti effects.

```css
/* Design System Motion Tokens */
:root {
  --ease-spring: cubic-bezier(0.175, 0.885, 0.32, 1.275);
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in-expo: cubic-bezier(0.7, 0, 0.84, 0);

  --duration-fast: 150ms;
  --duration-base: 250ms;
  --duration-slow: 400ms;
}
```

---

## 3. Choreography & Staggering (Hierarchical Reveal)

When revealing a list of 5 cards, never animate all 5 simultaneously (causes visual chaos). **Stagger** their entrance sequentially by `30ms - 50ms`:

```tsx
// Using Framer Motion Staggered Variants
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05, // 50ms delay between consecutive items
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20, scale: 0.98 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      type: 'spring',
      damping: 25,
      stiffness: 350,
    },
  },
};
```

---

## 4. Accessibility: `prefers-reduced-motion` Compliance

Users with vestibular motion disorders can experience severe nausea from sweeping camera movements or large scaling effects.

**✅ ALWAYS** respect `prefers-reduced-motion`:

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### In React / Framer Motion:

```tsx
import { useReducedMotion } from 'framer-motion';

export function AnimatedCard({ children }: { children: React.ReactNode }) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.div
      initial={{ opacity: 0, y: shouldReduceMotion ? 0 : 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25 }}
    >
      {children}
    </motion.div>
  );
}
```

---

**Execution Protocol**
1. **Never use Linear (`linear`) for UI state transitions**: Always use Ease-Out or Spring curves.
2. **Never exceed 300ms for user-initiated clicks**: Keep UI responsive.
3. **Animate ONLY `transform` and `opacity`**: Animating `height`, `width`, or `margin` triggers costly browser layout reflows and drops FPS.
4. **Mandate `prefers-reduced-motion`**: Invert motion into simple opacity fades.

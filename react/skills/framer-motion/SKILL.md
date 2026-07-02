---
name: framer-motion
description: The definitive architectural standard for building 60FPS physics-based animations, layout transitions, and micro-interactions in React Web.
author: Diego Villanueva
trigger: When building web animations, configuring AnimatePresence for entering/exiting elements, or implementing complex scroll/drag gestures.
---

# Framer Motion & Animation Architecture

Animation is not decoration; it is communication. Framer Motion is the industry standard for React because it relies on physics (springs) rather than time (easing curves) to create fluid, interruptible, and natural motion. Your goal is to make the interface feel alive without sacrificing 60FPS performance.

## 1. The Core Paradigm (`motion` Components)

Instead of using standard HTML tags, you must use their `motion` equivalents (e.g., `motion.div`, `motion.button`). These components are highly optimized DOM nodes that bypass React's render cycle during active animations.

```tsx
// ✅ ALWAYS: Declarative motion components
import { motion } from 'framer-motion';

export function Card() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: "spring", stiffness: 300, damping: 20 }}
    >
      Content
    </motion.div>
  );
}
```

## 2. Orchestration with Variants (Crucial for Scalability)

Never hardcode massive animation objects directly into JSX props if they affect multiple children. Use `variants` to orchestrate staggered, complex timelines cleanly.

- **Propagation**: Variants automatically propagate from parent to children if they share the same keys (`initial`, `animate`).
- **Staggering**: Use `staggerChildren` and `delayChildren` to create sequential cascades without writing manual delays for each item.

```tsx
// ✅ ALWAYS: Variant Orchestration
const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.1 }
  }
};

const item = {
  hidden: { opacity: 0, x: -50 },
  show: { opacity: 1, x: 0 }
};

export function List() {
  return (
    <motion.ul variants={container} initial="hidden" animate="show">
      <motion.li variants={item}>Item 1</motion.li>
      <motion.li variants={item}>Item 2</motion.li>
    </motion.ul>
  );
}
```

## 3. Entering & Exiting (`AnimatePresence`)

React cannot animate components that unmount because they instantly disappear from the DOM. `AnimatePresence` defers the unmounting process until the `exit` animation completes.

- **Unique Keys**: The immediate children of `AnimatePresence` MUST have unique `key` props.
- **Initial Mount**: Set `initial={false}` on `AnimatePresence` if you want to skip the animation on the very first page load.

```tsx
// ✅ ALWAYS: Graceful unmounting
import { motion, AnimatePresence } from 'framer-motion';

export function Modal({ isOpen, onClose }) {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          key="modal"
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.9 }}
        />
      )}
    </AnimatePresence>
  );
}
```

## 4. Magic Layout Animations (The FLIP Technique)

Animating `width`, `height`, or `justify-content` usually causes massive layout thrashing and drops frames. Framer Motion solves this mathematically using the FLIP (First, Last, Invert, Play) technique via the `layout` prop.

- **`layout`**: Simply adding this prop makes the component smoothly transition from its old physical space to its new space (e.g., when a list reorders).
- **`layoutId`**: The holy grail. If two completely different components in the DOM tree share the same `layoutId`, Framer Motion will magically morph one into the other when they mount/unmount.

```tsx
// ✅ ALWAYS: Magic Shared Element Transitions
import { motion } from 'framer-motion';

export function TabBar({ activeTab }) {
  return (
    <div className="flex">
      {tabs.map(tab => (
        <div key={tab.id} className="relative">
          {tab.title}
          {activeTab === tab.id && (
            <motion.div
              layoutId="active-pill"
              className="absolute inset-0 bg-blue-500 rounded-full"
              transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
            />
          )}
        </div>
      ))}
    </div>
  );
}
```

## 5. High-Performance Scroll & Parallax

Never attach native `window.addEventListener('scroll')` to drive animations. It forces React to re-render 60 times a second.

- **`useScroll`**: Extracts scroll progress efficiently.
- **`useTransform`**: Maps the scroll progress to style values (like opacity or scale).
- **`motion.div style`**: Passing these MotionValues directly to the `style` prop updates the DOM node directly without re-rendering the React component.

```tsx
// ✅ ALWAYS: Re-render free scroll animations
import { motion, useScroll, useTransform } from 'framer-motion';

export function ParallaxHeader() {
  const { scrollY } = useScroll();
  const y = useTransform(scrollY, [0, 500], [0, 200]); // Parallax effect
  const opacity = useTransform(scrollY, [0, 300], [1, 0]); // Fade out

  // Component does NOT re-render on scroll!
  return <motion.header style={{ y, opacity }} />;
}
```

## 6. Gestures & Interactivity

Forget standard CSS `:hover` or JS `onMouseDown`.

- Use `whileHover` and `whileTap` for immediate, spring-based feedback.
- Use `drag`, `dragConstraints`, and `dragElastic` for draggable interfaces (like swipe-to-delete or carousels).

```tsx
// ✅ ALWAYS: Physics-based interactions
<motion.button
  whileHover={{ scale: 1.05 }}
  whileTap={{ scale: 0.95 }}
  transition={{ type: "spring", stiffness: 400, damping: 17 }}
>
  Click Me
</motion.button>
```

## 7. Accessibility (Reduced Motion)

Animations can cause vestibular disorders (nausea, dizziness) in some users. You MUST respect the OS-level "Reduce Motion" preference.

```tsx
// ✅ ALWAYS: Respect OS preferences
import { useReducedMotion } from 'framer-motion';

export function AccessibleBox() {
  const shouldReduceMotion = useReducedMotion();
  
  return (
    <motion.div
      animate={{ 
        x: shouldReduceMotion ? 0 : 100, 
        opacity: 1 
      }}
    />
  );
}
```

---

**Execution Protocol**
1. **Never Animate Layout Properties Directly**: Do NOT animate `width`, `height`, `top`, or `margin` inside `animate={{}}`. This triggers browser reflows. ALWAYS animate `x`, `y`, `scale`, or `opacity`. If you must animate layout, use the `layout` prop.
2. **Server-Side Rendering (SSR)**: If your app uses Next.js, Framer Motion will render the `initial` state on the server. If this causes hydration mismatches, ensure your `initial` state is stable, or use `initial={false}` to skip the mount animation entirely if the component starts visually active.
3. **Bundle Size Optimization**: Framer Motion is heavy (~30kb gzipped). For landing pages, consider using `LazyMotion` and `m` components to dynamically load the animation features only when needed.

---
description: 'Production-ready Animations and Gesture Handling'
author: 'Diego Villanueva'
trigger: 'When implementing micro-interactions, layout transitions, or complex gesture-based UI.'
---

# Framer Motion

The industry standard for premium React animations and interactions.

## ✅ ALWAYS
- Use `motion` components (`motion.div`, `motion.button`) for all animated elements.
- Use `AnimatePresence` for handling entry/exit animations of components.
- Leverage `layout` prop for smooth layout-based transitions (Automatic FLIP).
- Use `variants` to orchestrate complex multi-step animations.
- Use `useScroll` and `useTransform` for scroll-based parallax effects.

## ❌ NEVER
- Use `useEffect` + manual CSS for things Framer Motion can handle declaratively.
- Over-animate; focus on meaningful motion that aids user understanding.
- Forget to set `initial={false}` on `AnimatePresence` if you don't want initial load animations.

## 🛠 Patterns
- **Shared Layout Animations**: Using `layoutId` to animate elements between different components.
- **Gesture Hooks**: Using `whileHover`, `whileTap`, and `whileDrag` for instant feedback.

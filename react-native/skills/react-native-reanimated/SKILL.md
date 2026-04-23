---
description: 'High-Performance 60fps Animations and Gestures'
author: 'Diego Villanueva'
trigger: 'When implementing complex UI animations, scroll effects, or gesture-based interactions.'
---

# React Native Reanimated

Mastery of the Worklet-based animation engine for buttery smooth interfaces.

## ✅ ALWAYS
- Use **Reanimated v3** for the best performance and simplified API.
- Use `useSharedValue` for reactive animation state.
- Use `useAnimatedStyle` to map shared values to component styles.
- Use `withSpring` and `withTiming` for fluid value transitions.
- Combine with **Gesture Handler** (`useAnimatedGestureHandler`) for touch-based motion.
- Ensure all animation logic runs on the UI thread (Worklets).

## ❌ NEVER
- Use the standard `Animated` API for complex or high-frequency animations.
- Perform heavy JS logic inside an animated style or worklet.
- Mutate shared values directly from the JS thread during an animation loop.

## 🛠 Patterns
- **Layout Animations**: Automatic entry, exit, and layout change animations.
- **Interpolation**: Mapping scroll positions to visual properties (opacity, scale).

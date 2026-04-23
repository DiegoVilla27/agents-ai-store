---
description: 'Mastering Flutter Animations and Visual Feedback'
author: 'Diego Villanueva'
trigger: 'When the user needs complex animations, transitions, or physics-based motion.'
---

# Flutter Animations & Motion

Mastery of the Flutter Animation framework to create premium, fluid, and high-performance visual experiences.

## ✅ ALWAYS
- Use `ImplicitlyAnimatedWidgets` (`AnimatedContainer`, `AnimatedOpacity`) for simple transitions.
- Use `AnimationController` and `Tween` for fine-grained control over complex animations.
- Wrap animations in `AnimatedBuilder` or `Listener` to optimize rebuilds.
- Use `RepaintBoundary` to isolate animated areas and improve FPS.
- Follow the 60/120 FPS rule: Never block the UI thread during animations.

## ❌ NEVER
- Rebuild the entire widget tree inside an animation listener.
- Forget to `dispose()` the `AnimationController`.
- Use `setState()` inside a `Ticker` callback if a specialized widget exists.

## 🛠 Patterns
- **Explicit Animations**: Controller -> Tween -> Animation -> AnimatedBuilder.
- **Staggered Animations**: Use multiple Tweens with different intervals.
- **Hero Transitions**: For seamless screen-to-screen element transitions.

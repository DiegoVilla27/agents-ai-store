---
description: 'Complex Layout Construction and Adaptive UI'
author: 'Diego Villanueva'
trigger: 'When building intricate UI structures, responsive layouts, or custom painting.'
---

# Flutter Layouts & Adaptive UI

Mastery of the Flutter rendering system for pixel-perfect and responsive interfaces.

## ✅ ALWAYS
- Use `LayoutBuilder` for responsive decision-making based on parent constraints.
- Implement `CustomScrollView` and `Slivers` for advanced scrolling effects.
- Use `IntrinsicHeight` sparingly only when necessary.
- Leverage `Flex`, `Expanded`, and `Flexible` for fluid proportions.
- Test UI on multiple screen sizes and pixel densities.

## ❌ NEVER
- Use hardcoded `height` or `width` for complex UI components.
- Wrap everything in a `ListView` if it doesn't need to scroll; use `Column`.
- Ignore the "Unbounded constraints" error; understand parent-child contract.

## 🛠 Patterns
- **Breakpoint System**: Defining UI changes based on screen width.
- **Intrinsic Ratio**: Maintaining aspect ratios using `AspectRatio` widget.

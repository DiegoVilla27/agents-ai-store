---
description: 'Utility-First Styling for Mobile with NativeWind'
author: 'Diego Villanueva'
trigger: 'When implementing UI styles using Tailwind CSS in React Native.'
---

# React Native + Tailwind (NativeWind)

Mastery of the utility-first styling workflow for mobile.

## ✅ ALWAYS
- Use **NativeWind v4** for the latest features and performance.
- Use `className` (with the NativeWind plugin) to apply styles.
- Define theme extensions (colors, spacing) in `tailwind.config.js`.
- Use responsive modifiers (`sm:`, `md:`) for tablet and large screen support.
- Use the `styled()` HOC for wrapping third-party components.

## ❌ NEVER
- Hardcode colors or spacing values; use the Tailwind theme tokens.
- Use complex CSS properties not supported by the React Native layout engine.

## 🛠 Patterns
- **Dark Mode**: Using the `dark:` modifier for seamless theme switching.
- **Platform Specific Styling**: Using `ios:` and `android:` modifiers for platform-specific tweaks.

---
description: 'Advanced Material 3 Theming and Design Systems'
author: 'Diego Villanueva'
trigger: 'When defining app-wide styles, dark mode support, or custom design systems.'
---

# Flutter Theming & Design Systems

Standardized implementation of Material 3 design systems and dynamic theming.

## ✅ ALWAYS
- Use `ThemeData.useMaterial3 = true`.
- Define a `ColorScheme` using `ColorScheme.fromSeed`.
- Access colors via `Theme.of(context).colorScheme.primary` etc.
- Implement both `lightTheme` and `darkTheme` in the `MaterialApp`.
- Create `ThemeExtension` for custom design tokens (e.g., specific brand colors or spacing).

## ❌ NEVER
- Hardcode hex colors inside widgets.
- Use `Colors.white` or `Colors.black` directly; use the color scheme tokens.
- Rely on default component styles without checking accessibility/contrast.

## 🛠 Patterns
- **Theme Extensions**: For project-specific design tokens.
- **Dynamic Color**: Integration with Android 12+ wallpaper colors.

---
description: 'Accessibility and Inclusive UI Standards'
author: 'Diego Villanueva'
trigger: 'When building UI components, forms, or custom interactive elements.'
---

# React Accessibility (a11y)

Ensuring your applications are usable by everyone, including assistive technology users.

## ✅ ALWAYS
- Use semantic HTML (`<button>`, `<nav>`, `<main>`) instead of nested `<div>`s.
- Provide `aria-label` or `aria-labelledby` for interactive elements without text.
- Ensure proper keyboard focus management and visible focus indicators.
- Use `aria-live` regions for dynamic content updates (e.g., notifications).
- Ensure a contrast ratio of at least 4.5:1 for text.

## ❌ NEVER
- Use `onClick` on a `<div>` or `<span>` without adding `role="button"` and keyboard support.
- Remove `outline: none` without providing a custom visible focus style.
- Use images for meaningful content without providing `alt` text.

## 🛠 Patterns
- **Focus Trap**: Ensuring keyboard focus stays within modals or menus.
- **Skip Links**: Allowing users to bypass navigation and jump to content.

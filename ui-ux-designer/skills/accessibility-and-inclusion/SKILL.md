---
name: accessibility-and-inclusion
description: Ensuring the design is usable by all humans, strictly adhering to WCAG standards.
author: Diego Villanueva
trigger: When designing forms, interactive elements, or color palettes.
---

# UI/UX Master Class: Accessibility (a11y)

A design that only works for a 20-year-old with perfect vision and a 4K monitor is a failed design.

## ✅ ALWAYS

1.  **Color Contrast (WCAG AA/AAA)**:
    -   Text must have a contrast ratio of at least `4.5:1` against its background.
    -   Large text must have a ratio of at least `3.0:1`.

2.  **Focus States are Sacred**:
    -   Users navigating via keyboard (Tab) rely entirely on focus rings. 
    -   NEVER use `outline: none` without providing a custom, highly visible `:focus-visible` alternative (e.g., `ring-2 ring-blue-500 ring-offset-2`).

3.  **Do Not Rely on Color Alone**:
    -   If an input has an error, do not just turn the border red. (Colorblind users won't see it). 
    -   ALWAYS add an icon (e.g., a cross) or explicit error text below the input.

4.  **Touch Targets (Mobile)**:
    -   Any clickable element on a mobile device MUST be at least `44x44px`. Small buttons lead to frustrating "fat-finger" errors.

## ❌ NEVER

-   **Low-Contrast Placeholders**: Do not use extremely light gray (`#e5e7eb`) for placeholder text in inputs. 
-   **Jargon in Empty States**: Empty states and error messages should be written in plain, inclusive language.

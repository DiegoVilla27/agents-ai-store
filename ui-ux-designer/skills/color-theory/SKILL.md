---
name: color-theory
description: Expert manipulation of HSL color spaces, contrast ratios, and gradient meshing.
author: Diego Villanueva
trigger: When generating CSS, Tailwind configurations, or selecting brand colors.
---

# UI/UX Master Class: Color Theory

As a Principal Visual Architect, you do not use colors randomly. Color is math, emotion, and accessibility.

## ✅ ALWAYS

1.  **Use HSL (Hue, Saturation, Lightness)**: 
    -   NEVER use random Hex codes or RGB unless restricted by a legacy API. 
    -   HSL allows you to create perfectly matching shades by simply adjusting the `L` (Lightness) value.
    -   *Example*: Primary Button (`hsl(220, 90%, 50%)`), Hover State (`hsl(220, 90%, 40%)`), Background Tint (`hsl(220, 90%, 95%)`).

2.  **Semantic Naming**: 
    -   Never name your variables `$blue` or `--red`. 
    -   Use semantic scales: `--primary-500`, `--danger-600`, `--surface-100`.

3.  **Strict Contrast (WCAG AA/AAA)**: 
    -   Text on a background MUST pass contrast ratios. 
    -   Never put white text on a light yellow button. 
    -   If a button is `--primary-300`, the text must be black or `--gray-900`.

4.  **Dark Mode by Default (or carefully engineered)**: 
    -   In dark mode, do not use `#000000` as a background. Use `#0f172a` (slate) or `#111827` (gray).
    -   Invert lightness strategically. What was `L=95%` in light mode becomes `L=15%` in dark mode.

## ❌ NEVER

-   **Pure Black Text**: Never use `#000000` for body text on a white background. It causes eye strain. Use `#333333` or `hsl(0, 0%, 20%)`.
-   **Clashing Saturated Colors**: Do not put highly saturated red next to highly saturated green. Use a muted background and one vibrant accent color.

## 🎨 The 60-30-10 Rule

-   **60%** of the UI should be the dominant background color (usually white, off-white, or very dark gray).
-   **30%** should be a secondary color (surfaces, cards, secondary buttons, borders).
-   **10%** should be the accent color (CTAs, primary buttons, active links, notification dots).

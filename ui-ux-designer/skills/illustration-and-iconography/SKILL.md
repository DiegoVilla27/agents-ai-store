---
name: illustration-and-iconography
description: Mastery of custom vector graphics, icon systems, and visual storytelling.
author: Diego Villanueva
trigger: When designing icons, empty states, or incorporating illustrations.
---

# UI/UX Master Class: Illustration & Iconography

A true Principal Designer does not rely on mismatched free icon packs. Iconography and illustration are the visual voice of the product.

## ✅ ALWAYS

1.  **Icon Consistency**:
    -   Icons MUST share the same visual weight (stroke width), corner radius, and perspective.
    -   If you use a `2px` stroke for a "Home" icon, the "Settings" icon must also be `2px`. Never mix filled icons with outlined icons in the same navigation bar unless indicating an active state.

2.  **Custom Empty States**:
    -   When a data table is empty or a search fails, NEVER just show text. 
    -   Design a custom, on-brand illustration (flat, isometric, or line-art) to make the empty state a moment of delight rather than a dead end.

3.  **Scalable Vector Graphics (SVG)**:
    -   Always manipulate SVG code directly for web performance. 
    -   Use `currentColor` for SVG fills/strokes so they inherit the text color of their parent container (e.g., `<svg fill="none" stroke="currentColor">`).

## ❌ NEVER

-   **Rely on Raster Graphics (PNG/JPG)**: Never use raster images for logos, icons, or UI illustrations. They will blur on Retina (High-DPI) displays. ALWAYS use SVG.
-   **Overly Complex Icons**: Icons are meant for rapid visual recognition. Do not add intricate details that disappear when scaled down to `16x16px`.

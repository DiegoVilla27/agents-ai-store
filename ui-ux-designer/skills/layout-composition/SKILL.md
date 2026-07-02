---
name: layout-composition
description: Mastery of CSS Grid, Flexbox, whitespace, and responsive constraints.
author: Diego Villanueva
trigger: When building page structures, positioning elements, or implementing responsive design.
---

# UI/UX Master Class: Layout & Composition

A premium design relies heavily on how elements are arranged in space. Cluttered screens scream "amateur."

## ✅ ALWAYS

1.  **Embrace Negative Space (Whitespace)**:
    -   Whitespace is not empty space; it's active space that guides the eye.
    -   Double the padding/margins you initially think of. If a card has `p-4` (16px), try `p-8` (32px). Generous padding instantly elevates the design.

2.  **Use CSS Grid for 2D, Flexbox for 1D**:
    -   Use `display: grid` for complex page structures, galleries, or dashboards.
    -   Use `display: flex` for aligning items in a single row or column (Navbars, button groups, icon + text).

3.  **Constrain Maximum Widths**:
    -   A text paragraph should never be wider than `65-75 characters` (`max-w-3xl` in Tailwind).
    -   The main content container should have a max-width (e.g., `max-w-7xl` or `1280px`) and be centered (`mx-auto`). Don't stretch content to 100% on a 4K monitor.

4.  **Use Asymmetry to Create Interest**:
    -   Perfect symmetry can be boring. Try offsetting an image slightly over a background block.
    -   Use a 60/40 or 70/30 split for two-column layouts instead of a perfect 50/50 split.

## ❌ NEVER

-   **Fear the Scroll**: Users know how to scroll. Do not cram all information "above the fold" if it compromises the whitespace and hierarchy.
-   **Use Magic Numbers**: Do not use `margin-top: 13px;`. Always stick to a 4pt or 8pt grid system (e.g., `4, 8, 12, 16, 24, 32, 48, 64`). Tailwind handles this automatically (`mt-1`, `mt-2`, `mt-4`).
-   **Float Layouts**: Never use `float: left` for layout structuring. It belongs in 2005. Use Flexbox or Grid.

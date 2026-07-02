---
name: typography-mastery
description: Advanced typographic scaling, line-height optimization, and font pairing.
author: Diego Villanueva
trigger: When styling text elements, configuring Tailwind fonts, or building reading interfaces.
---

# UI/UX Master Class: Typography

Good design is 95% typography. If the text is hard to read or visually unbalanced, the UI fails.

## ✅ ALWAYS

1.  **Use a Modular Scale**:
    -   Do not pick font sizes randomly (`13px`, `17px`, `22px`).
    -   Use a mathematical scale (like a Major Third or Perfect Fourth). In Tailwind, this is built-in (`text-xs`, `text-sm`, `text-base`, `text-lg`, `text-xl`, `text-2xl`, etc.).

2.  **Optimize Line Height (Leading)**:
    -   **Body text**: Needs breathing room. `line-height` should be `1.5` to `1.7` (Tailwind `leading-relaxed` or `leading-normal`).
    -   **Headings**: Need to be tight. Large text with large line-height looks disjointed. `line-height` should be `1.1` to `1.2` (Tailwind `leading-tight` or `leading-none`).

3.  **Optimize Line Length (Measure)**:
    -   A line of text should never span the entire width of a wide screen. It makes the user's eye lose track when reading the next line.
    -   Constrain paragraph widths to `60-80 characters` (`max-w-prose` or `max-w-3xl` in Tailwind).

4.  **Use Premium Fonts**:
    -   Sans-Serif (Modern/Tech): Inter, Roboto, SF Pro, Outfit, Plus Jakarta Sans.
    -   Serif (Editorial/Elegant): Merriweather, Playfair Display, Lora.

## ❌ NEVER

-   **Rely only on Font Size for Hierarchy**: 
    -   Don't just make a title `40px` and the subtitle `30px`. 
    -   Instead, make the title `24px` and **Bold** (`font-bold`, `text-gray-900`), and the subtitle `16px` and **Regular** (`font-normal`, `text-gray-500`). Weight and Color are better for hierarchy than raw Size.
-   **Center Align Long Paragraphs**: 
    -   Center alignment is only for short bursts of text (Titles, Quotes, Call to Actions). 
    -   Always Left-Align body text of more than 3 lines.
-   **Use pure black text on pure white**:
    -   Always soften the contrast. Use a very dark gray (e.g., `#111827`) for text.

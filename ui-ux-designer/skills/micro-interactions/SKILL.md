---
name: micro-interactions
description: Mastery of CSS transitions, hover states, active states, and Framer Motion.
author: Diego Villanueva
trigger: When styling buttons, cards, modals, or creating Framer Motion animations.
---

# UI/UX Master Class: Micro-Interactions

A static UI is a dead UI. Micro-interactions breathe life into the application and provide critical feedback to the user.

## ✅ ALWAYS

1.  **Style the Hover State (`:hover`)**:
    -   Every interactive element MUST change when hovered.
    -   *Buttons*: Darken/lighten the background color, add a soft glow (shadow), or slightly lift the button (`transform: translateY(-2px)`).
    -   *Cards*: Increase the drop shadow significantly to make it feel like it's lifting off the page.

2.  **Style the Active State (`:active`)**:
    -   When a user clicks, the element should react instantly.
    -   *Standard rule*: Scale the element down slightly (`transform: scale(0.95)` or `scale(0.97)`). This provides a satisfying "click" feel, similar to a physical button.

3.  **Use Fluid Transitions (`transition`)**:
    -   Never allow a color or transform to snap instantly.
    -   Use `transition: all 0.2s ease-in-out` (or specific properties: `transition: transform 0.2s, box-shadow 0.2s`).
    -   Tailwind makes this easy: `transition-all duration-200 ease-in-out`.

4.  **Style the Focus State (`:focus-visible`)**:
    -   Accessibility is mandatory. When a user tabs via keyboard, they must see where they are.
    -   Use a distinct focus ring (e.g., `ring-2 ring-primary-500 ring-offset-2`). Do NOT use the ugly default browser outline unless styled properly.

## 🚀 Advanced (Framer Motion / Reanimated)

If the project uses Framer Motion (React) or Reanimated (React Native):

1.  **Layout Animations**: Use `layoutId` (Framer Motion) to magically animate a component moving from one part of the DOM to another.
2.  **Spring Physics**: Avoid linear timings (`ease-linear`). Use Spring animations for organic, bouncy movement.
    -   *Framer Motion*: `transition={{ type: "spring", stiffness: 400, damping: 10 }}`.
3.  **Staggered Children**: When a list appears, don't show all 10 items instantly. Use staggered animations to let them cascade in one by one.

## ❌ NEVER

-   **Animate Width/Height or Margins**: Animating dimensions triggers "Layout Reflows" in the browser, causing stuttering and dropping frames. 
-   **Animate Transform/Opacity Instead**: ALWAYS animate `transform` (scale, translate) and `opacity`. These are GPU-accelerated and guarantee 60fps.

---
name: 3d-and-spatial-design
description: Creating depth, ray-traced lighting illusions, and WebGL integrations.
author: Diego Villanueva
trigger: When designing modern landing pages, hero sections, or interactive product showcases.
---

# UI/UX Master Class: 3D & Spatial Design

Modern web design has moved beyond flat interfaces. We now design for spatial computing and extreme depth.

## ✅ ALWAYS

1.  **Multi-Layered Drop Shadows (Lighting Ilusion)**:
    -   To simulate real-world light, do not use a single drop shadow. 
    -   Combine multiple shadows: A tight, dark shadow for contact (`0 1px 2px rgba(0,0,0,0.1)`), and a wide, soft shadow for ambient occlusion (`0 20px 40px rgba(0,0,0,0.05)`).

2.  **Inner Shadows for Volume**:
    -   To make elements feel like physical objects (Neumorphism / Skeuomorphism), use subtle inner shadows and borders.
    -   Example: A top inner border of `rgba(255, 255, 255, 0.4)` makes a button look like it is catching overhead light.

3.  **WebGL / Three.js Context**:
    -   When integrating 3D models (Spline, Three.js), the surrounding UI MUST step back. Let the 3D element be the hero. 
    -   Use translucent UI cards (Glassmorphism) over the 3D canvas so the 3D space feels contiguous.

## ❌ NEVER

-   **Overuse 3D Depth**: Do not apply heavy 3D bevels to data-heavy dashboards. 3D is for marketing pages, hero sections, and product showcases. Dashboards require maximum legibility (flat or subtle layers).
-   **Ignore Performance**: Do not render massive WebGL canvases without a fallback for low-end devices. Always lazy-load 3D assets.

---
name: dark-mode-theming
description: The ultimate architectural standard for Enterprise Dark Mode Theming, Surface Elevation Luminance Hierarchies, Contrast Preservation, and Pure Black OLED Fatigue Prevention.
author: Diego Villanueva
trigger: When implementing dark mode, designing themes, calculating surface elevations in dark mode, or preventing contrast strain in dark UI.
---

# Enterprise Dark Mode Theming & Elevation Architecture

Dark mode is not just inverting white to black. Inverting colors creates harsh, vibrating contrasts, eye strain, and destroys depth perception. An Enterprise Visual Architect uses **Surface Luminance Elevation**, **Desaturated Accent Palettes**, and **Warm Grays (Zinc/Slate)** to create a luxurious dark interface.

---

## 1. The Pure Black (`#000000`) Trap vs Luminance Elevation

**❌ NEVER** make the main canvas `#000000` with pure white `#FFFFFF` text (unless designing for specific OLED battery savers). It causes severe visual halation, astigmatism blur, and eye fatigue.
**✅ ALWAYS** use deep, rich grays (`#09090b` or `#0f172a`) for the base background, and elevate surfaces by increasing **Luminance** rather than casting shadows.

### In Dark Mode: Surface Elevation = Higher Lightness

```text
┌─────────────────────────────────────────────────────────┐
│ Level 3: Modals / Popovers (Luminance: ~16%)            │
│          bg: hsl(240, 5%, 16%) / #27272a                │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│ Level 2: Cards / Sidebars (Luminance: ~12%)             │
│          bg: hsl(240, 5%, 12%) / #18181b                │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│ Level 1: Canvas Base Background (Luminance: ~6%)        │
│          bg: hsl(240, 10%, 4%) / #09090b                │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Contrast & Saturation Rules in Dark Mode

1. **Desaturate Brand Accents**: Saturated colors that look vibrant on white look blinding on dark backgrounds. Lower saturation by 10-15% in dark mode.
2. **Text Hierarchy by Opacity**:
   - **Primary Text**: `rgba(255, 255, 255, 0.92)` or `#f4f4f5` (Not `#ffffff`).
   - **Secondary Text**: `rgba(255, 255, 255, 0.65)` or `#a1a1aa`.
   - **Disabled/Muted**: `rgba(255, 255, 255, 0.40)` or `#71717a`.
3. **Subtle Light Borders**: Shadows are invisible on dark backgrounds. Separate cards from canvas using subtle 1px border highlights: `border: 1px solid rgba(255, 255, 255, 0.08)`.

---

## 3. Theming Tokens Implementation

```css
/* src/styles/dark-mode.css */
.dark {
  /* Canvas & Surface Elevations */
  --bg-canvas: hsl(240, 10%, 4%);        /* Deep Zinc */
  --bg-surface: hsl(240, 5%, 10%);       /* Card Background */
  --bg-elevated: hsl(240, 5%, 15%);      /* Modal & Dropdown */

  /* Text Contrast */
  --text-primary: hsl(0, 0%, 98%);
  --text-secondary: hsl(240, 5%, 65%);
  --text-muted: hsl(240, 4%, 46%);

  /* Borders & Dividers */
  --border-subtle: hsl(240, 4%, 16%);
  --border-strong: hsl(240, 5%, 26%);

  /* Adjusted Brand Accent */
  --action-primary: hsl(217, 91%, 60%);
  --action-primary-hover: hsl(217, 91%, 68%);

  /* Dark Mode Inset Glow Shadow */
  --shadow-elevated: 0 0 0 1px rgba(255, 255, 255, 0.08), 0 20px 25px -5px rgba(0, 0, 0, 0.5);
}
```

---

## 4. Flash of Light Theme (FOUC) Elimination

When using SSR (Next.js, Remix, Astro), the page may flash white for 100ms before reading the user's theme preference from localStorage.

**✅ ALWAYS** inject a synchronous blocking script in the HTML `<head>`:

```html
<!-- Injects theme class before first paint to prevent white flash -->
<script>
  (function() {
    var storedTheme = localStorage.getItem('theme');
    var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (storedTheme === 'dark' || (!storedTheme && prefersDark)) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  })();
</script>
```

---

**Execution Protocol**
1. **Never use `#000000` background with `#ffffff` text**: Use rich dark grays with 90% opacity text.
2. **Elevate surfaces with lighter backgrounds, not drop shadows**: Shadows are physically invisible in dark environments.
3. **Use 1px `rgba(255, 255, 255, 0.08)` borders to define card boundaries**: Adds high-end structural crispness.
4. **Always test images and logos in both modes**: Provide inverted transparent SVG assets for dark mode.

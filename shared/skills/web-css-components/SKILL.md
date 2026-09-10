---
name: web-css-components
description: The definitive pattern library for engineering premium CSS component effects including glassmorphism, neumorphism, gradients, clip-path, scroll-snap, skeleton loading, and advanced visual effects.
author: Diego Villanueva
trigger: When implementing glassmorphism, neumorphism, skeleton loading, gradients, clip-path, scroll-snap, backdrop-filter, mask-image, custom scrollbars, or advanced CSS visual patterns.
---

# CSS Component Patterns & Visual Effects Mastery

You are an expert Visual CSS Engineer. Your directive is to build premium, production-grade UI effects and component patterns that feel polished, perform at 60fps, and degrade gracefully in older browsers. Every effect must serve a UX purpose — never decoration for decoration's sake.

---

## 1. Glassmorphism (Frosted Glass Effect)

The premium glass-panel effect for overlays, cards, and navigation.

```css
.glass-card {
  background: hsl(0 0% 100% / 0.08);
  backdrop-filter: blur(16px) saturate(180%);
  -webkit-backdrop-filter: blur(16px) saturate(180%);
  border: 1px solid hsl(0 0% 100% / 0.15);
  border-radius: var(--radius-xl);
  box-shadow:
    0 8px 32px hsl(0 0% 0% / 0.12),
    inset 0 1px 0 hsl(0 0% 100% / 0.1);
}

/* Dark variant */
.glass-card--dark {
  background: hsl(220 25% 10% / 0.6);
  backdrop-filter: blur(20px) saturate(150%);
  border-color: hsl(0 0% 100% / 0.08);
}

/* Navigation bar */
.glass-nav {
  position: fixed;
  inset-block-start: 0;
  inset-inline: 0;
  background: hsl(0 0% 100% / 0.7);
  backdrop-filter: blur(12px) saturate(180%);
  -webkit-backdrop-filter: blur(12px) saturate(180%);
  border-block-end: 1px solid hsl(0 0% 0% / 0.06);
  z-index: var(--z-sticky);
}

/* Graceful fallback */
@supports not (backdrop-filter: blur(1px)) {
  .glass-card {
    background: hsl(220 25% 15% / 0.95);
  }
}
```

---

## 2. Neumorphism (Soft UI)

Subtle embossed/debossed effects using dual-directional shadows:

```css
:root {
  --neu-bg: hsl(220 15% 92%);
  --neu-shadow-light: hsl(0 0% 100% / 0.7);
  --neu-shadow-dark: hsl(220 20% 80% / 0.5);
}

.neu-card {
  background: var(--neu-bg);
  border-radius: var(--radius-xl);
  box-shadow:
    8px 8px 16px var(--neu-shadow-dark),
    -8px -8px 16px var(--neu-shadow-light);
}

/* Pressed/inset state */
.neu-card--inset {
  box-shadow:
    inset 4px 4px 8px var(--neu-shadow-dark),
    inset -4px -4px 8px var(--neu-shadow-light);
}

/* Toggle button */
.neu-toggle {
  background: var(--neu-bg);
  border: none;
  border-radius: var(--radius-full);
  padding: var(--spacing-3) var(--spacing-6);
  box-shadow:
    4px 4px 8px var(--neu-shadow-dark),
    -4px -4px 8px var(--neu-shadow-light);
  transition: box-shadow 200ms var(--ease-snappy);
  cursor: pointer;

  &:active,
  &[aria-pressed="true"] {
    box-shadow:
      inset 3px 3px 6px var(--neu-shadow-dark),
      inset -3px -3px 6px var(--neu-shadow-light);
  }
}
```

---

## 3. Advanced Gradients

### A. Mesh Gradient Backgrounds

```css
.mesh-gradient {
  background:
    radial-gradient(at 20% 80%, hsl(260 80% 60% / 0.6) 0%, transparent 50%),
    radial-gradient(at 80% 20%, hsl(200 90% 50% / 0.5) 0%, transparent 50%),
    radial-gradient(at 50% 50%, hsl(340 80% 55% / 0.4) 0%, transparent 50%),
    hsl(220 30% 8%);
}

/* Animated gradient */
@keyframes gradient-shift {
  0%   { background-position: 0% 50%; }
  50%  { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

.animated-gradient {
  background: linear-gradient(
    -45deg,
    hsl(260 80% 60%),
    hsl(200 90% 50%),
    hsl(340 80% 55%),
    hsl(160 70% 45%)
  );
  background-size: 400% 400%;
  animation: gradient-shift 8s ease infinite;
}
```

### B. Text Gradient

```css
.gradient-text {
  background: linear-gradient(135deg, hsl(260 80% 60%), hsl(200 90% 50%));
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  color: transparent; /* Fallback */
}
```

### C. Border Gradient

```css
.gradient-border {
  position: relative;
  border-radius: var(--radius-lg);
  padding: var(--spacing-6);
  background: var(--color-surface);

  &::before {
    content: '';
    position: absolute;
    inset: 0;
    border-radius: inherit;
    padding: 2px; /* Border width */
    background: linear-gradient(135deg, hsl(260 80% 60%), hsl(200 90% 50%));
    mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
    mask-composite: exclude;
    -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
    -webkit-mask-composite: xor;
    pointer-events: none;
  }
}
```

---

## 4. Skeleton Loading

Production-grade skeleton screens for perceived performance:

```css
@keyframes shimmer {
  from { background-position: -200% 0; }
  to   { background-position: 200% 0; }
}

.skeleton {
  --skeleton-base: hsl(220 15% 92%);
  --skeleton-shine: hsl(220 15% 96%);

  background: linear-gradient(
    90deg,
    var(--skeleton-base) 25%,
    var(--skeleton-shine) 50%,
    var(--skeleton-base) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite linear;
  border-radius: var(--radius-md);
  color: transparent !important;
  user-select: none;
  pointer-events: none;

  /* Dark mode variant */
  @media (prefers-color-scheme: dark) {
    --skeleton-base: hsl(220 20% 18%);
    --skeleton-shine: hsl(220 20% 24%);
  }
}

.skeleton--text   { block-size: 1em; inline-size: 80%; }
.skeleton--title  { block-size: 1.5em; inline-size: 60%; }
.skeleton--avatar { block-size: 48px; inline-size: 48px; border-radius: var(--radius-full); }
.skeleton--image  { block-size: 200px; inline-size: 100%; }
.skeleton--button { block-size: 40px; inline-size: 120px; border-radius: var(--radius-md); }
```

---

## 5. `clip-path` — Shape Masking

### A. Geometric Shapes

```css
/* Diagonal section divider */
.diagonal-top {
  clip-path: polygon(0 0, 100% 0, 100% 85%, 0 100%);
}

.diagonal-bottom {
  clip-path: polygon(0 15%, 100% 0, 100% 100%, 0 100%);
}

/* Circle reveal on hover */
.circle-reveal {
  clip-path: circle(0% at 50% 50%);
  transition: clip-path 600ms var(--ease-out);

  &:hover,
  &.is-visible {
    clip-path: circle(100% at 50% 50%);
  }
}

/* Hexagon avatar */
.hex-avatar {
  clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
}
```

---

## 6. Scroll Snap

Native scroll snapping for carousels, galleries, and full-page sections:

```css
/* Horizontal carousel */
.carousel {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
  gap: var(--spacing-4);
  padding: var(--spacing-4);

  /* Hide scrollbar */
  scrollbar-width: none;
  &::-webkit-scrollbar { display: none; }
}

.carousel__slide {
  scroll-snap-align: center;
  flex: 0 0 min(300px, 85vw);
}

/* Full-page vertical snap */
.fullpage {
  overflow-y: auto;
  scroll-snap-type: y mandatory;
  block-size: 100dvh;
}

.fullpage__section {
  scroll-snap-align: start;
  block-size: 100dvh;
  display: grid;
  place-items: center;
}

/* Proximity snap (softer — doesn't force) */
.gallery {
  scroll-snap-type: x proximity;
}
```

---

## 7. `aspect-ratio` — Consistent Proportions

```css
/* Video embed 16:9 */
.video-container {
  aspect-ratio: 16 / 9;
  inline-size: 100%;
  border-radius: var(--radius-lg);
  overflow: hidden;
}

/* Square avatar */
.avatar {
  aspect-ratio: 1;
  inline-size: 48px;
  border-radius: var(--radius-full);
  object-fit: cover;
}

/* Card thumbnail */
.card__thumbnail {
  aspect-ratio: 4 / 3;
  inline-size: 100%;
  object-fit: cover;
}
```

---

## 8. Custom Scrollbars

```css
/* Modern scrollbar styling */
.custom-scroll {
  scrollbar-width: thin;
  scrollbar-color: var(--color-border) transparent;

  /* Webkit browsers */
  &::-webkit-scrollbar {
    inline-size: 6px;
    block-size: 6px;
  }

  &::-webkit-scrollbar-track {
    background: transparent;
  }

  &::-webkit-scrollbar-thumb {
    background: var(--color-border);
    border-radius: var(--radius-full);

    &:hover {
      background: var(--color-text-muted);
    }
  }
}

/* Auto-hide scrollbar */
.auto-hide-scroll {
  scrollbar-width: thin;
  scrollbar-color: transparent transparent;

  &:hover {
    scrollbar-color: var(--color-border) transparent;
  }
}
```

---

## 9. `mask-image` — Advanced Masking

```css
/* Fade out at bottom */
.fade-bottom {
  mask-image: linear-gradient(to bottom, black 70%, transparent 100%);
  -webkit-mask-image: linear-gradient(to bottom, black 70%, transparent 100%);
}

/* Fade edges (horizontal scroll indicator) */
.fade-edges {
  mask-image: linear-gradient(
    to right,
    transparent 0%,
    black 5%,
    black 95%,
    transparent 100%
  );
  -webkit-mask-image: linear-gradient(
    to right,
    transparent 0%,
    black 5%,
    black 95%,
    transparent 100%
  );
}

/* Circular vignette */
.vignette {
  mask-image: radial-gradient(circle at center, black 50%, transparent 80%);
  -webkit-mask-image: radial-gradient(circle at center, black 50%, transparent 80%);
}
```

---

## 10. Advanced Shadow Systems

```css
:root {
  /* Layered shadow system — more realistic depth */
  --shadow-elevation-low:
    0 1px 2px hsl(var(--shadow-hsl) / 0.07),
    0 1px 3px hsl(var(--shadow-hsl) / 0.05);

  --shadow-elevation-medium:
    0 2px 4px hsl(var(--shadow-hsl) / 0.07),
    0 4px 8px hsl(var(--shadow-hsl) / 0.06),
    0 8px 16px hsl(var(--shadow-hsl) / 0.04);

  --shadow-elevation-high:
    0 4px 8px hsl(var(--shadow-hsl) / 0.04),
    0 8px 16px hsl(var(--shadow-hsl) / 0.06),
    0 16px 32px hsl(var(--shadow-hsl) / 0.08),
    0 32px 64px hsl(var(--shadow-hsl) / 0.06);

  /* Light mode shadow color */
  --shadow-hsl: 220 25% 27%;
}

@media (prefers-color-scheme: dark) {
  :root {
    --shadow-hsl: 0 0% 0%;
  }
}
```

---

## 11. Focus Ring Patterns

```css
/* Universal focus-visible pattern */
:is(a, button, input, select, textarea, [tabindex]):focus-visible {
  outline: 2px solid var(--color-focus-ring);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}

/* Animated focus ring */
.focus-ring-animated:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
  animation: focus-pulse 1.5s ease infinite;
}

@keyframes focus-pulse {
  0%, 100% { outline-offset: 2px; }
  50%      { outline-offset: 4px; }
}
```

---

## 12. Summary of Banned Practices

- Using `backdrop-filter` without `@supports` fallback (Check browser support).
- `overflow: hidden` on scroll-snap containers (Breaks snapping).
- Decorative-only effects without UX purpose (Every effect must inform or guide).
- Forgetting `-webkit-` prefixes for `backdrop-filter`, `mask-image`, `background-clip`.
- Using `clip-path` on elements that receive focus without accessible alternatives.
- Custom scrollbar styles without `scrollbar-width` (Firefox support).

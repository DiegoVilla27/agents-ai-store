---
name: web-css-animations
description: The definitive standard for engineering high-performance CSS animations, transitions, scroll-driven animations, and View Transitions using modern browser APIs.
author: Diego Villanueva
trigger: When implementing CSS animations, transitions, keyframes, scroll-driven animations, View Transitions API, micro-interactions, easing functions, or hardware-accelerated motion.
---

# CSS Animations & Transitions Mastery

You are an expert Motion Design Engineer specializing in CSS-native animations. Your directive is to build silky-smooth (60/120 FPS), GPU-accelerated, accessible animations that enhance UX without causing layout jank, battery drain, or accessibility barriers. Every animation must have purpose — guide attention, provide feedback, or create spatial continuity.

---

## 1. The GPU Acceleration Mandate

The browser renders in two phases: **Layout/Paint** (CPU, expensive) and **Composite** (GPU, cheap). You MUST only animate properties handled by the compositor.

### Compositor-Safe Properties (✅ GPU-Accelerated)

| Property | Use For |
|----------|---------|
| `transform: translate()` | Moving elements |
| `transform: scale()` | Sizing effects |
| `transform: rotate()` | Rotation effects |
| `opacity` | Fade in/out |
| `filter` | Blur, brightness |
| `clip-path` | Reveal effects |

### Layout-Triggering Properties (❌ BANNED from Animation)

| Property | Why Banned |
|----------|-----------|
| `width`, `height` | Triggers full layout recalculation |
| `top`, `left`, `right`, `bottom` | Triggers layout |
| `margin`, `padding` | Triggers layout + paint |
| `border-width` | Triggers layout |
| `font-size` | Triggers layout + text reflow |

```css
/* ❌ JANKY: Triggers layout on every frame */
.card:hover {
  width: 320px;
  margin-top: 10px;
}

/* ✅ BUTTERY SMOOTH: GPU compositor only */
.card:hover {
  transform: scale(1.05) translateY(-4px);
  box-shadow: var(--shadow-lg);
}
```

---

## 2. Transitions — Micro-Interactions

Transitions animate property changes between two states. Use them for hover effects, focus states, and state toggles.

### A. Easing Functions

**❌ NEVER** use `linear` or default `ease` for UI transitions. They feel robotic.

```css
:root {
  /* ═══ Production Easing Tokens ═══ */
  --ease-out:       cubic-bezier(0.0, 0.0, 0.2, 1);    /* Deceleration — entering elements */
  --ease-in:        cubic-bezier(0.4, 0.0, 1, 1);      /* Acceleration — exiting elements */
  --ease-in-out:    cubic-bezier(0.4, 0.0, 0.2, 1);    /* Standard — state changes */
  --ease-bounce:    cubic-bezier(0.34, 1.56, 0.64, 1);  /* Overshoot — playful interactions */
  --ease-spring:    cubic-bezier(0.22, 1.0, 0.36, 1);   /* Spring — natural feel */
  --ease-snappy:    cubic-bezier(0.2, 0.8, 0.2, 1);     /* Snappy — quick response */
}
```

### B. Transition Patterns

```css
/* ═══ Button hover — snappy feedback ═══ */
.btn {
  transition:
    transform 200ms var(--ease-snappy),
    box-shadow 200ms var(--ease-snappy),
    background-color 150ms var(--ease-in-out);

  &:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-md);
  }

  &:active {
    transform: translateY(0) scale(0.98);
    transition-duration: 80ms;
  }
}

/* ═══ Card hover — lift effect ═══ */
.card {
  transition:
    transform 300ms var(--ease-spring),
    box-shadow 300ms var(--ease-out);

  &:hover {
    transform: translateY(-8px);
    box-shadow: var(--shadow-xl);
  }
}

/* ═══ Modal overlay ═══ */
.overlay {
  opacity: 0;
  pointer-events: none;
  transition: opacity 250ms var(--ease-out);

  &.is-visible {
    opacity: 1;
    pointer-events: auto;
  }
}
```

### C. Transition Rules
- ✅ **ALWAYS** specify individual properties (`transition: transform 200ms`) instead of `transition: all`.
- ✅ Keep transition durations **≤ 400ms** for UI interactions. Slower feels sluggish.
- ✅ Use `transition-duration: 80ms` on `:active` for instant tactile feedback.
- ❌ **NEVER** transition `all` — it animates properties you don't intend and causes performance issues.

---

## 3. `@keyframes` — Complex Animations

Use `@keyframes` for multi-step animations that can't be expressed as A→B transitions.

```css
/* ═══ Fade + slide entrance ═══ */
@keyframes slide-up-fade {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-enter {
  animation: slide-up-fade 500ms var(--ease-out) both;
}

/* ═══ Staggered children entrance ═══ */
.stagger-list > * {
  animation: slide-up-fade 400ms var(--ease-out) both;
}

.stagger-list > *:nth-child(1) { animation-delay: 0ms; }
.stagger-list > *:nth-child(2) { animation-delay: 75ms; }
.stagger-list > *:nth-child(3) { animation-delay: 150ms; }
.stagger-list > *:nth-child(4) { animation-delay: 225ms; }
.stagger-list > *:nth-child(5) { animation-delay: 300ms; }

/* ═══ Skeleton shimmer loading ═══ */
@keyframes shimmer {
  from { background-position: -200% 0; }
  to   { background-position: 200% 0; }
}

.skeleton {
  background: linear-gradient(
    90deg,
    var(--color-surface) 25%,
    var(--color-border) 50%,
    var(--color-surface) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite linear;
  border-radius: var(--radius-md);
}

/* ═══ Pulse indicator ═══ */
@keyframes pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50%      { opacity: 0.6; transform: scale(1.1); }
}

.status-live {
  animation: pulse 2s var(--ease-in-out) infinite;
}

/* ═══ Spin loader ═══ */
@keyframes spin {
  to { transform: rotate(360deg); }
}

.spinner {
  animation: spin 800ms linear infinite;
  inline-size: 1.5rem;
  block-size: 1.5rem;
  border: 2px solid var(--color-border);
  border-top-color: var(--color-primary);
  border-radius: var(--radius-full);
}
```

---

## 4. Scroll-Driven Animations (`animation-timeline`)

The modern CSS API for scroll-bound animations — no JavaScript required.

### A. Scroll Progress Animation

```css
/* Progress bar that fills as the user scrolls the page */
.scroll-progress {
  position: fixed;
  inset-block-start: 0;
  inset-inline-start: 0;
  inline-size: 100%;
  block-size: 3px;
  background: var(--color-primary);
  transform-origin: left;
  animation: scale-x linear both;
  animation-timeline: scroll(root);
}

@keyframes scale-x {
  from { transform: scaleX(0); }
  to   { transform: scaleX(1); }
}
```

### B. Scroll-Triggered Reveal

```css
/* Elements fade in when they enter the viewport */
@keyframes reveal {
  from {
    opacity: 0;
    transform: translateY(40px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.reveal-on-scroll {
  animation: reveal linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}
```

### C. Parallax Effect (CSS-Only)

```css
.parallax-image {
  animation: parallax linear both;
  animation-timeline: view();
}

@keyframes parallax {
  from { transform: translateY(-15%); }
  to   { transform: translateY(15%); }
}
```

---

## 5. View Transitions API

Native page and state transitions for SPA-like experiences.

```css
/* Define transition names for morphing elements */
.card__image {
  view-transition-name: card-hero;
}

.page-title {
  view-transition-name: page-title;
}

/* Style the transition animation */
::view-transition-old(card-hero) {
  animation: fade-out 200ms var(--ease-in);
}

::view-transition-new(card-hero) {
  animation: fade-in 300ms var(--ease-out);
}

/* Cross-fade default for all other content */
::view-transition-old(root) {
  animation: fade-out 150ms var(--ease-in);
}

::view-transition-new(root) {
  animation: fade-in 200ms var(--ease-out);
}
```

---

## 6. `will-change` — GPU Layer Promotion

`will-change` hints to the browser that a property will change, allowing it to pre-promote the element to its own compositor layer.

```css
/* ✅ Apply ONLY to elements that will actually animate */
.carousel-slide {
  will-change: transform;
}

/* ✅ Remove after animation completes for static elements */
.card {
  &:hover {
    will-change: transform, box-shadow;
  }
}
```

### Rules
- ❌ **NEVER** use `will-change: all` or apply it globally (`* { will-change: transform; }`). It wastes GPU memory.
- ❌ **NEVER** keep `will-change` on elements that are not actively animating. Remove it via JavaScript or scoped states.
- ✅ Use it sparingly — each promoted layer consumes video memory.

---

## 7. Accessibility: `prefers-reduced-motion`

Some users experience motion sickness, seizures, or vestibular disorders. **This is non-negotiable.**

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Alternative: Provide Reduced Motion, Not No Motion

```css
.card {
  transition: transform 300ms var(--ease-spring);

  @media (prefers-reduced-motion: reduce) {
    transition: opacity 150ms var(--ease-out);
    /* Replace motion with a simple fade */
  }
}
```

---

## 8. Summary of Banned Practices

- Animating `width`, `height`, `top`, `left`, `margin`, `padding` (Use `transform` + `opacity`).
- `transition: all` (Specify exact properties).
- `will-change` on all elements or permanently (Apply scoped, remove after animation).
- `linear` easing for UI interactions (Use production `cubic-bezier` tokens).
- Missing `prefers-reduced-motion` fallback (Always provide it).
- Animations longer than 400ms for direct interactions (Feels sluggish).
- Decorative animations that distract without serving a UX purpose.

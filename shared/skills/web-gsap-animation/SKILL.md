---
name: web-gsap-animation
description: A comprehensive standard for engineering high-performance, responsive, and robust GSAP (GreenSock) animations and ScrollTrigger interactions.
author: Diego Villanueva
trigger: When implementing GSAP animations, ScrollTrigger timelines, parallax effects, scroll-bound interactive UI, or smooth scroll integrations.
---

# GSAP & ScrollTrigger Architecture Protocol

You are an expert Motion Engineer specializing in **GSAP (GreenSock Animation Platform)** and **ScrollTrigger**. Your directive is to build smooth (60/120 FPS), memory-safe, responsive, and jaw-dropping scroll interactions that enhance UX without causing layout jank or memory leaks.

---

## 1. Core Engineering & Performance Rules

### A. The GPU Acceleration Mandate
- **❌ NEVER** animate layout properties (`width`, `height`, `top`, `left`, `margin`, `padding`). They trigger costly browser reflows and cause scroll stutter.
- **✅ ALWAYS** animate hardware-accelerated transform and opacity properties (`x`, `y`, `xPercent`, `yPercent`, `scale`, `rotation`, `opacity`, `autoAlpha`).
- **✅ ALWAYS** use `autoAlpha` instead of `opacity`. `autoAlpha` automatically toggles `visibility: hidden` when `opacity: 0`, optimizing browser rendering and accessibility.

```javascript
// ❌ JANKY: Triggers layout recalculation on every scroll frame
gsap.to(".card", { left: "100px", width: "300px" });

// ✅ BUTTERY SMOOTH: Rendered on the GPU compositor thread
gsap.to(".card", { x: 100, scale: 1.1, autoAlpha: 1 });
```

---

## 2. Memory Safety & Framework Lifecycle (`gsap.context()`)

Creating GSAP tweens and ScrollTriggers in single-page applications (React, Angular, Vue, Next.js) without explicit cleanup causes memory leaks, ghost triggers, and duplicate event listeners on route changes.

### A. Universal Cleanup Pattern
**✅ ALWAYS** wrap all GSAP animations inside `gsap.context()`. Releasing the context in the component unmount lifecycle instantly cleans up every tween and ScrollTrigger created within it.

```typescript
// 🟢 React Example (useLayoutEffect / useEffect)
import { useLayoutEffect, useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

export function HeroSection() {
  const containerRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    // Scope all selector queries to containerRef
    const ctx = gsap.context((self) => {
      gsap.from(".hero-title", {
        y: 60,
        autoAlpha: 0,
        duration: 1,
        scrollTrigger: {
          trigger: ".hero-title",
          start: "top 80%",
          end: "top 20%",
          scrub: 1,
        }
      });
    }, containerRef); // Scope parameter

    return () => ctx.revert(); // 🧹 Instantly cleans up all tweens & ScrollTriggers!
  }, []);

  return (
    <div ref={containerRef}>
      <h1 className="hero-title">Elevate Your Vision</h1>
    </div>
  );
}
```

---

## 3. ScrollTrigger Standards & Patterns

### A. `toggleActions` vs `scrub`
- **Use `toggleActions`** when an animation should play discreetly as a scene comes into view.
  - Format: `"onEnter onLeave onEnterBack onLeaveBack"`
  - Standard snap: `"play none none reverse"` or `"play pause resume reset"`
- **Use `scrub`** when the animation's timeline must strictly sync to the user's scrollbar movement.
  - Use numeric scrubbing (`scrub: 1` or `scrub: 0.5`) to add smooth momentum physics instead of a hard `scrub: true`.

```javascript
// Discrete Triggered Animation
gsap.to(".feature-card", {
  y: 0,
  autoAlpha: 1,
  stagger: 0.15,
  scrollTrigger: {
    trigger: ".feature-grid",
    start: "top 75%", // Trigger when top of grid hits 75% of viewport height
    toggleActions: "play none none reverse"
  }
});
```

### B. Pinning & Horizontal Scroll Pattern
To create side-scrolling sections pinned in place:

```javascript
const ctx = gsap.context(() => {
  const sections = gsap.utils.toArray<HTMLElement>(".panel");

  gsap.to(sections, {
    xPercent: -100 * (sections.length - 1),
    ease: "none",
    scrollTrigger: {
      trigger: ".horizontal-wrapper",
      pin: true,
      scrub: 1,
      snap: 1 / (sections.length - 1), // Optional snapping to panel edges
      end: () => "+=" + document.querySelector(".horizontal-wrapper")!.scrollWidth
    }
  });
});
```

---

## 4. Responsive Motion (`gsap.matchMedia()`)

Never run complex desktop pin-and-scroll animations on mobile devices where screen height and touch events cause jumpy viewport shifts.

**✅ ALWAYS** use `gsap.matchMedia()` to construct responsive motion profiles.

```javascript
const mm = gsap.matchMedia();

mm.add("(min-width: 1024px)", () => {
  // 🖥️ Desktop Motion: Pinning & Complex Sequences
  gsap.to(".pinned-graphic", {
    rotation: 360,
    scrollTrigger: {
      trigger: ".pinned-container",
      pin: true,
      scrub: 1
    }
  });
});

mm.add("(max-width: 1023px)", () => {
  // 📱 Mobile Motion: Simplified fade-ins without pinning
  gsap.from(".pinned-graphic", {
    autoAlpha: 0,
    y: 30,
    scrollTrigger: {
      trigger: ".pinned-graphic",
      start: "top 85%"
    }
  });
});

// Cleanup media queries on teardown
// mm.revert();
```

---

## 5. Smooth Scroll Integration (Lenis Integration)

For high-end agency websites, pair ScrollTrigger with **Lenis** for ultra-smooth inertial scrolling.

```javascript
import Lenis from 'lenis';

const lenis = new Lenis({
  duration: 1.2,
  easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
  smoothWheel: true,
});

// Sync Lenis scroll updates with GSAP ScrollTrigger
lenis.on('scroll', ScrollTrigger.update);

gsap.ticker.add((time) => {
  lenis.raf(time * 1000);
});

// Disable lag smoothing to prevent visual stutter during heavy RAF calls
gsap.ticker.lagSmoothing(0);
```

---

## 6. Summary of Banned Practices

- **No `opacity: 0` without `autoAlpha`**: Plain opacity leaves non-visible elements clickable and in the accessibility tree.
- **No manual `window.addEventListener("scroll")`**: Always delegate scroll calculations to ScrollTrigger.
- **No hardcoded offsets without functions**: For dynamic elements, use dynamic getters in ScrollTrigger properties: `end: () => "+=" + element.offsetHeight`.
- **No forgetting `ScrollTrigger.refresh()`**: Call `ScrollTrigger.refresh()` after dynamic content loads or images finish loading to recalculate layout positions.

---
name: lit-animations
description: The definitive standard for implementing animations in Lit using the Web Animations API (WAAPI), CSS transitions in Shadow DOM, and @lit-labs/motion.
author: Diego Villanueva
trigger: When implementing animations in Lit components, using Web Animations API, CSS transitions in Shadow DOM, entrance/exit animations, or @lit-labs/motion animate directive.
---

# Lit Animations Mastery

Lit components run inside Shadow DOM, which requires specific patterns for animations. This skill covers Web Animations API (WAAPI), CSS transitions, staggered entrances, and the `@lit-labs/motion` animate directive.

---

## 1. Web Animations API (WAAPI) in Lit

WAAPI is the standard browser API for programmatic animations — no libraries needed.

```typescript
@customElement('animated-card')
export class AnimatedCard extends LitElement {
  // Entrance animation on first render
  firstUpdated() {
    this.shadowRoot?.querySelector('.card')?.animate(
      [
        { opacity: 0, transform: 'translateY(20px)' },
        { opacity: 1, transform: 'translateY(0)' },
      ],
      {
        duration: 400,
        easing: 'cubic-bezier(0.22, 1.0, 0.36, 1)',
        fill: 'forwards',
      }
    );
  }

  // Triggered animation
  private async _shake() {
    const el = this.shadowRoot?.querySelector('.card');
    await el?.animate(
      [
        { transform: 'translateX(0)' },
        { transform: 'translateX(-8px)' },
        { transform: 'translateX(8px)' },
        { transform: 'translateX(-4px)' },
        { transform: 'translateX(4px)' },
        { transform: 'translateX(0)' },
      ],
      { duration: 400, easing: 'ease-out' }
    ).finished;
  }
}
```

---

## 2. CSS Transitions in Shadow DOM

```typescript
@customElement('collapsible-section')
export class CollapsibleSection extends LitElement {
  static styles = css`
    .content {
      display: grid;
      grid-template-rows: 0fr;
      transition: grid-template-rows 300ms cubic-bezier(0.22, 1.0, 0.36, 1);
      overflow: hidden;
    }

    :host([open]) .content {
      grid-template-rows: 1fr;
    }

    .inner {
      min-block-size: 0;
    }

    .trigger {
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0.75rem 1rem;
    }

    .arrow {
      transition: transform 200ms ease;
    }

    :host([open]) .arrow {
      transform: rotate(180deg);
    }
  `;

  @property({ type: Boolean, reflect: true }) open = false;

  render() {
    return html`
      <div class="trigger" @click=${() => this.open = !this.open}>
        <slot name="title"></slot>
        <span class="arrow">▼</span>
      </div>
      <div class="content">
        <div class="inner">
          <slot></slot>
        </div>
      </div>
    `;
  }
}
```

---

## 3. Staggered Entrance Animations

```typescript
@customElement('stagger-list')
export class StaggerList extends LitElement {
  static styles = css`
    ::slotted(*) {
      opacity: 0;
    }
  `;

  @property({ type: Number }) delay = 75;

  firstUpdated() {
    this._animateEntrance();
  }

  updated() {
    this._animateEntrance();
  }

  private _animateEntrance() {
    const slot = this.shadowRoot?.querySelector('slot');
    const items = slot?.assignedElements() ?? [];

    items.forEach((el, i) => {
      (el as HTMLElement).animate(
        [
          { opacity: 0, transform: 'translateY(16px)' },
          { opacity: 1, transform: 'translateY(0)' },
        ],
        {
          duration: 350,
          delay: i * this.delay,
          easing: 'cubic-bezier(0.22, 1.0, 0.36, 1)',
          fill: 'forwards',
        }
      );
    });
  }

  render() {
    return html`<slot></slot>`;
  }
}
```

```html
<stagger-list delay="100">
  <div class="card">Card 1</div>
  <div class="card">Card 2</div>
  <div class="card">Card 3</div>
</stagger-list>
```

---

## 4. `@lit-labs/motion` — Animate Directive

The animate directive provides automatic FLIP (First, Last, Invert, Play) animations for layout changes:

```typescript
import { LitElement, html, css } from 'lit';
import { customElement, state } from 'lit/decorators.js';
import { animate } from '@lit-labs/motion';
import { repeat } from 'lit/directives/repeat.js';

@customElement('animated-list')
export class AnimatedList extends LitElement {
  @state() items = ['Alpha', 'Beta', 'Gamma', 'Delta'];

  private _shuffle() {
    this.items = [...this.items].sort(() => Math.random() - 0.5);
  }

  render() {
    return html`
      <button @click=${this._shuffle}>Shuffle</button>
      <ul>
        ${repeat(this.items, (item) => item, (item) => html`
          <li ${animate()}>${item}</li>
        `)}
      </ul>
    `;
  }
}
```

### Customizing the Animation

```typescript
import { animate, fadeIn, fadeOut, flyBelow } from '@lit-labs/motion';

render() {
  return html`
    ${repeat(this.items, (i) => i.id, (item) => html`
      <div ${animate({
        keyframeOptions: { duration: 300, easing: 'ease-out' },
        in: fadeIn,
        out: fadeOut,
      })}>
        ${item.name}
      </div>
    `)}
  `;
}
```

---

## 5. Exit Animations

WAAPI animations with promise-based cleanup:

```typescript
async removeItem(index: number) {
  const el = this.shadowRoot?.querySelectorAll('.item')[index];
  if (el) {
    // Animate out, then remove from data
    await el.animate(
      [
        { opacity: 1, transform: 'translateX(0) scale(1)' },
        { opacity: 0, transform: 'translateX(-100px) scale(0.9)' },
      ],
      { duration: 300, easing: 'ease-in', fill: 'forwards' }
    ).finished;
  }
  // Remove from state AFTER animation completes
  this.items = this.items.filter((_, i) => i !== index);
}
```

---

## 6. Accessibility: `prefers-reduced-motion`

```typescript
static styles = css`
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      transition-duration: 0.01ms !important;
    }
  }
`;

// Programmatic check
firstUpdated() {
  const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!prefersReduced) {
    this._animateEntrance();
  }
}
```

---

## 7. Rules

- ✅ **ALWAYS** use `firstUpdated()` for entrance animations (DOM is ready).
- ✅ Use WAAPI `.finished` promise before removing elements (exit animations).
- ✅ Respect `prefers-reduced-motion` — always check and provide fallback.
- ✅ Only animate `transform` and `opacity` for 60fps performance.
- ❌ **NEVER** animate in `render()` — it runs before DOM is painted.
- ❌ **NEVER** animate layout properties (`width`, `height`, `margin`, `padding`).
- ❌ **NEVER** use `will-change` on all elements — only on actively animated ones.

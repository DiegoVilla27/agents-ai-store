---
name: lit-performance
description: The definitive standard for Lit component performance optimization including virtual scrolling, async rendering, bundle splitting, tree-shaking, and rendering efficiency.
author: Diego Villanueva
trigger: When optimizing Lit component performance, implementing virtual scrolling, lazy loading, bundle optimization, or reducing unnecessary re-renders.
---

# Lit Performance Mastery

Lit is already one of the fastest UI libraries (~5KB gzipped, zero VDOM overhead). This skill focuses on scaling performance for enterprise applications with large lists, complex trees, and aggressive bundle budgets.

---

## 1. `@lit-labs/virtualizer` — Virtual Scrolling

For lists with 100+ items, rendering all DOM nodes is wasteful. The virtualizer only renders visible items.

```typescript
import { LitElement, html, css } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import '@lit-labs/virtualizer';

@customElement('virtual-list')
export class VirtualList extends LitElement {
  @property({ type: Array }) items: Item[] = [];

  static styles = css`
    lit-virtualizer {
      block-size: 600px;
      overflow: auto;
    }
    .item {
      padding: 1rem;
      border-bottom: 1px solid var(--color-border);
    }
  `;

  render() {
    return html`
      <lit-virtualizer
        .items=${this.items}
        .renderItem=${(item: Item) => html`
          <div class="item">
            <strong>${item.name}</strong>
            <p>${item.description}</p>
          </div>
        `}
      ></lit-virtualizer>
    `;
  }
}
```

### Grid Layout

```typescript
import { grid } from '@lit-labs/virtualizer/layouts/grid.js';

render() {
  return html`
    <lit-virtualizer
      .items=${this.products}
      .renderItem=${(product: Product) => html`
        <product-card .data=${product}></product-card>
      `}
      .layout=${grid({ itemSize: { width: '300px', height: '400px' }, gap: '16px' })}
    ></lit-virtualizer>
  `;
}
```

---

## 2. Lazy Loading Components

```typescript
// Lazy-load heavy components
@customElement('app-dashboard')
export class AppDashboard extends LitElement {
  @state() private _chartLoaded = false;

  private async _loadChart() {
    await import('./heavy-chart-component.js');
    this._chartLoaded = true;
  }

  firstUpdated() {
    // Load heavy component only when needed
    if (this.hasAttribute('show-chart')) {
      this._loadChart();
    }
  }

  render() {
    return html`
      <div class="stats">
        ${this._chartLoaded
          ? html`<heavy-chart .data=${this.chartData}></heavy-chart>`
          : html`<div class="chart-skeleton"></div>`
        }
      </div>
    `;
  }
}
```

### Intersection Observer Lazy Loading

```typescript
@customElement('lazy-component')
export class LazyComponent extends LitElement {
  @state() private _loaded = false;
  private _observer?: IntersectionObserver;

  connectedCallback() {
    super.connectedCallback();
    this._observer = new IntersectionObserver(async ([entry]) => {
      if (entry.isIntersecting && !this._loaded) {
        await import('./heavy-widget.js');
        this._loaded = true;
        this._observer?.disconnect();
      }
    }, { rootMargin: '200px' }); // Pre-load 200px before viewport
    this._observer.observe(this);
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    this._observer?.disconnect();
  }

  render() {
    return this._loaded
      ? html`<heavy-widget></heavy-widget>`
      : html`<div class="placeholder">Loading...</div>`;
  }
}
```

---

## 3. Avoiding Unnecessary Re-renders

### A. `guard` Directive

```typescript
import { guard } from 'lit/directives/guard.js';

render() {
  return html`
    <!-- Only re-renders when this.items reference changes -->
    ${guard([this.items], () => html`
      ${this.items.map(item => html`<item-card .data=${item}></item-card>`)}
    `)}
  `;
}
```

### B. Custom `hasChanged`

```typescript
@property({
  hasChanged: (newVal: User[], oldVal: User[]) => {
    if (newVal.length !== oldVal?.length) return true;
    return newVal.some((u, i) => u.id !== oldVal[i]?.id);
  }
})
users: User[] = [];
```

### C. `nothing` vs Empty String

```typescript
// ✅ nothing removes the DOM node entirely (cheaper)
render() {
  return html`${this.showBanner ? html`<app-banner></app-banner>` : nothing}`;
}

// ❌ Empty string leaves a text node in the DOM
render() {
  return html`${this.showBanner ? html`<app-banner></app-banner>` : ''}`;
}
```

---

## 4. CSS Containment

```css
:host {
  contain: content;        /* Layout + paint + style containment */
}

/* For elements with known size */
:host {
  contain: strict;         /* All containment + size containment */
  content-visibility: auto; /* Skip rendering when off-screen */
  contain-intrinsic-size: 200px; /* Estimated size for layout */
}
```

---

## 5. Bundle Optimization

### A. Tree-Shaking Imports

```typescript
// ✅ Import only what you need
import { LitElement, html, css, nothing } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import { repeat } from 'lit/directives/repeat.js';

// ❌ NEVER import the entire library
import * as lit from 'lit';
```

### B. Code Splitting Entry Points

```typescript
// routes.ts — Each route lazy-loads its components
const routes = [
  {
    path: '/',
    enter: () => import('./pages/home-page.js'),
    render: () => html`<home-page></home-page>`,
  },
  {
    path: '/admin',
    enter: () => import('./pages/admin-page.js'),
    render: () => html`<admin-page></admin-page>`,
  },
];
```

### C. Shared Dependency Deduplication

```json
// package.json — Ensure single Lit instance
{
  "dependencies": {
    "lit": "^3.0.0"
  },
  "overrides": {
    "lit": "$lit"
  }
}
```

---

## 6. Batch DOM Reads/Writes

```typescript
updated() {
  // ✅ Batch reads first, then writes
  const rect = this.getBoundingClientRect();
  const scrollHeight = this.scrollHeight;

  // Then write
  this.style.setProperty('--content-height', `${scrollHeight}px`);
}
```

---

## 7. Rules

- ✅ Use `@lit-labs/virtualizer` for lists > 100 items.
- ✅ Lazy-load heavy components via dynamic `import()`.
- ✅ Use `contain: content` on `:host` for render isolation.
- ✅ Use `nothing` instead of empty strings for conditional content removal.
- ✅ Import specific modules, not barrel exports.
- ❌ **NEVER** create DOM nodes in `render()` via `document.createElement()`.
- ❌ **NEVER** use `requestAnimationFrame` loops for rendering — let Lit batch updates.
- ❌ **NEVER** read layout properties (offsetHeight, getBoundingClientRect) in `render()`.

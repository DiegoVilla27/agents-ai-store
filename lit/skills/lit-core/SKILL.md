---
name: lit-core
description: The definitive architectural standard for Lit 3+ fundamentals including LitElement, tagged templates, reactive properties, decorators, lifecycle hooks, and the reactive update cycle.
author: Diego Villanueva
trigger: When creating Lit components, defining reactive properties, using html/css/svg tagged templates, managing component lifecycle, or working with the reactive update cycle.
---

# Lit Core Architecture (Lit 3+)

You are an expert Web Components Architect specializing in **Lit 3+**. Lit is a tiny, fast, and standards-based library for building Web Components. Your directive is to build blazing-fast, standards-compliant custom elements that leverage the full power of the Web Components platform — Shadow DOM, custom element registry, and CSS encapsulation — with Lit's surgical reactivity system.

---

## 1. LitElement — The Foundation

Every Lit component extends `LitElement`, which handles Shadow DOM creation, reactive property observation, and efficient batched rendering.

```typescript
import { LitElement, html, css } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';

@customElement('my-counter')
export class MyCounter extends LitElement {
  static styles = css`
    :host {
      display: block;
      font-family: system-ui, sans-serif;
    }
    button {
      padding: 0.5rem 1rem;
      border: none;
      border-radius: 0.5rem;
      background: var(--color-primary, hsl(220 90% 56%));
      color: white;
      cursor: pointer;
      font-weight: 600;
    }
    button:hover {
      filter: brightness(1.1);
    }
    .count {
      font-size: 2rem;
      font-weight: 700;
      margin-block: 0.5rem;
    }
  `;

  @property({ type: Number }) count = 0;

  render() {
    return html`
      <div class="count">${this.count}</div>
      <button @click=${this._increment}>+1</button>
    `;
  }

  private _increment() {
    this.count++;
  }
}
```

### Rules
- ✅ **ALWAYS** use `@customElement('tag-name')` decorator for class registration.
- ✅ **ALWAYS** include a hyphen in the tag name (Web Components spec requirement): `my-card`, `app-header`.
- ❌ **NEVER** call `customElements.define()` manually when using the decorator.
- ❌ **NEVER** use single-word tag names (`counter`, `header`) — they conflict with HTML native elements.

---

## 2. Tagged Template Literals

### A. `html` — Declarative Templates

```typescript
import { html, nothing } from 'lit';

render() {
  return html`
    <h1>${this.title}</h1>
    <p>${this.description || nothing}</p>

    <!-- Event binding with @ prefix -->
    <button @click=${this._handleClick}>Action</button>

    <!-- Boolean attribute binding with ? prefix -->
    <input ?disabled=${this.isLoading}>

    <!-- Property binding with . prefix -->
    <my-child .data=${this.items}></my-child>

    <!-- Attribute binding (default, no prefix) -->
    <div id=${this.elementId} class=${this.cssClass}></div>
  `;
}
```

### B. Binding Prefixes

| Prefix | Type | Example | Use Case |
|--------|------|---------|----------|
| None | Attribute | `id=${val}` | String attributes |
| `.` | Property | `.data=${obj}` | Objects, arrays, complex data |
| `?` | Boolean Attribute | `?disabled=${bool}` | Presence/absence attributes |
| `@` | Event Listener | `@click=${fn}` | DOM event handlers |

### C. `css` — Scoped Styles

```typescript
import { css } from 'lit';

static styles = css`
  :host {
    display: block;
    contain: content;
  }

  :host([hidden]) {
    display: none;
  }
`;
```

### Rules
- ✅ **ALWAYS** use `nothing` (imported from `lit`) instead of empty strings or `undefined` to remove attributes/content cleanly.
- ❌ **NEVER** use string concatenation for templates: `` html`<div class="${'my-' + name}">` ``. Use template expressions.
- ❌ **NEVER** return `null` or `undefined` from `render()`. Return `nothing` or `html```.

---

## 3. Reactive Properties

### A. `@property()` — Public API (Reflected to Attributes)

```typescript
import { property } from 'lit/decorators.js';

// String property (default type)
@property() name = '';

// Typed property with attribute reflection
@property({ type: Number, reflect: true }) count = 0;

// Boolean property
@property({ type: Boolean, reflect: true }) disabled = false;

// Object/Array — NEVER reflected (use .property binding from parent)
@property({ type: Object }) config: Config = {};
@property({ type: Array }) items: Item[] = [];

// Custom attribute name
@property({ attribute: 'card-type' }) cardType = 'default';

// Disable attribute observation
@property({ attribute: false }) complexData: Map<string, any> = new Map();
```

### B. `@state()` — Private Internal State

```typescript
import { state } from 'lit/decorators.js';

// Internal state — NOT exposed as attribute, NOT reflected
@state() private _isOpen = false;
@state() private _selectedIndex = -1;
@state() private _computedValue = '';
```

### C. Custom `hasChanged`

```typescript
@property({
  type: Object,
  hasChanged: (newVal: User, oldVal: User) => {
    return newVal?.id !== oldVal?.id || newVal?.name !== oldVal?.name;
  }
})
user: User = { id: '', name: '' };
```

### D. Custom Attribute Converter

```typescript
@property({
  converter: {
    fromAttribute: (value: string | null) => value ? new Date(value) : null,
    toAttribute: (value: Date | null) => value?.toISOString() ?? null,
  },
  reflect: true,
})
deadline: Date | null = null;
```

### Rules
- ✅ Use `@property()` for the component's public API (data in).
- ✅ Use `@state()` for internal UI state (not observable from outside).
- ✅ Use `reflect: true` ONLY for simple primitive types (string, number, boolean) that need to appear in the DOM for CSS selectors or accessibility.
- ❌ **NEVER** reflect Objects or Arrays — serialization to attributes is expensive and lossy.
- ❌ **NEVER** mutate arrays/objects in place. Replace them: `this.items = [...this.items, newItem]`.

---

## 4. Reactive Update Cycle (Lifecycle)

Lit batches property changes and performs a single asynchronous update. Understanding the cycle is critical.

```text
Property Change
  → requestUpdate()
  → shouldUpdate(changedProperties)    // Return false to skip update
  → willUpdate(changedProperties)      // Compute derived state HERE
  → update(changedProperties)          // Renders template (DO NOT OVERRIDE)
  → render()                           // Returns template
  → firstUpdated(changedProperties)    // Runs ONCE after first render
  → updated(changedProperties)         // Runs after every render
  → updateComplete (Promise)           // Resolves when update is done
```

```typescript
export class MyComponent extends LitElement {
  @property({ type: String }) userId = '';
  @state() private _userData: User | null = null;

  // ✅ Compute derived state BEFORE rendering
  willUpdate(changedProperties: PropertyValues) {
    if (changedProperties.has('userId') && this.userId) {
      // Trigger async data fetch
      this._loadUser(this.userId);
    }
  }

  // ✅ Runs ONCE after first render — DOM is available
  firstUpdated() {
    this.shadowRoot?.querySelector('input')?.focus();
  }

  // ✅ Runs after EVERY render — DOM has been updated
  updated(changedProperties: PropertyValues) {
    if (changedProperties.has('count')) {
      this.dispatchEvent(new CustomEvent('count-changed', {
        detail: { count: this.count },
        bubbles: true,
        composed: true,
      }));
    }
  }

  // ✅ Wait for rendering to complete
  async performAction() {
    this.items = [...this.items, newItem];
    await this.updateComplete;
    // DOM is now updated, safe to query
    const lastItem = this.shadowRoot?.querySelector('.item:last-child');
    lastItem?.scrollIntoView({ behavior: 'smooth' });
  }
}
```

### Rules
- ✅ Use `willUpdate()` for computing derived state — it runs before `render()`.
- ✅ Use `firstUpdated()` for one-time DOM setup (focus, third-party library init).
- ✅ Use `updated()` for post-render side effects (dispatching events, measuring DOM).
- ✅ Use `await this.updateComplete` before querying DOM after a state change.
- ❌ **NEVER** set reactive properties in `render()` — it causes infinite loops.
- ❌ **NEVER** override `update()` unless you are deeply customizing the rendering pipeline.

---

## 5. DOM Queries

```typescript
import { query, queryAll, queryAsync } from 'lit/decorators.js';

export class MyForm extends LitElement {
  // Single element query (cached after first access)
  @query('#username') _usernameInput!: HTMLInputElement;

  // All matching elements
  @queryAll('.field') _fields!: NodeListOf<HTMLElement>;

  // Async query — resolves after updateComplete
  @queryAsync('#dynamic-content') _dynamicContent!: Promise<HTMLElement>;

  async submit() {
    const username = this._usernameInput.value;
    // ...
  }
}
```

---

## 6. Custom Events (Communication Out)

```typescript
// ✅ ALWAYS: Use composed: true to cross Shadow DOM boundaries
private _dispatchSelection(item: Item) {
  this.dispatchEvent(new CustomEvent('item-selected', {
    detail: { item },
    bubbles: true,    // Propagates up the DOM tree
    composed: true,   // Crosses Shadow DOM boundaries
  }));
}
```

```html
<!-- Parent consuming the event -->
<my-list @item-selected=${this._onItemSelected}></my-list>
```

### Rules
- ✅ **ALWAYS** set `bubbles: true` and `composed: true` for events that parents need to capture.
- ✅ Name events with `kebab-case` verbs: `item-selected`, `form-submitted`, `dialog-closed`.
- ❌ **NEVER** use `composed: false` if the event needs to be heard outside the Shadow DOM.

---

## 7. Summary of Banned Practices

- `document.createElement()` + manual DOM manipulation inside Lit components (Use `render()` templates).
- `innerHTML` for rendering content (Use `html` tagged template).
- Mutating arrays/objects in place (`this.items.push()`) — Replace with spread or new reference.
- Setting reactive properties inside `render()` (Infinite loop).
- Single-word custom element names (`<counter>`, `<modal>`).
- `customElements.define()` when using `@customElement` decorator.
- Reflecting complex types (Object, Array) to attributes.

---
name: lit-components-shadow-dom
description: The definitive standard for Shadow DOM encapsulation, slot composition, CSS scoping, part-based styling, and light DOM rendering patterns in Lit.
author: Diego Villanueva
trigger: When working with Shadow DOM, slots, CSS encapsulation, ::slotted, :host, ::part, component composition, or light DOM rendering in Lit.
---

# Shadow DOM & Component Composition Mastery

You are an expert in Web Components encapsulation. Your directive is to leverage Shadow DOM for true CSS and DOM isolation while mastering slot-based composition, part-based theming, and advanced component architecture patterns.

---

## 1. Shadow DOM Fundamentals

Lit creates an open Shadow DOM by default for every component. This provides:
- **DOM Encapsulation**: Internal DOM is invisible to parent queries (`document.querySelector` won't find shadow children).
- **CSS Scoping**: Styles defined in `static styles` are completely isolated — they don't leak out and external styles don't leak in.
- **Event Retargeting**: Events originating from shadow children are retargeted to the host element.

```typescript
@customElement('my-card')
export class MyCard extends LitElement {
  static styles = css`
    /* These styles ONLY apply inside this Shadow DOM */
    h2 { color: var(--card-title-color, hsl(220 90% 56%)); }
    p  { color: var(--card-text-color, hsl(215 16% 47%)); }
  `;

  @property() heading = '';

  render() {
    return html`
      <h2>${this.heading}</h2>
      <p><slot></slot></p>
    `;
  }
}
```

---

## 2. Slots — Content Projection

Slots allow consumers to project content into your component's shadow DOM.

### A. Default Slot

```typescript
render() {
  return html`
    <div class="card-body">
      <slot></slot>  <!-- Projects all unnamed slotted content -->
    </div>
  `;
}
```

```html
<my-card>
  <p>This paragraph is projected into the default slot.</p>
</my-card>
```

### B. Named Slots

```typescript
render() {
  return html`
    <header>
      <slot name="header"></slot>
    </header>
    <main>
      <slot></slot>  <!-- Default slot for body content -->
    </main>
    <footer>
      <slot name="footer"></slot>
    </footer>
  `;
}
```

```html
<my-layout>
  <h1 slot="header">Dashboard</h1>
  <p>Main content goes here (default slot)</p>
  <nav slot="footer">Footer navigation</nav>
</my-layout>
```

### C. Slot Fallback Content

```typescript
render() {
  return html`
    <slot name="icon">
      <!-- Fallback shown when no content is slotted -->
      <svg viewBox="0 0 24 24"><path d="M12 2L2 22h20L12 2z"/></svg>
    </slot>
  `;
}
```

### D. Slot Change Detection

```typescript
render() {
  return html`
    <slot @slotchange=${this._onSlotChange}></slot>
  `;
}

private _onSlotChange(e: Event) {
  const slot = e.target as HTMLSlotElement;
  const assignedElements = slot.assignedElements({ flatten: true });
  console.log('Slotted elements:', assignedElements.length);
}
```

---

## 3. `:host` — Styling the Host Element

`:host` targets the custom element itself (the outer tag).

```css
/* Default host styles */
:host {
  display: block;
  contain: content;
  border: 1px solid var(--color-border, hsl(214 32% 91%));
  border-radius: 0.75rem;
  padding: 1.5rem;
}

/* Host with specific attribute */
:host([variant="primary"]) {
  background: var(--color-primary);
  color: white;
}

/* Host with boolean attribute */
:host([disabled]) {
  opacity: 0.5;
  pointer-events: none;
}

/* Hidden host */
:host([hidden]) {
  display: none;
}

/* Host in a specific parent context */
:host-context(.dark-theme) {
  background: hsl(220 25% 12%);
  color: hsl(210 40% 96%);
}
```

### Rules
- ✅ **ALWAYS** set `display` on `:host` — custom elements are `display: inline` by default, which breaks layout.
- ✅ **ALWAYS** handle `:host([hidden])` to respect the `hidden` attribute.
- ✅ Use `contain: content` on `:host` for performance isolation.

---

## 4. `::slotted()` — Styling Projected Content

`::slotted()` styles elements projected into a slot. It only targets **direct children** of the slot, not deeper descendants.

```css
/* Style all slotted content */
::slotted(*) {
  margin-block: 0.5rem;
}

/* Style specific slotted elements */
::slotted(h1) {
  font-size: 1.5rem;
  font-weight: 700;
}

::slotted([slot="footer"]) {
  border-top: 1px solid var(--color-border);
  padding-top: 1rem;
}

/* Slotted images */
::slotted(img) {
  max-inline-size: 100%;
  border-radius: 0.5rem;
}
```

### Limitation
- ❌ `::slotted()` can only select **direct children** of the slot, not nested elements.
- ❌ You cannot combine `::slotted()` with descendant selectors: `::slotted(div span)` is invalid.

---

## 5. `::part()` — Exposing Styleable Parts

`part` exposes internal shadow DOM elements for external styling — a controlled escape hatch.

### Component Definition

```typescript
@customElement('fancy-button')
export class FancyButton extends LitElement {
  static styles = css`
    button {
      padding: 0.5rem 1rem;
      border: none;
      border-radius: 0.5rem;
      cursor: pointer;
    }
    .icon {
      margin-inline-end: 0.5rem;
    }
  `;

  render() {
    return html`
      <button part="base">
        <span part="icon" class="icon"><slot name="icon"></slot></span>
        <span part="label"><slot></slot></span>
      </button>
    `;
  }
}
```

### Consumer Styling

```css
/* External CSS can now target exposed parts */
fancy-button::part(base) {
  background: linear-gradient(135deg, hsl(260 80% 60%), hsl(200 90% 50%));
  color: white;
  font-weight: 600;
}

fancy-button::part(base):hover {
  filter: brightness(1.1);
}

fancy-button::part(icon) {
  font-size: 1.25rem;
}
```

### Rules
- ✅ Use `part` for intentional public styling API — document which parts are available.
- ❌ **NEVER** expose every element as a part — it defeats encapsulation.
- ❌ Parts do NOT cross nested shadow boundaries (no `exportparts` in Lit by default).

---

## 6. Light DOM Rendering

For rare cases where Shadow DOM encapsulation is not desired (e.g., CMS integration, global CSS frameworks):

```typescript
@customElement('my-unshadowed')
export class MyUnshadowed extends LitElement {
  // Override createRenderRoot to render into light DOM
  createRenderRoot() {
    return this;  // Renders directly into the host element
  }

  render() {
    return html`
      <div class="card">
        <h2>${this.title}</h2>
        <p>${this.description}</p>
      </div>
    `;
  }
}
```

### Rules
- ⚠️ Light DOM rendering loses CSS encapsulation — styles leak in and out.
- ✅ Only use for components that MUST integrate with global CSS (Bootstrap, legacy systems).
- ❌ **NEVER** use light DOM rendering as the default — Shadow DOM is the standard.

---

## 7. Composition Patterns

### A. Wrapper Component (Slot-Based)

```typescript
@customElement('app-dialog')
export class AppDialog extends LitElement {
  @property({ type: Boolean, reflect: true }) open = false;

  render() {
    return html`
      <div class="overlay" @click=${this._close}>
        <div class="dialog" @click=${(e: Event) => e.stopPropagation()}>
          <header><slot name="title"></slot></header>
          <main><slot></slot></main>
          <footer><slot name="actions"></slot></footer>
        </div>
      </div>
    `;
  }

  private _close() {
    this.open = false;
    this.dispatchEvent(new CustomEvent('dialog-closed', { bubbles: true, composed: true }));
  }
}
```

### B. Nested Components

```typescript
@customElement('user-card')
export class UserCard extends LitElement {
  @property({ type: Object }) user: User = { name: '', role: '' };

  render() {
    return html`
      <app-avatar .src=${this.user.avatar}></app-avatar>
      <app-badge .label=${this.user.role}></app-badge>
      <h3>${this.user.name}</h3>
    `;
  }
}
```

---

## 8. Summary of Banned Practices

- Forgetting `display: block` on `:host` (Custom elements default to `inline`).
- Using `::slotted()` with descendant selectors (Only direct children work).
- Exposing all internal elements via `part` (Use sparingly as public API).
- Defaulting to light DOM rendering (Shadow DOM is the standard).
- Forgetting `composed: true` on events that need to cross shadow boundaries.
- Using `this.shadowRoot!.innerHTML` instead of `render()` templates.

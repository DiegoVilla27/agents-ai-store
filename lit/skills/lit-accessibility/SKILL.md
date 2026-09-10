---
name: lit-accessibility
description: The definitive standard for building accessible Lit web components with ARIA, focus management, keyboard navigation, and screen reader compatibility.
author: Diego Villanueva
trigger: When implementing accessibility in Lit components, using ARIA roles, managing focus, building keyboard navigation, or ensuring screen reader compatibility in web components.
---

# Lit Accessibility Mastery

Web Components have unique accessibility challenges: Shadow DOM boundaries affect focus behavior, ARIA relationships, and label associations. This skill ensures every Lit component is fully WCAG-compliant and usable by everyone.

---

## 1. ARIA Roles & Properties

### A. Implicit Roles via ElementInternals

```typescript
@customElement('app-button')
export class AppButton extends LitElement {
  private _internals = this.attachInternals();

  constructor() {
    super();
    this._internals.role = 'button';
  }

  @property({ type: Boolean, reflect: true }) disabled = false;

  updated(changed: PropertyValues) {
    if (changed.has('disabled')) {
      this._internals.ariaDisabled = String(this.disabled);
    }
  }
}
```

### B. ARIA on Host Element

```typescript
@customElement('app-tabs')
export class AppTabs extends LitElement {
  static styles = css`
    :host { display: block; }
    [role="tablist"] { display: flex; gap: 0; }
    [role="tab"] {
      padding: 0.75rem 1.25rem;
      cursor: pointer;
      border: none;
      background: transparent;
    }
    [role="tab"][aria-selected="true"] {
      border-bottom: 2px solid var(--color-primary);
      font-weight: 600;
    }
  `;

  @property({ type: Number }) activeIndex = 0;
  @property({ type: Array }) tabs: string[] = [];

  render() {
    return html`
      <div role="tablist" aria-label="Content tabs">
        ${this.tabs.map((tab, i) => html`
          <button
            role="tab"
            id="tab-${i}"
            aria-selected=${i === this.activeIndex}
            aria-controls="panel-${i}"
            tabindex=${i === this.activeIndex ? 0 : -1}
            @click=${() => this._selectTab(i)}
            @keydown=${this._onKeydown}
          >${tab}</button>
        `)}
      </div>
      <div
        role="tabpanel"
        id="panel-${this.activeIndex}"
        aria-labelledby="tab-${this.activeIndex}"
      >
        <slot name="panel-${this.activeIndex}"></slot>
      </div>
    `;
  }

  private _selectTab(index: number) {
    this.activeIndex = index;
  }

  private _onKeydown(e: KeyboardEvent) {
    let newIndex = this.activeIndex;
    if (e.key === 'ArrowRight') newIndex = (this.activeIndex + 1) % this.tabs.length;
    if (e.key === 'ArrowLeft') newIndex = (this.activeIndex - 1 + this.tabs.length) % this.tabs.length;
    if (e.key === 'Home') newIndex = 0;
    if (e.key === 'End') newIndex = this.tabs.length - 1;

    if (newIndex !== this.activeIndex) {
      e.preventDefault();
      this._selectTab(newIndex);
      // Focus the new tab
      this.shadowRoot?.querySelectorAll('[role="tab"]')[newIndex]
        ?.dispatchEvent(new Event('focus'));
      (this.shadowRoot?.querySelectorAll('[role="tab"]')[newIndex] as HTMLElement)?.focus();
    }
  }
}
```

---

## 2. Focus Management

### A. `delegatesFocus`

When `delegatesFocus` is true, clicking anywhere on the host automatically delegates focus to the first focusable element inside the Shadow DOM:

```typescript
@customElement('focus-input')
export class FocusInput extends LitElement {
  static shadowRootOptions = {
    ...LitElement.shadowRootOptions,
    delegatesFocus: true,  // ✅ Auto-delegate focus to inner input
  };

  render() {
    return html`<input type="text" placeholder="Type here..." />`;
  }
}
```

### B. Focus Trapping (Modals/Dialogs)

```typescript
@customElement('app-modal')
export class AppModal extends LitElement {
  @property({ type: Boolean, reflect: true }) open = false;
  private _previousFocus: HTMLElement | null = null;

  updated(changed: PropertyValues) {
    if (changed.has('open')) {
      if (this.open) {
        this._previousFocus = document.activeElement as HTMLElement;
        // Focus first focusable element in modal
        requestAnimationFrame(() => {
          const focusable = this.shadowRoot?.querySelector<HTMLElement>(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
          );
          focusable?.focus();
        });
      } else {
        // Restore focus to trigger element
        this._previousFocus?.focus();
      }
    }
  }

  private _onKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape') {
      this.open = false;
      return;
    }

    if (e.key !== 'Tab') return;

    const focusableElements = this.shadowRoot?.querySelectorAll<HTMLElement>(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );

    if (!focusableElements?.length) return;

    const first = focusableElements[0];
    const last = focusableElements[focusableElements.length - 1];

    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  }

  render() {
    if (!this.open) return nothing;

    return html`
      <div
        class="overlay"
        role="dialog"
        aria-modal="true"
        aria-labelledby="dialog-title"
        @keydown=${this._onKeydown}
      >
        <div class="dialog">
          <h2 id="dialog-title"><slot name="title"></slot></h2>
          <div class="content"><slot></slot></div>
          <footer>
            <slot name="actions">
              <button @click=${() => this.open = false}>Close</button>
            </slot>
          </footer>
        </div>
      </div>
    `;
  }
}
```

---

## 3. Keyboard Navigation Patterns

| Component | Key | Action |
|-----------|-----|--------|
| Tabs | `Arrow Right/Left` | Switch active tab |
| Menu | `Arrow Down/Up` | Navigate items |
| Dialog | `Escape` | Close dialog |
| Dropdown | `Enter/Space` | Open/select |
| Tree | `Arrow Right` | Expand node |
| Listbox | `Home/End` | First/last item |

---

## 4. Live Regions

```typescript
@customElement('toast-container')
export class ToastContainer extends LitElement {
  @state() private _message = '';

  showToast(message: string) {
    this._message = message;
    setTimeout(() => { this._message = ''; }, 5000);
  }

  render() {
    return html`
      <div role="status" aria-live="polite" aria-atomic="true">
        ${this._message ? html`<div class="toast">${this._message}</div>` : nothing}
      </div>
    `;
  }
}
```

| Attribute | Value | When |
|-----------|-------|------|
| `aria-live` | `polite` | Non-urgent updates (toast, status) |
| `aria-live` | `assertive` | Urgent alerts (errors, warnings) |
| `aria-atomic` | `true` | Announce entire region content |

---

## 5. Accessible Form Labels

```typescript
// Shadow DOM prevents <label for="id"> from crossing boundaries
// Solution 1: Use aria-labelledby with slotted content
render() {
  return html`
    <div>
      <slot name="label" id="label-slot"></slot>
      <input aria-labelledby="label-slot" />
    </div>
  `;
}

// Solution 2: Use ElementInternals
constructor() {
  super();
  this._internals = this.attachInternals();
  this._internals.ariaLabel = this.label;
}
```

---

## 6. Color & Contrast

```css
/* Focus indicators — WCAG 2.4.7 */
:host(:focus-visible) {
  outline: 2px solid var(--color-focus-ring, hsl(220 90% 56%));
  outline-offset: 2px;
}

/* Ensure contrast meets WCAG AA (4.5:1 for text) */
button {
  color: white;                          /* Contrast against --color-primary */
  background: var(--color-primary);      /* Must meet 4.5:1 ratio */
}
```

---

## 7. Rules

- ✅ **ALWAYS** add `role`, `aria-label`, and keyboard handlers to interactive custom elements.
- ✅ Use `delegatesFocus: true` for input wrapper components.
- ✅ Trap focus inside modals/dialogs and restore on close.
- ✅ Support `Escape` key to close overlays.
- ✅ Use `aria-live` for dynamic content updates (toasts, notifications).
- ❌ **NEVER** remove focus outlines without providing a visible alternative.
- ❌ **NEVER** use `tabindex > 0` — it disrupts natural tab order.
- ❌ **NEVER** use ARIA roles that conflict with the native element semantics.

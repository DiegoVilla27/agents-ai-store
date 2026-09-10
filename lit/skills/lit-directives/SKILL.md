---
name: lit-directives
description: The definitive reference for all Lit built-in directives and custom directive creation for advanced template rendering patterns.
author: Diego Villanueva
trigger: When using Lit directives like repeat, classMap, styleMap, when, choose, guard, cache, ref, until, or creating custom directives.
---

# Lit Directives Mastery

Directives are functions that customize how Lit renders expressions in templates. They hook into Lit's rendering pipeline for advanced control over DOM updates.

---

## 1. Rendering Directives

### A. `repeat` — Keyed List Rendering

```typescript
import { repeat } from 'lit/directives/repeat.js';

render() {
  return html`
    <ul>
      ${repeat(
        this.items,
        (item) => item.id,  // Key function (like React's key)
        (item, index) => html`
          <li>${index + 1}. ${item.name}</li>
        `
      )}
    </ul>
  `;
}
```

**When to use**: Use `repeat` when list items are reordered, inserted, or removed and you need efficient DOM recycling via keys. For simple static lists, `map()` is sufficient.

### B. `map` — Simple Iteration

```typescript
import { map } from 'lit/directives/map.js';

render() {
  return html`
    <ul>${map(this.items, (item) => html`<li>${item.name}</li>`)}</ul>
  `;
}
```

### C. `join` — Separator Between Items

```typescript
import { join } from 'lit/directives/join.js';

render() {
  return html`
    <nav>${join(this.breadcrumbs.map(b => html`<a href=${b.url}>${b.label}</a>`), ' / ')}</nav>
  `;
}
```

### D. `range` — Number Sequences

```typescript
import { range } from 'lit/directives/range.js';
import { map } from 'lit/directives/map.js';

render() {
  return html`
    <div class="pagination">
      ${map(range(this.totalPages), (i) => html`
        <button ?disabled=${i === this.currentPage} @click=${() => this._goToPage(i)}>
          ${i + 1}
        </button>
      `)}
    </div>
  `;
}
```

---

## 2. Conditional Directives

### A. `when` — Ternary Rendering

```typescript
import { when } from 'lit/directives/when.js';

render() {
  return html`
    ${when(this.isLoggedIn,
      () => html`<user-dashboard></user-dashboard>`,
      () => html`<login-form></login-form>`
    )}
  `;
}
```

### B. `choose` — Switch/Case Rendering

```typescript
import { choose } from 'lit/directives/choose.js';

render() {
  return html`
    ${choose(this.status, [
      ['loading', () => html`<app-spinner></app-spinner>`],
      ['error',   () => html`<error-banner .message=${this.error}></error-banner>`],
      ['empty',   () => html`<empty-state></empty-state>`],
      ['success', () => html`<data-table .rows=${this.data}></data-table>`],
    ], () => html`<p>Unknown status</p>`)}
  `;
}
```

---

## 3. Styling Directives

### A. `classMap` — Conditional CSS Classes

```typescript
import { classMap } from 'lit/directives/class-map.js';

render() {
  const classes = {
    'card': true,
    'card--active': this.isActive,
    'card--disabled': this.disabled,
    'card--featured': this.featured,
  };

  return html`<div class=${classMap(classes)}><slot></slot></div>`;
}
```

### B. `styleMap` — Dynamic Inline Styles

```typescript
import { styleMap } from 'lit/directives/style-map.js';

render() {
  const styles = {
    width: `${this.progress}%`,
    backgroundColor: this.progress >= 100 ? 'var(--color-success)' : 'var(--color-primary)',
    transition: 'width 300ms ease',
  };

  return html`<div class="bar" style=${styleMap(styles)}></div>`;
}
```

---

## 4. Performance Directives

### A. `guard` — Skip Re-rendering

Only re-renders the template when the guarded values change:

```typescript
import { guard } from 'lit/directives/guard.js';

render() {
  return html`
    ${guard([this.items], () => html`
      <heavy-list .data=${this.items}></heavy-list>
    `)}
  `;
}
```

### B. `cache` — Preserve DOM Between Switches

Caches the DOM for each branch so switching doesn't destroy and recreate elements:

```typescript
import { cache } from 'lit/directives/cache.js';

render() {
  return html`
    ${cache(this.activeTab === 'settings'
      ? html`<settings-panel></settings-panel>`
      : html`<profile-panel></profile-panel>`
    )}
  `;
}
```

### C. `keyed` — Force Re-creation

Forces a complete teardown and re-creation of the template when the key changes:

```typescript
import { keyed } from 'lit/directives/keyed.js';

render() {
  return html`
    ${keyed(this.userId, html`<user-profile .id=${this.userId}></user-profile>`)}
  `;
}
```

---

## 5. DOM Directives

### A. `ref` — Direct DOM Reference

```typescript
import { ref, createRef, Ref } from 'lit/directives/ref.js';

export class MyForm extends LitElement {
  inputRef: Ref<HTMLInputElement> = createRef();

  render() {
    return html`
      <input ${ref(this.inputRef)} type="text" />
      <button @click=${this._focus}>Focus</button>
    `;
  }

  private _focus() {
    this.inputRef.value?.focus();
  }
}
```

### B. `live` — Force Attribute Sync

Forces Lit to always set the property/attribute, even if the value hasn't changed in Lit's tracking. Essential for inputs where the DOM value can diverge from Lit's tracked value:

```typescript
import { live } from 'lit/directives/live.js';

render() {
  return html`
    <input .value=${live(this.inputValue)} @input=${this._onInput}>
  `;
}
```

---

## 6. Async Directives

### A. `until` — Placeholder While Loading

```typescript
import { until } from 'lit/directives/until.js';

render() {
  return html`
    <div>
      ${until(
        this._fetchUser().then(user => html`<p>${user.name}</p>`),
        html`<app-spinner></app-spinner>`  // Shown until promise resolves
      )}
    </div>
  `;
}
```

### B. `asyncAppend` / `asyncReplace`

```typescript
import { asyncAppend } from 'lit/directives/async-append.js';
import { asyncReplace } from 'lit/directives/async-replace.js';

// asyncReplace: Replaces content with each new value from an async iterable
render() {
  return html`<div>${asyncReplace(this._streamData())}</div>`;
}

// asyncAppend: Appends each new value from an async iterable
render() {
  return html`<ul>${asyncAppend(this._logStream(), (msg) => html`<li>${msg}</li>`)}</ul>`;
}
```

---

## 7. Safety Directives

### A. `ifDefined` — Remove Attribute When Undefined

```typescript
import { ifDefined } from 'lit/directives/if-defined.js';

render() {
  return html`
    <a href=${ifDefined(this.url)}>Link</a>
    <img src=${this.src} alt=${ifDefined(this.alt)}>
  `;
}
```

### B. `unsafeHTML` / `unsafeSVG` — Raw Markup (⚠️ Use With Caution)

```typescript
import { unsafeHTML } from 'lit/directives/unsafe-html.js';

render() {
  // ⚠️ ONLY use with sanitized/trusted content (e.g., from a CMS after DOMPurify)
  return html`<div class="markdown-body">${unsafeHTML(this.sanitizedHtml)}</div>`;
}
```

- ❌ **NEVER** pass user input directly to `unsafeHTML` — XSS vulnerability.
- ✅ **ALWAYS** sanitize with DOMPurify before using `unsafeHTML`.

---

## 8. Custom Directives

```typescript
import { Directive, directive, PartInfo, PartType } from 'lit/directive.js';
import { noChange } from 'lit';

class TooltipDirective extends Directive {
  private _tooltip: HTMLElement | null = null;

  constructor(partInfo: PartInfo) {
    super(partInfo);
    if (partInfo.type !== PartType.ELEMENT) {
      throw new Error('tooltip directive must be used on an element');
    }
  }

  update(part: any, [text]: [string]) {
    if (!this._tooltip) {
      const el = part.element as HTMLElement;
      el.setAttribute('aria-label', text);
      el.style.position = 'relative';
    }
    return this.render(text);
  }

  render(text: string) {
    return noChange;  // We don't modify the template output
  }
}

export const tooltip = directive(TooltipDirective);

// Usage
html`<button ${tooltip('Click to save')}>💾</button>`;
```

---

## 9. Summary

| Directive | Import | Purpose |
|-----------|--------|---------|
| `repeat` | `lit/directives/repeat.js` | Keyed list rendering |
| `map` | `lit/directives/map.js` | Simple iteration |
| `join` | `lit/directives/join.js` | Separator between items |
| `range` | `lit/directives/range.js` | Number sequences |
| `when` | `lit/directives/when.js` | Conditional (ternary) |
| `choose` | `lit/directives/choose.js` | Multi-branch (switch) |
| `classMap` | `lit/directives/class-map.js` | Conditional classes |
| `styleMap` | `lit/directives/style-map.js` | Dynamic inline styles |
| `guard` | `lit/directives/guard.js` | Skip re-renders |
| `cache` | `lit/directives/cache.js` | Preserve DOM |
| `keyed` | `lit/directives/keyed.js` | Force re-creation |
| `ref` | `lit/directives/ref.js` | DOM references |
| `live` | `lit/directives/live.js` | Force DOM sync |
| `until` | `lit/directives/until.js` | Async placeholder |
| `ifDefined` | `lit/directives/if-defined.js` | Remove undefined attrs |
| `unsafeHTML` | `lit/directives/unsafe-html.js` | Raw HTML (sanitized) |

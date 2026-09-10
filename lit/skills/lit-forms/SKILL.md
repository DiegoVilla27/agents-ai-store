---
name: lit-forms
description: The definitive standard for form-associated custom elements, ElementInternals, custom validation, and form participation in Lit.
author: Diego Villanueva
trigger: When building form controls with Lit, implementing form-associated custom elements, using ElementInternals, or creating custom form validation.
---

# Lit Forms & ElementInternals Mastery

Form-associated custom elements allow Lit components to participate natively in HTML `<form>` elements — supporting `FormData`, validation, reset, restore, and disabled states — just like native `<input>`, `<select>`, and `<textarea>`.

---

## 1. Form-Associated Custom Element

```typescript
import { LitElement, html, css } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';

@customElement('fancy-input')
export class FancyInput extends LitElement {
  // ═══ CRITICAL: Declares this element participates in forms ═══
  static formAssociated = true;

  private _internals: ElementInternals;

  @property() name = '';
  @property() label = '';
  @property({ type: Boolean }) required = false;
  @state() private _value = '';
  @state() private _touched = false;

  constructor() {
    super();
    this._internals = this.attachInternals();
  }

  static styles = css`
    :host { display: block; }
    :host([invalid]) input { border-color: var(--color-danger, red); }
    label { display: block; font-weight: 600; margin-block-end: 0.25rem; }
    input {
      inline-size: 100%;
      padding: 0.5rem 0.75rem;
      border: 1px solid var(--color-border, #ccc);
      border-radius: 0.5rem;
      font-size: 1rem;
    }
    .error { color: var(--color-danger, red); font-size: 0.875rem; margin-block-start: 0.25rem; }
  `;

  // ═══ Set form value whenever internal state changes ═══
  private _onInput(e: InputEvent) {
    this._value = (e.target as HTMLInputElement).value;
    this._internals.setFormValue(this._value);
    this._validate();
  }

  private _onBlur() {
    this._touched = true;
    this._validate();
  }

  private _validate() {
    if (this.required && !this._value) {
      this._internals.setValidity(
        { valueMissing: true },
        `${this.label || this.name} is required`,
        this.shadowRoot?.querySelector('input') ?? undefined
      );
      this.toggleAttribute('invalid', true);
    } else {
      this._internals.setValidity({});
      this.removeAttribute('invalid');
    }
  }

  // ═══ Form lifecycle callbacks ═══
  formResetCallback() {
    this._value = '';
    this._touched = false;
    this._internals.setFormValue('');
    this._internals.setValidity({});
    this.removeAttribute('invalid');
  }

  formDisabledCallback(disabled: boolean) {
    this.toggleAttribute('disabled', disabled);
  }

  formStateRestoreCallback(state: string) {
    this._value = state;
    this._internals.setFormValue(state);
  }

  render() {
    return html`
      <label for="input">${this.label}</label>
      <input
        id="input"
        .value=${this._value}
        @input=${this._onInput}
        @blur=${this._onBlur}
        ?required=${this.required}
        ?disabled=${this.hasAttribute('disabled')}
      >
      ${this._touched && this._internals.validity.valueMissing
        ? html`<p class="error">${this._internals.validationMessage}</p>`
        : ''}
    `;
  }
}
```

### Usage in a Form

```html
<form id="profile-form">
  <fancy-input name="username" label="Username" required></fancy-input>
  <fancy-input name="email" label="Email"></fancy-input>
  <button type="submit">Submit</button>
  <button type="reset">Reset</button>
</form>

<script>
  document.querySelector('#profile-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const form = e.target;

    // ✅ checkValidity() works with form-associated custom elements!
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }

    // ✅ FormData automatically includes custom element values!
    const data = new FormData(form);
    console.log('username:', data.get('username'));
    console.log('email:', data.get('email'));
  });
</script>
```

---

## 2. ElementInternals API

| Method | Purpose |
|--------|---------|
| `setFormValue(value)` | Set the value submitted with the form |
| `setValidity(flags, message?, anchor?)` | Set validation state |
| `reportValidity()` | Show validation UI |
| `checkValidity()` | Check without showing UI |
| `validity` | Access `ValidityState` object |
| `validationMessage` | Get current validation message |
| `form` | Reference to the parent `<form>` |
| `labels` | Associated `<label>` elements |

### Validity Flags

```typescript
this._internals.setValidity({
  valueMissing: true,     // Required field is empty
  typeMismatch: true,     // Type doesn't match (email, url)
  patternMismatch: true,  // Doesn't match pattern regex
  tooLong: true,          // Exceeds maxlength
  tooShort: true,         // Below minlength
  rangeUnderflow: true,   // Below min value
  rangeOverflow: true,    // Above max value
  stepMismatch: true,     // Doesn't match step
  customError: true,      // Custom validation error
}, 'Error message here', anchorElement);
```

---

## 3. Complex Form Controls

### A. Multi-Value (Select/Checkbox Group)

```typescript
@customElement('fancy-select')
export class FancySelect extends LitElement {
  static formAssociated = true;
  private _internals = this.attachInternals();

  @property() name = '';
  @property({ type: Array }) options: string[] = [];
  @state() private _selected = '';

  private _onSelect(value: string) {
    this._selected = value;
    this._internals.setFormValue(value);
  }

  render() {
    return html`
      <div class="options" role="listbox">
        ${this.options.map(opt => html`
          <button
            role="option"
            aria-selected=${this._selected === opt}
            class=${this._selected === opt ? 'selected' : ''}
            @click=${() => this._onSelect(opt)}
          >${opt}</button>
        `)}
      </div>
    `;
  }
}
```

### B. File Upload Custom Element

```typescript
@customElement('fancy-upload')
export class FancyUpload extends LitElement {
  static formAssociated = true;
  private _internals = this.attachInternals();

  @property() name = '';
  @state() private _file: File | null = null;

  private _onFileChange(e: Event) {
    const input = e.target as HTMLInputElement;
    this._file = input.files?.[0] ?? null;
    if (this._file) {
      this._internals.setFormValue(this._file);
    }
  }

  formResetCallback() {
    this._file = null;
    this._internals.setFormValue(null);
  }

  render() {
    return html`
      <label class="upload-area">
        <input type="file" @change=${this._onFileChange} hidden>
        ${this._file
          ? html`<span>📄 ${this._file.name}</span>`
          : html`<span>📁 Click to upload</span>`
        }
      </label>
    `;
  }
}
```

---

## 4. ARIA via ElementInternals

ElementInternals can set ARIA properties without polluting the DOM with attributes:

```typescript
constructor() {
  super();
  this._internals = this.attachInternals();
  this._internals.role = 'textbox';
  this._internals.ariaLabel = 'Username input';
  this._internals.ariaRequired = 'true';
}
```

---

## 5. Rules

- ✅ **ALWAYS** set `static formAssociated = true` for form participation.
- ✅ **ALWAYS** call `setFormValue()` whenever the internal value changes.
- ✅ **ALWAYS** implement `formResetCallback()` to handle `<form>` reset.
- ✅ Pass the anchor element (the input) to `setValidity()` for proper validation UI positioning.
- ❌ **NEVER** forget to call `attachInternals()` in the constructor.
- ❌ **NEVER** try to call `attachInternals()` more than once per element instance.

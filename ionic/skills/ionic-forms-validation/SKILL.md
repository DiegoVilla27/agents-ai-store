---
name: ionic-forms-validation
description: The ultimate architectural standard for Ionic Forms with Angular Reactive Forms, Custom Validation, ion-input/ion-select patterns, and Mobile-First UX.
author: Diego Villanueva
trigger: When building forms with Ionic input components, implementing validation, handling keyboard behavior, or creating multi-step form flows.
---

# Enterprise Ionic Forms & Validation Architecture

Forms in Ionic demand special attention because mobile keyboards, input masking, and touch-optimized validation differ significantly from desktop web forms. You MUST combine Angular Reactive Forms with Ionic's native-feeling input components.

## 1. Reactive Forms with Ionic Components

**❌ NEVER** use template-driven forms (`[(ngModel)]`) in enterprise apps.
**✅ ALWAYS** use Angular Reactive Forms (`FormGroup`, `FormControl`) with Ionic inputs.

```typescript
import { Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import {
  IonHeader, IonToolbar, IonTitle, IonContent,
  IonList, IonItem, IonInput, IonButton, IonNote, IonSelect, IonSelectOption
} from '@ionic/angular/standalone';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    IonHeader, IonToolbar, IonTitle, IonContent,
    IonList, IonItem, IonInput, IonButton, IonNote, IonSelect, IonSelectOption
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ion-header>
      <ion-toolbar>
        <ion-title>Register</ion-title>
      </ion-toolbar>
    </ion-header>
    <ion-content class="ion-padding">
      <form [formGroup]="form" (ngSubmit)="onSubmit()">
        <ion-list>
          <ion-item>
            <ion-input
              formControlName="fullName"
              label="Full Name"
              labelPlacement="floating"
              type="text"
              autocomplete="name"
              [clearInput]="true"
              errorText="Name is required (min 2 characters)"
            />
          </ion-item>

          <ion-item>
            <ion-input
              formControlName="email"
              label="Email"
              labelPlacement="floating"
              type="email"
              autocomplete="email"
              inputmode="email"
              errorText="Please enter a valid email"
            />
          </ion-item>

          <ion-item>
            <ion-input
              formControlName="phone"
              label="Phone"
              labelPlacement="floating"
              type="tel"
              inputmode="tel"
              autocomplete="tel"
              errorText="Please enter a valid phone number"
            />
          </ion-item>

          <ion-item>
            <ion-select
              formControlName="country"
              label="Country"
              labelPlacement="floating"
              interface="action-sheet"
            >
              <ion-select-option value="us">United States</ion-select-option>
              <ion-select-option value="mx">Mexico</ion-select-option>
              <ion-select-option value="es">Spain</ion-select-option>
            </ion-select>
          </ion-item>

          <ion-item>
            <ion-input
              formControlName="password"
              label="Password"
              labelPlacement="floating"
              type="password"
              autocomplete="new-password"
              [counter]="true"
              [maxlength]="64"
              errorText="Minimum 8 characters with uppercase, number, and symbol"
            />
          </ion-item>
        </ion-list>

        <ion-button
          expand="block"
          type="submit"
          [disabled]="form.invalid || submitting()"
          class="ion-margin-top"
        >
          @if (submitting()) {
            <ion-spinner name="crescent" />
          } @else {
            Register
          }
        </ion-button>
      </form>
    </ion-content>
  `
})
export class RegisterPage {
  private readonly fb = inject(FormBuilder);
  readonly submitting = signal(false);

  readonly form = this.fb.nonNullable.group({
    fullName: ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]],
    phone: ['', [Validators.required, Validators.pattern(/^\+?[\d\s-]{7,15}$/)]],
    country: ['', Validators.required],
    password: ['', [Validators.required, Validators.minLength(8), this.passwordStrength]],
  });

  private passwordStrength(control: AbstractControl): ValidationErrors | null {
    const value = control.value;
    if (!value) return null;
    const hasUpper = /[A-Z]/.test(value);
    const hasNumber = /\d/.test(value);
    const hasSymbol = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(value);
    return hasUpper && hasNumber && hasSymbol ? null : { passwordStrength: true };
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched(); // Triggers Ionic error messages
      return;
    }
    this.submitting.set(true);
    // Submit logic...
  }
}
```

## 2. Ionic v8 Input Validation Display

Ionic v8+ has built-in error display via the `errorText` property on `ion-input`. The error message appears automatically when the form control is **touched** and **invalid**.

```html
<!-- Ionic v8 auto-validation display -->
<ion-input
  formControlName="email"
  label="Email"
  labelPlacement="floating"
  type="email"
  errorText="Please enter a valid email address"
/>
<!-- No need for manual @if blocks to show/hide error messages! -->
```

For custom/dynamic error messages:

```html
<ion-item>
  <ion-input
    formControlName="username"
    label="Username"
    labelPlacement="floating"
    [errorText]="usernameError()"
  />
</ion-item>
```

```typescript
readonly usernameError = computed(() => {
  const ctrl = this.form.controls.username;
  if (ctrl.hasError('required')) return 'Username is required';
  if (ctrl.hasError('minlength')) return 'Minimum 3 characters';
  if (ctrl.hasError('taken')) return 'Username is already taken';
  return '';
});
```

## 3. Mobile Keyboard Optimization

Mobile keyboards are a major UX concern. ALWAYS set the correct `inputmode` and `type` to trigger the right keyboard layout.

| Data Type | `type` | `inputmode` | Keyboard |
|---|---|---|---|
| Email | `email` | `email` | @ and .com keys |
| Phone | `tel` | `tel` | Numeric dial pad |
| Number | `text` | `decimal` | Numbers with decimal |
| URL | `url` | `url` | .com / .org keys |
| Search | `search` | `search` | Search/Go key |
| Pin Code | `text` | `numeric` | Numeric only |

```html
<!-- ✅ Numeric PIN input with correct mobile keyboard -->
<ion-input
  formControlName="pin"
  label="Verification PIN"
  labelPlacement="floating"
  type="text"
  inputmode="numeric"
  [maxlength]="6"
  pattern="[0-9]*"
  autocomplete="one-time-code"
/>
```

## 4. Multi-Step Form Flow

For complex registration or checkout flows, use a signal-based step system:

```typescript
export class CheckoutPage {
  readonly currentStep = signal(0);
  readonly steps = ['Shipping', 'Payment', 'Review'];

  readonly shippingForm = this.fb.nonNullable.group({ /* ... */ });
  readonly paymentForm = this.fb.nonNullable.group({ /* ... */ });

  nextStep(): void {
    const forms = [this.shippingForm, this.paymentForm];
    const current = forms[this.currentStep()];

    if (current && current.invalid) {
      current.markAllAsTouched();
      return;
    }
    this.currentStep.update(s => Math.min(s + 1, this.steps.length - 1));
  }

  prevStep(): void {
    this.currentStep.update(s => Math.max(s - 1, 0));
  }
}
```

## 5. Ion-Select Patterns

```html
<!-- Action Sheet style (recommended for mobile) -->
<ion-select interface="action-sheet" label="Category" labelPlacement="floating">
  <ion-select-option value="tech">Technology</ion-select-option>
  <ion-select-option value="health">Health</ion-select-option>
</ion-select>

<!-- Alert style (for small lists) -->
<ion-select interface="alert" label="Priority" labelPlacement="floating" [multiple]="true">
  <ion-select-option value="high">High</ion-select-option>
  <ion-select-option value="medium">Medium</ion-select-option>
  <ion-select-option value="low">Low</ion-select-option>
</ion-select>

<!-- Popover style (for desktop/tablet) -->
<ion-select interface="popover" label="Sort By" labelPlacement="floating">
  <ion-select-option value="date">Date</ion-select-option>
  <ion-select-option value="name">Name</ion-select-option>
</ion-select>
```

## 6. Date & Time Inputs

```html
<!-- ion-datetime with modal presentation -->
<ion-datetime
  formControlName="birthDate"
  presentation="date"
  [preferWheel]="true"
  [max]="maxDate"
  [min]="'1920-01-01'"
  [showDefaultButtons]="true"
  doneText="Confirm"
  cancelText="Cancel"
/>
```

---

**Execution Protocol**
1. **Always use Reactive Forms**: Never use `[(ngModel)]` in enterprise Ionic apps.
2. **Always set `inputmode`**: Triggers the correct mobile keyboard layout.
3. **Always use `labelPlacement="floating"`**: Provides the best mobile UX by maximizing input space.
4. **Always call `markAllAsTouched()`**: Before checking validity on submit, so Ionic displays error messages.
5. **Use `ion-select` with `interface="action-sheet"`**: On mobile, it provides the most native-feeling selection experience.

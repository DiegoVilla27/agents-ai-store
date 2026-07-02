---
name: angular-forms
description: The ultimate architectural standard for Enterprise Angular Forms Strongly Typed Reactive Forms, Async Validators, FormArrays, and ControlValueAccessor.
author: Diego Villanueva
trigger: When building forms, validating inputs, handling dynamic fields, or creating custom form controls.
---

# Enterprise Angular Forms Architecture

Forms are the most complex part of any frontend application. If not architected correctly, they become a tangled mess of `(change)` events, two-way bindings, and untestable validation logic.

**THE CORE RULE**: For Enterprise applications, you MUST use **Typed Reactive Forms**. Template-driven forms (`[(ngModel)]`) are strictly limited to trivial, single-input scenarios (like a standalone search bar).

## 1. Strictly Typed Reactive Forms (Angular 14+)

In older versions of Angular, `form.value` returned `any`. In modern Angular, forms are strictly typed.

**❌ NEVER** use `UntypedFormBuilder` or `UntypedFormGroup`.
**✅ ALWAYS** define the exact interface of your form and use `NonNullableFormBuilder` to prevent variables from unexpectedly becoming `null` when `.reset()` is called.

```typescript
// ✅ ALWAYS: Use strictly typed forms with NonNullableFormBuilder
import { Component, inject } from '@angular/core';
import { FormBuilder, FormGroup, FormControl, Validators, ReactiveFormsModule } from '@angular/forms';

// 1. Define the Form Interface
interface UserForm {
  email: FormControl<string>;
  age: FormControl<number>;
  newsletter: FormControl<boolean>;
}

@Component({
  selector: 'app-user-form',
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <input formControlName="email" type="email" />
      @if (form.controls.email.invalid && form.controls.email.touched) {
        <span class="error">Valid email is required</span>
      }
      <button type="submit" [disabled]="form.invalid">Submit</button>
    </form>
  `
})
export class UserFormComponent {
  // Use NonNullableFormBuilder (usually injected via FormBuilder in strict mode)
  private readonly fb = inject(FormBuilder).nonNullable;

  // 2. Build the Form
  readonly form: FormGroup<UserForm> = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    age: [18, [Validators.required, Validators.min(18)]],
    newsletter: [false] // Automatically inferred as FormControl<boolean>
  });

  onSubmit() {
    if (this.form.valid) {
      // form.getRawValue() includes disabled fields, form.value does not.
      // the result is 100% type-safe!
      const data = this.form.getRawValue(); 
      console.log(data.email); 
    }
  }
}
```

## 2. Advanced Validation Strategies

### A. Cross-Field Validation (FormGroup level)
If you need to check if `password` matches `confirmPassword`, you CANNOT put the validator on the individual control. You MUST attach it to the `FormGroup`.

```typescript
// ✅ ALWAYS: Attach cross-field validators to the parent FormGroup
const passwordMatchValidator: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
  const password = control.get('password')?.value;
  const confirm = control.get('confirmPassword')?.value;
  return password === confirm ? null : { passwordMismatch: true };
};

this.form = this.fb.group({
  password: ['', Validators.required],
  confirmPassword: ['', Validators.required]
}, { validators: passwordMatchValidator }); // <--- Applied to the group
```

### B. Async Validators (API checks)
When checking if an email is already taken, you must query the database.
**CRITICAL RULE**: You MUST use `timer()` to debounce the request, otherwise you will DDOS your own server on every keystroke.

```typescript
// ✅ ALWAYS: Debounce async validators using RxJS timer
emailTakenValidator(api: ApiService): AsyncValidatorFn {
  return (control: AbstractControl): Observable<ValidationErrors | null> => {
    if (!control.value) return of(null);
    
    // Wait 500ms after the user stops typing
    return timer(500).pipe(
      switchMap(() => api.checkEmailExists(control.value)),
      map(exists => (exists ? { emailTaken: true } : null)),
      catchError(() => of(null)) // Never crash the form if the API fails
    );
  };
}
```

## 3. Dynamic Forms (`FormArray`)

When you need a dynamic list of inputs (e.g., "Add multiple phone numbers"), you MUST use `FormArray`.

```typescript
// ✅ ALWAYS: Use FormArray for dynamic lists
interface CompanyForm {
  name: FormControl<string>;
  branches: FormArray<FormGroup<{ city: FormControl<string> }>>;
}

this.form = this.fb.group<CompanyForm>({
  name: this.fb.control(''),
  branches: this.fb.array([
    this.fb.group({ city: this.fb.control('New York') })
  ])
});

// Adding a new branch dynamically
addBranch() {
  this.form.controls.branches.push(this.fb.group({ city: this.fb.control('') }));
}
```

## 4. Custom Form Components (`ControlValueAccessor`)

If you build a custom UI component (e.g., a fancy `StarRatingComponent`), and you want to use it inside a form like `<app-star-rating formControlName="rating">`, you MUST implement the `ControlValueAccessor` (CVA) interface.

**❌ NEVER** pass `FormGroup` instances directly into child components as `@Input()`. It tightly couples the child to the parent's specific form structure. The child should only care about its own value.

```typescript
// ✅ ALWAYS: Implement CVA for reusable form inputs
import { Component, forwardRef } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

@Component({
  selector: 'app-star-rating',
  standalone: true,
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => StarRatingComponent),
    multi: true
  }],
  template: `
    <div (click)="setRating(5)">⭐⭐⭐⭐⭐ (Current: {{ rating }})</div>
  `
})
export class StarRatingComponent implements ControlValueAccessor {
  rating = 0;
  private onChange: (value: number) => void = () => {};
  private onTouched: () => void = () => {};

  // 1. Angular tells the component to update its internal value
  writeValue(value: number): void {
    this.rating = value || 0;
  }

  // 2. Component tells Angular that the user changed the value
  registerOnChange(fn: any): void {
    this.onChange = fn;
  }

  // 3. Component tells Angular that the user interacted with it
  registerOnTouched(fn: any): void {
    this.onTouched = fn;
  }

  setRating(val: number) {
    this.rating = val;
    this.onChange(val); // Notifies the parent FormGroup!
    this.onTouched();
  }
}
```

## 5. Integrating Forms with Signals

Instead of manually subscribing to `form.valueChanges` and dealing with memory leaks, you should convert the Observable into a Signal.

```typescript
// ✅ ALWAYS: Convert valueChanges to Signals for reactive UI updates
export class SearchComponent {
  private readonly fb = inject(FormBuilder);
  readonly searchControl = this.fb.control('');

  // Automatically unsubscribes, perfectly reactive
  readonly searchValue = toSignal(this.searchControl.valueChanges, { initialValue: '' });

  readonly results = computed(() => {
    // Only runs when searchValue changes
    return this.api.search(this.searchValue()); 
  });
}
```

---

**Execution Protocol**
1. **`updateValueAndValidity()`**: If you dynamically add or remove a validator using `setValidators()`, you MUST call `control.updateValueAndValidity()` for Angular to re-evaluate the form state.
2. **`markAllAsTouched()`**: Before submitting a form, always call `this.form.markAllAsTouched()`. This ensures that all validation error messages instantly appear on the screen, even if the user didn't click inside those specific fields.
3. **Avoid `valueChanges` infinite loops**: If you subscribe to `valueChanges` and call `patchValue()` inside the subscription, you will cause an infinite loop. Always pass `{ emitEvent: false }` to `patchValue` if you don't want it to trigger the subscription again.
---
name: angular-signals
description: The ultimate architectural standard for Enterprise Angular Signals signal(), computed(), linkedSignal(), effect(), Signal Inputs/Outputs/Models, and RxJS Interoperability.
author: Diego Villanueva
trigger: When managing state, creating inputs/outputs, computing derived data, using linkedSignal, or replacing BehaviorSubjects.
---

# Enterprise Angular Signals Architecture (v18 & v19+)

Angular Signals are the foundation of modern, highly performant, "Zoneless" Angular. They replace `BehaviorSubject` for synchronous state and replace all legacy decorators (`@Input`, `@Output`, `@ViewChild`, `@ContentChild`).

A Signal is a wrapper around a value that notifies interested consumers when that value changes with fine-grained reactivity.

---

## 1. Writable Signals (`signal`)

Use a Writable Signal to hold any primitive or object state that the component needs to modify.

**❌ NEVER** use `BehaviorSubject` for local synchronous state.
**✅ ALWAYS** use `signal()`.

```typescript
import { Component, signal } from '@angular/core';

export class CounterComponent {
  // ✅ ALWAYS: Initialize with a default value
  readonly count = signal(0);
  readonly user = signal({ id: 1, name: 'Diego' });

  increment() {
    // .update() computes new state from previous value
    this.count.update(c => c + 1); 
  }

  reset() {
    // .set() overwrites the value entirely
    this.count.set(0); 
  }
}
```

---

## 2. Derived State (`computed`)

If you have a Signal for `items` and a Signal for `filter`, you should NOT create a third Writable Signal for `filteredItems` and manually update it.

**✅ ALWAYS** use `computed()` to derive state.
`computed()` is **Lazy and Memoized**. It only recalculates if one of its dependencies changes AND it is actually being read in the template.

```typescript
export class CartComponent {
  readonly items = signal([{ price: 10 }, { price: 20 }]);
  readonly taxRate = signal(0.15);

  // Re-calculates ONLY when `items` or `taxRate` change.
  readonly totalPrice = computed(() => {
    const subtotal = this.items().reduce((acc, item) => acc + item.price, 0);
    return subtotal + (subtotal * this.taxRate());
  });
}
```

---

## 3. Resettable & Dependent Writable State (`linkedSignal` - Angular 19+)

Historically, synchronizing a writable state with a changing input or source signal required ugly `effect()` hacks or manual `ngOnChanges`. 

Angular 19 introduced `linkedSignal()`. A `linkedSignal` is a **writable** signal whose value automatically recomputes or resets whenever its source signal changes, but can also be manually overwritten by user interaction.

```typescript
import { Component, input, linkedSignal } from '@angular/core';

export class ShippingOptionSelectorComponent {
  // Source Signal Input from parent
  readonly availableOptions = input.required<string[]>();

  // ✅ ALWAYS: Use linkedSignal() for writable state linked to a source signal
  // Automatically defaults to availableOptions()[0] whenever the parent list changes,
  // but can be independently modified when the user clicks a radio button!
  readonly selectedOption = linkedSignal(() => this.availableOptions()[0]);

  // Advanced: linkedSignal with explicit source and computation
  readonly quantity = linkedSignal({
    source: () => this.availableOptions(),
    computation: (options, prev) => {
      // Reset quantity to 1 if available options change
      return 1;
    },
  });

  selectOption(opt: string) {
    this.selectedOption.set(opt); // Directly writable!
  }
}
```

---

## 4. Side Effects (`effect`, `untracked` & `onCleanup`)

An `effect` is a function that runs whenever one of the Signals inside it changes.

**❌ NEVER** use `effect()` to update the value of another Signal (causes cycles and performance hits). Use `computed()` or `linkedSignal()`.
**✅ ALWAYS** use `effect()` exclusively for side-effects: Syncing with `localStorage`, logging, updating non-Angular DOM canvas/charts, or hardware APIs.

```typescript
import { effect, untracked } from '@angular/core';

export class ThemeComponent {
  readonly theme = signal('dark');
  readonly currentUser = signal('Diego');

  constructor() {
    effect((onCleanup) => {
      const activeTheme = this.theme();
      const user = untracked(this.currentUser); // Read WITHOUT creating a dependency
      
      console.log(`User ${user} switched theme to ${activeTheme}`);
      document.body.className = activeTheme;

      // Register cleanup handler (runs before next effect run or on component destroy)
      onCleanup(() => {
        console.log(`Cleaning up previous theme: ${activeTheme}`);
      });
    });
  }
}
```

---

## 5. Signal-Based Component API (Inputs, Outputs & Models)

Angular eliminates `@Input`, `@Output`, and `@ViewChild` decorators entirely.

```typescript
import { Component, input, output, model, viewChild, viewChildren, ElementRef } from '@angular/core';

@Component({
  selector: 'app-user-card',
  standalone: true,
  template: `
    <h2 #headerEl>{{ title() }}</h2>
    <p>Age: {{ age() }}</p>
    <button (click)="onDelete()">Delete</button>
  `
})
export class UserCardComponent {
  // Inputs
  readonly title = input<string>('Default');
  readonly age = input.required<number>();

  // Outputs
  readonly delete = output<void>();

  // Two-Way Binding Model ([()="..."])
  readonly isActive = model<boolean>(false);

  // View Queries
  readonly header = viewChild<ElementRef<HTMLElement>>('headerEl');

  onDelete() {
    this.delete.emit();
    this.isActive.set(true); // Modifying model() automatically emits change event
  }
}
```

---

## 6. RxJS Interoperability

Convert RxJS Observables into Signals at the component boundary:

```typescript
import { toSignal, toObservable } from '@angular/core/rxjs-interop';

export class WeatherComponent {
  private readonly http = inject(HttpClient);
  readonly searchInput = signal('Madrid');

  // Convert Signal -> Observable (to leverage debounceTime / switchMap)
  readonly search$ = toObservable(this.searchInput).pipe(
    debounceTime(300),
    switchMap(city => this.http.get(`/api/weather?q=${city}`))
  );

  // Convert Observable -> Signal for template rendering
  readonly weather = toSignal(this.search$, { initialValue: null });
}
```

---

**Execution Protocol**
1. **Never use `effect()` to synchronize state**: Use `computed()` or `linkedSignal()`.
2. **Object Equality**: By default, `signal()` uses strict reference equality (`===`). Pass custom `{ equal: (a, b) => a.id === b.id }` when needed.
3. **No `async` pipe needed**: With Signals, consume values directly in templates: `{{ data() }}`.
4. **Use `untracked()`**: When reading a Signal inside an `effect` or `computed` without subscribing to changes.

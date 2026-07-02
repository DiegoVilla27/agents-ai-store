---
name: angular-signals
description: The ultimate architectural standard for Enterprise Angular Signals signal(), computed(), effect(), Signal Inputs/Outputs, and RxJS Interoperability.
author: Diego Villanueva
trigger: When managing state, creating inputs/outputs, computing derived data, or replacing BehaviorSubjects.
---

# Enterprise Angular Signals Architecture

Angular Signals are the foundation of modern, highly performant, "Zoneless" Angular. They replace `BehaviorSubject` for synchronous state and replace all legacy decorators (`@Input`, `@Output`, `@ViewChild`).

A Signal is a wrapper around a value that notifies interested consumers when that value changes.

## 1. Writable Signals (`signal`)

Use a Writable Signal to hold any primitive or object state that the component needs to modify.

**❌ NEVER** use `BehaviorSubject` for simple local state.
**✅ ALWAYS** use `signal()`.

```typescript
import { Component, signal } from '@angular/core';

export class CounterComponent {
  // ✅ ALWAYS: Initialize with a default value
  readonly count = signal(0);
  readonly user = signal({ id: 1, name: 'Diego' });

  increment() {
    // .update() passes the current value
    this.count.update(c => c + 1); 
  }

  reset() {
    // .set() overwrites the value entirely
    this.count.set(0); 
  }
}
```

## 2. Derived State (`computed`)

If you have a Signal for `items` and a Signal for `filter`, you should NOT create a third Writable Signal for `filteredItems` and manually update it.

**✅ ALWAYS** use `computed()` to derive state.
`computed()` is **Lazy and Memoized**. It only recalculates if one of its dependencies changes AND it is actually being read in the template.

```typescript
export class CartComponent {
  readonly items = signal([{ price: 10 }, { price: 20 }]);
  readonly taxRate = signal(0.15);

  // Re-calculates ONLY when `items` or `taxRate` change.
  // If `items` changes but the template doesn't read `totalPrice`, it won't calculate!
  readonly totalPrice = computed(() => {
    const subtotal = this.items().reduce((acc, item) => acc + item.price, 0);
    return subtotal + (subtotal * this.taxRate());
  });
}
```

## 3. Side Effects (`effect` & `untracked`)

An `effect` is a function that runs whenever one of the Signals inside it changes.

**❌ NEVER** use `effect()` to update the value of another Signal. This leads to infinite loops and spaghetti code. If you need a Signal based on another Signal, use `computed()`.
**✅ ALWAYS** use `effect()` exclusively for side-effects: Syncing with `localStorage`, logging, updating a non-Angular charting library, or modifying the DOM directly (Canvas).

```typescript
import { effect, untracked } from '@angular/core';

export class ThemeComponent {
  readonly theme = signal('dark');
  readonly currentUser = signal('Diego');

  constructor() {
    effect(() => {
      // Runs whenever `theme` changes.
      // We use untracked() to read `currentUser` WITHOUT subscribing to it.
      // If `currentUser` changes, this effect WILL NOT re-run.
      const user = untracked(this.currentUser);
      console.log(`User ${user} changed theme to ${this.theme()}`);
      
      document.body.className = this.theme(); // Valid Side Effect!
    });
  }
}
```

## 4. Signal-Based Components API (The Death of Decorators)

Angular 17.1+ introduced Signal-based alternatives for all major component decorators.

**❌ NEVER** use `@Input`, `@Output`, or `@ViewChild` in new code.
**✅ ALWAYS** use `input()`, `output()`, and `viewChild()`.

### A. Inputs & Outputs
```typescript
import { Component, input, output, model } from '@angular/core';

@Component({
  selector: 'app-user-card',
  template: `
    <h2>{{ title() }}</h2>
    <p>Age: {{ age() }}</p>
    <button (click)="onDelete()">Delete</button>
  `
})
export class UserCardComponent {
  // Replaces @Input() title = 'Default';
  readonly title = input<string>('Default');
  
  // Replaces @Input({ required: true }) age!: number;
  readonly age = input.required<number>();
  
  // Replaces @Output() delete = new EventEmitter<void>();
  readonly delete = output<void>();

  // Replaces @Input() value + @Output() valueChange (Two-Way Binding)
  readonly isActive = model<boolean>(false); 

  onDelete() {
    this.delete.emit();
    this.isActive.set(true); // Modifying a model() emits the change automatically
  }
}
```

### B. View Queries
```typescript
import { Component, viewChild, ElementRef, viewChildren } from '@angular/core';

export class SearchComponent {
  // Replaces @ViewChild('searchInput')
  // Automatically updates if the element appears/disappears due to @if
  readonly inputEl = viewChild<ElementRef<HTMLInputElement>>('searchInput');
  
  // Replaces @ViewChildren
  readonly listItems = viewChildren(ListItemComponent);
  
  focus() {
    this.inputEl()?.nativeElement.focus();
  }
}
```

## 5. RxJS Interoperability

Signals and RxJS serve different purposes. Signals are for **Synchronous State** (what is happening right now). RxJS is for **Asynchronous Streams** (events over time, debounce, WebSockets).

**✅ ALWAYS** convert RxJS Observables into Signals at the component boundary so the template can remain purely Signal-driven.

```typescript
import { toSignal, toObservable } from '@angular/core/rxjs-interop';

export class WeatherComponent {
  private readonly http = inject(HttpClient);
  readonly searchInput = signal('Madrid');

  // Convert Signal -> Observable (to use RxJS operators like debounceTime)
  readonly search$ = toObservable(this.searchInput).pipe(
    debounceTime(300),
    switchMap(city => this.http.get(`/api/weather?q=${city}`))
  );

  // Convert Observable -> Signal (for the template)
  // Subscribes automatically, Unsubscribes automatically!
  readonly weather = toSignal(this.search$, { initialValue: null });
}
```

---

**Execution Protocol**
1. **Object Equality**: By default, `signal()` uses strict equality (`===`). If you do `user.set({ name: 'Diego' })`, and then do `user.set({ name: 'Diego' })` again, Angular will consider them *different* objects and trigger a re-render. If you want custom equality, you can pass `{ equal: (a, b) => a.id === b.id }` when creating the signal.
2. **Effects are asynchronous**: `effect()` runs during the change detection cycle, not synchronously the moment the signal is updated.
3. **No `async` pipe**: With Signals, you never need the `| async` pipe in your templates again. Just call the signal `{{ data() }}`.

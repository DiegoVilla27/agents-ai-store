---
name: angular-core
description: The ultimate architectural standard for Angular Core (v17+) Signals, inject(), New Control Flow (@if/@for), Signal Inputs, and Zoneless Performance.
author: Diego Villanueva
trigger: When writing Angular components, managing state with Signals, passing data (Inputs/Outputs), or injecting dependencies.
---

# Enterprise Angular Core Architecture (v17+)

Angular has undergone a complete renaissance. The patterns you learned in Angular 12 (Constructors, `@Input`, `*ngIf`, `Zone.js`) are now considered **legacy**.

To write modern, ultra-performant Angular code, you MUST adhere to the following paradigms.

## 1. Dependency Injection (`inject()` Function)

Historically, dependencies were injected via the `constructor`. This created massive boilerplate and made class inheritance (`extends BaseComponent`) a nightmare because you had to pass all dependencies via `super()`.

**❌ NEVER** use constructor injection for Services, Tokens, or routing.
**✅ ALWAYS** use the `inject()` function. It is cleaner, type-safe, and makes inheritance trivial.

```typescript
// ❌ ATROCIOUS: Legacy Constructor Injection
export class UserProfileComponent {
  constructor(
    private userService: UserService,
    private router: Router,
    @Inject(DOCUMENT) private document: Document
  ) {}
}

// ✅ ALWAYS: Modern inject() function
export class UserProfileComponent {
  private readonly userService = inject(UserService);
  private readonly router = inject(Router);
  private readonly document = inject(DOCUMENT);
}
```

## 2. Signal Inputs & Outputs (The End of Decorators)

Decorators like `@Input()` and `@Output()` are legacy. They do not trigger fine-grained reactive updates, and they force you to use `ngOnChanges` (which is a massive performance killer).

Angular 17+ introduced Signal Inputs. They are strictly typed, reactive by default, and allow you to use `computed()` instead of `ngOnChanges`.

```typescript
import { Component, input, output, model, computed } from '@angular/core';

@Component({
  selector: 'app-product-card',
  standalone: true,
  template: `
    <div [class.disabled]="isDisabled()">
      <h2>{{ product().name }} ({{ taxPrice() | currency }})</h2>
      
      <!-- Two-way binding with model() -->
      <input type="number" [(ngModel)]="quantity" />
      
      <button (click)="onBuy()">Buy</button>
    </div>
  `
})
export class ProductCardComponent {
  // ✅ ALWAYS: Use Signal Inputs
  readonly product = input.required<Product>(); // Throws error if parent forgets to pass it
  readonly isDisabled = input(false); // Default value, optional
  
  // ✅ ALWAYS: Use computed() instead of ngOnChanges
  readonly taxPrice = computed(() => this.product().price * 1.21);

  // ✅ ALWAYS: Use Signal Outputs
  readonly purchase = output<number>();

  // ✅ ALWAYS: Use model() for two-way binding ([()="..."])
  readonly quantity = model(1);

  onBuy() {
    this.purchase.emit(this.product().id);
  }
}
```

## 3. The Signal State Machine

Signals are the new reactive primitive. Unlike RxJS `BehaviorSubject`, Signals are synchronously available and integrate perfectly with the Angular rendering engine.

- `signal()`: Writable state (`set`, `update`).
- `computed()`: Derived state (Memoized, only recalculates if dependencies change).
- `effect()`: Side effects.

**CRITICAL RULE**: Do NOT use `effect()` to update other signals! This causes infinite loops and destroys performance. `effect()` is ONLY for touching the DOM manually, drawing to a Canvas, or saving to `localStorage`.

```typescript
export class CartService {
  // 1. Writable Signals
  readonly items = signal<CartItem[]>([]);
  readonly discountCode = signal<string | null>(null);

  // 2. Computed Signals (Automatically updates when items or discountCode change)
  readonly total = computed(() => {
    const sum = this.items().reduce((acc, item) => acc + item.price, 0);
    return this.discountCode() === 'SAVE20' ? sum * 0.8 : sum;
  });

  constructor() {
    // 3. Side effects (Runs once initially, and then whenever 'total' changes)
    effect(() => {
      console.log(`The new cart total is: ${this.total()}`);
      localStorage.setItem('CART', JSON.stringify(this.items()));
    });
  }

  addItem(item: CartItem) {
    // ✅ ALWAYS: Use update() when relying on previous state
    this.items.update(current => [...current, item]);
  }
}
```

## 4. Modern Control Flow (`@if`, `@for`)

The old structural directives (`*ngIf`, `*ngFor`, `*ngSwitch`) are slow because they rely on the Angular template compiler parsing micro-syntax. 
Angular 17 introduced built-in Control Flow. It is up to 90% faster.

```html
<!-- ❌ ATROCIOUS: Legacy syntax -->
<div *ngIf="isLoaded; else loading">
  <div *ngFor="let user of users; trackBy: trackById">
    {{ user.name }}
  </div>
</div>
<ng-template #loading>Loading...</ng-template>

<!-- ✅ ALWAYS: Modern Control Flow -->
@if (isLoaded()) {
  <!-- The track property is MANDATORY in modern Angular -->
  @for (user of users(); track user.id) {
    <div>{{ user.name }}</div>
  } @empty {
    <div>No users found.</div>
  }
} @else {
  <div>Loading...</div>
}
```

## 5. Memory Leaks (`takeUntilDestroyed`)

If you must use RxJS (e.g., listening to `HttpClient` or `valueChanges` on a form), you MUST unsubscribe, or the app will leak memory.

Forget implementing `OnDestroy`. Use `takeUntilDestroyed()`.

```typescript
export class SearchComponent {
  private readonly searchControl = new FormControl('');
  private readonly destroyRef = inject(DestroyRef); // Native Angular cleanup

  constructor() {
    this.searchControl.valueChanges.pipe(
      debounceTime(300),
      takeUntilDestroyed(this.destroyRef) // ✅ ALWAYS: Auto-unsubscribes when component dies
    ).subscribe(val => console.log(val));
  }
}
```
*(Even better: Use `toSignal(this.searchControl.valueChanges)` to completely avoid `.subscribe()`).*

## 6. Zoneless Angular (Angular 18+ Experimental)

`zone.js` is a library that monkey-patches every API in the browser (setTimeout, Promises, DOM events) so Angular knows when to run Change Detection. It adds 100kb to your bundle and slows down the app.

With Signals, Angular no longer needs `zone.js`.

```typescript
// ✅ ALWAYS: In new Angular 18+ apps, enable Zoneless performance
import { bootstrapApplication } from '@angular/platform-browser';
import { provideExperimentalZonelessChangeDetection } from '@angular/core';

bootstrapApplication(AppComponent, {
  providers: [
    // This entirely removes the need for Zone.js! 
    // You MUST use Signals and OnPush everywhere for this to work.
    provideExperimentalZonelessChangeDetection(),
  ]
});
```

---

**Execution Protocol**
1. **Never mutate Signal arrays/objects directly**: Calling `this.items().push(newItem)` will NOT trigger a UI update. You must create a new reference: `this.items.update(items => [...items, newItem])`.
2. **`untracked()`**: If you need to read a Signal inside a `computed()` or `effect()` WITHOUT subscribing to its changes, wrap it in `untracked(() => this.mySignal())`.
3. **No standalone: true needed**: As of Angular 19, components are standalone by default. Do not write `standalone: true` explicitly in the `@Component` decorator unless working in an older v17/18 codebase.
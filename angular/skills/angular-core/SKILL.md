---
name: angular-core
description: The ultimate architectural standard for Angular Core (v18 & v19+) Standalone Components by Default, inject(), Signal Inputs/Outputs/Models, afterNextRender, and Zoneless Performance.
author: Diego Villanueva
trigger: When writing Angular components, managing component architecture, using afterNextRender, or injecting dependencies.
---

# Enterprise Angular Core Architecture (v18 & v19+)

Angular has undergone a complete renaissance. Legacy patterns (Constructors, `@Input`, `*ngIf`, `NgModule`, `Zone.js`) are fully obsolete.

To build enterprise-grade, ultra-performant Angular applications, you MUST adhere to modern standards.

---

## 1. Standalone by Default (Angular 19+)

In Angular 19+, all components, directives, and pipes are **standalone by default**. You do NOT need to write `standalone: true` in the `@Component` decorator.

**❌ NEVER** write `standalone: true` in new Angular 19+ applications.
**✅ ALWAYS** import component dependencies directly into the `imports` array.

```typescript
import { Component, ChangeDetectionStrategy, signal, computed, inject } from '@angular/core';
import { CurrencyPipe } from '@angular/common';

@Component({
  selector: 'app-product-card',
  // standalone: true is default in Angular 19+
  imports: [CurrencyPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="product-box">
      <h3>{{ title() }}</h3>
      <p>{{ price() | currency }}</p>
    </div>
  `
})
export class ProductCardComponent {
  readonly title = input.required<string>();
  readonly price = input.required<number>();
}
```

---

## 2. Dependency Injection (`inject()` Function)

Historically, dependencies were injected via the `constructor`. This created massive boilerplate and made class inheritance (`extends BaseComponent`) messy because all dependencies had to be passed via `super()`.

**❌ NEVER** use constructor injection.
**✅ ALWAYS** use the `inject()` function.

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

---

## 3. Modern Lifecycle: `afterNextRender` and `afterRender`

In SSR (Server-Side Rendering) and modern Angular architectures, `ngOnInit` and `ngAfterViewInit` run in contexts where direct DOM manipulation or canvas rendering may fail on the server.

**✅ ALWAYS** use `afterNextRender` to run DOM-specific initializations safely in the browser only.

```typescript
import { Component, ElementRef, viewChild, afterNextRender } from '@angular/core';

@Component({
  selector: 'app-interactive-chart',
  template: `<canvas #chartCanvas></canvas>`
})
export class InteractiveChartComponent {
  readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('chartCanvas');

  constructor() {
    // Guaranteed to execute ONLY in the browser, AFTER the DOM is fully painted
    afterNextRender(() => {
      const ctx = this.canvas().nativeElement.getContext('2d');
      if (ctx) {
        this.renderChart(ctx);
      }
    });
  }

  private renderChart(ctx: CanvasRenderingContext2D) {
    // Paint canvas...
  }
}
```

---

## 4. Signal Queries (`viewChild`, `viewChildren`, `contentChild`)

Decorators like `@ViewChild` and `@ContentChild` are replaced by Signal-based query functions. They update automatically when conditional elements (`@if`) appear or disappear.

```typescript
import { Component, viewChild, viewChildren, ElementRef } from '@angular/core';

export class FormContainerComponent {
  // Required query (throws compile-time/runtime error if not present)
  readonly submitBtn = viewChild.required<ElementRef<HTMLButtonElement>>('submitBtn');

  // Optional query (returns Signal<ElementRef | undefined>)
  readonly optionalInput = viewChild<ElementRef<HTMLInputElement>>('optionalInput');

  // Collection query (returns Signal<readonly ElementRef[]>)
  readonly fieldList = viewChildren<ElementRef>('formField');

  focusSubmit(): void {
    this.submitBtn().nativeElement.focus();
  }
}
```

---

## 5. Modern Built-In Control Flow (`@if`, `@for`, `@switch`)

Built-in Control Flow is up to 90% faster than legacy `*ngIf` / `*ngFor` structural directives.

```html
@if (isLoading()) {
  <app-skeleton-loader />
} @else {
  <!-- track expression is MANDATORY in Angular for high performance -->
  @for (item of items(); track item.id; let idx = $index, count = $count) {
    <div class="row">
      <span>{{ idx + 1 }}/{{ count }}</span>
      <span>{{ item.name }}</span>
    </div>
  } @empty {
    <div class="empty-state">No items found.</div>
  }
}
```

---

## 6. Memory Leak Elimination (`DestroyRef` & `takeUntilDestroyed`)

Forget implementing `ngOnDestroy`. Use `DestroyRef` and `takeUntilDestroyed()`.

```typescript
import { Component, DestroyRef, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

export class PollingComponent {
  private readonly destroyRef = inject(DestroyRef);

  constructor() {
    // Automatically cleans up subscription when component is destroyed
    interval(5000).pipe(
      takeUntilDestroyed(this.destroyRef)
    ).subscribe(() => this.pollStatus());

    // Register custom teardown logic
    this.destroyRef.onDestroy(() => {
      console.log('Component destroyed, resources released.');
    });
  }
}
```

---

**Execution Protocol**
1. **Always enforce `ChangeDetectionStrategy.OnPush`**: Ensures compatibility with Signals and Zoneless Angular.
2. **Never access `window` / `document` in `ngOnInit`**: Use `afterNextRender()`.
3. **No Constructor DI**: Always use `inject()`.
4. **Mandatory `track` in `@for`**: Always provide a unique identifier (e.g. `track item.id`).
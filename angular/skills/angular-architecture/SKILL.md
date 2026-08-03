---
name: angular-architecture
description: The ultimate architectural standard for modern Angular 17+ Standalone Components, Feature-First Structure, Smart/Dumb Components, and Core/Shared boundaries.
author: Diego Villanueva
trigger: When structuring a new project, deciding where to place files, generating components, or enforcing modular architecture in Angular.
---

# Enterprise Angular Architecture (Standalone Era)

Modern Angular (v14+) fundamentally changed how we architect applications by introducing **Standalone Components**. The days of massive `SharedModule`, `CoreModule`, and tangled `NgModules` are over.

This architecture enforces Domain-Driven Design (DDD), strict boundaries, and the "Proximity Rule".

## 1. The Proximity Rule (Scope Determines Structure)

**"Code belongs as close to where it is used as possible."**

If a `CartSummaryComponent` is only used inside the `ShoppingCartComponent`, it MUST live inside the `shopping-cart` folder. It should NOT live in a global `shared/components` folder.

| Usage | Placement |
|-------|-----------|
| Used exclusively by 1 feature | `features/[feature]/components/` |
| Used by 2+ features | `shared/ui/` |

## 2. The Enterprise Folder Structure

The application is divided into three strict boundaries: `core/`, `shared/`, and `features/`.

```text
src/app/
  ├── core/                 # SINGLETONS: Only imported once (Auth, API, Interceptors, Guards)
  │   ├── auth/
  │   ├── http/
  │   ├── error-handling/
  │   └── layout/           # Global app layouts (MainLayout, AuthLayout)
  │
  ├── shared/               # REUSABLES: Used by multiple features (UI, Pipes, Directives)
  │   ├── ui/               # Button, Modal, Card (DUMB components)
  │   ├── utils/            # format-date.ts, validators.ts
  │   └── directives/       # click-outside.directive.ts
  │
  ├── features/             # DOMAIN LOGIC: The actual business capabilities
  │   ├── products/         # Each feature is a self-contained Bounded Context
  │   │   ├── models/       # Interfaces (Product, Category)
  │   │   ├── services/     # ProductService, ProductStore (Signals)
  │   │   ├── components/   # ProductCard (Dumb)
  │   │   ├── pages/        # ProductList, ProductDetails (Smart/Routed)
  │   │   └── products.routes.ts # Feature-specific routing
  │   │
  │   └── checkout/
  │
  ├── app.component.ts      # Root Component
  ├── app.config.ts         # Global Providers (Router, HttpClient, Animations)
  └── app.routes.ts         # Lazy-loaded feature routes
```

## 3. Boundary Rules (Strict Dependency Flow)

To prevent circular dependencies and spaghetti code, you MUST respect these import rules:

1. **`core/`** can ONLY be imported by `app.config.ts` or `app.component.ts` (or other core services). A feature cannot import `core/` (unless it's an Auth token or global interface).
2. **`shared/`** can be imported by anyone. It contains no business logic and no side effects. It is pure UI and utilities.
3. **`features/`** CANNOT import from other `features/`. The `checkout` feature cannot import the `ProductService` from the `products` feature. If they need to share data, that data must be lifted to a shared state or handled via route parameters.

## 4. Smart vs Dumb Components (Container / Presentational)

This is the most critical pattern in frontend architecture. Mixing UI logic with Business logic makes components untestable and un-reusable.

### A. Dumb Components (Presentational)
- **Role**: Only care about *how things look*.
- **Rules**: 
  - They DO NOT inject services (No `constructor(private api: ApiService)`).
  - They communicate exclusively via `@Input()` and `@Output()`.
  - They MUST use `ChangeDetectionStrategy.OnPush` for maximum performance.

```typescript
// ✅ ALWAYS: Dumb components use OnPush and communicate via I/O
@Component({
  selector: 'app-product-card',
  standalone: true,
  template: `
    <div>
      <h3>{{ product().name }}</h3>
      <button (click)="onBuy()">Buy</button>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ProductCardComponent {
  product = input.required<Product>(); // Angular 17+ Signal Input
  buy = output<number>(); // Angular 17+ Signal Output

  onBuy() {
    this.buy.emit(this.product().id);
  }
}
```

### B. Smart Components (Container / Pages)
- **Role**: Only care about *how things work*.
- **Rules**:
  - They live in the `pages/` folder of a feature.
  - They inject Services and State (Signals, RxJS).
  - They pass data down to Dumb components.
  - They handle the `@Output()` events from Dumb components and call APIs.

```typescript
// ✅ ALWAYS: Smart components handle logic and pass data to Dumb components
@Component({
  selector: 'app-product-list-page',
  standalone: true,
  imports: [ProductCardComponent],
  template: `
    @for (p of productService.products(); track p.id) {
      <app-product-card 
        [product]="p" 
        (buy)="handlePurchase($event)" 
      />
    }
  `
})
export class ProductListPage {
  // Injects the state/service
  productService = inject(ProductService); 

  handlePurchase(productId: number) {
    this.productService.purchase(productId); // Performs the side effect
  }
}
```

## 5. The End of NgModules

In modern Angular, `NgModule` is considered legacy. 

**❌ NEVER** create a `SharedModule` to export all your UI components. It creates massive bundles.
**✅ ALWAYS** use `standalone: true`. When a component needs a button, it imports exactly that button in its `imports: []` array.

```typescript
// ❌ ATROCIOUS: The old Angular 12 way
@NgModule({
  declarations: [MyComponent],
  imports: [SharedModule, CommonModule]
})
export class FeatureModule {}

// ✅ ALWAYS: The modern Angular 17+ way
@Component({
  standalone: true,
  imports: [PrimaryButtonComponent, CurrencyPipe], // Import EXACTLY what you need
})
export class MyComponent {}
```

## 6. Services & State Placement

Services should be scoped using `providedIn: 'root'` to make them tree-shakeable singletons. 
However, their physical file location matters:

- If it's a global service (e.g., `AuthService`), put it in `core/auth/`.
- If it's a feature service (e.g., `ProductService`), put it in `features/products/services/`.

If a service is highly specific to a single component and its children, provide it at the component level to destroy it when the component unmounts:

```typescript
// ✅ ALWAYS: Scope state strictly if it doesn't need to be global
@Component({
  selector: 'app-complex-form',
  standalone: true,
  providers: [FormStateService], // Service is created when component mounts, destroyed when it unmounts
})
export class ComplexFormComponent {}
```

---

**Execution Protocol**
1. **Barrel Files (`index.ts`)**: Use `index.ts` files in your `shared/ui` and `models` directories to clean up imports. `import { ButtonComponent } from '@shared/ui'`.
2. **Path Aliases**: ALWAYS configure `tsconfig.json` with path aliases to avoid `../../../` hell. Map `@core/*`, `@shared/*`, and `@features/*`.
3. **No Logic in Templates**: Never execute function calls in templates (e.g., `{{ calculateTotal() }}`). It destroys performance because Angular calls it on every change detection cycle. Use Pipes or Signals instead.
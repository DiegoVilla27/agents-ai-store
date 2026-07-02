---
name: nx-monorepo
description: The ultimate architectural standard for Nx Monorepos Library Boundaries, Tag Rules, Micro-frontends (Module Federation), and computation caching.
author: Diego Villanueva
trigger: When structuring a monorepo, creating Nx libraries, enforcing dependency boundaries, or configuring CI/CD pipelines.
---

# Enterprise Nx Monorepo Architecture

In an Enterprise environment, building a monolithic application inside the `apps/` directory is an architectural failure. 
Nx exists to enforce boundaries, maximize code reuse, and optimize build times through caching.

**THE CORE RULE**: The `apps/` directory should contain almost ZERO logic. The App is merely an empty shell that stitches together libraries. 90% of your code MUST live in `libs/`.

## 1. Library Types & Architecture

You cannot just throw code into `libs/shared`. You MUST categorize every library into one of four distinct types.

1. **`feature`** (Smart): Contains routed components, smart components, and connects to the store.
2. **`ui`** (Dumb): Pure presentational components. No HTTP calls, no Store injection. Only `@Input` and `@Output`.
3. **`data-access`**: Contains Services, HTTP calls, State Management (SignalStore), and DTO interfaces.
4. **`util`**: Pure TypeScript functions, Pipes, Constants, and Helpers. Zero UI dependencies.

```bash
# ✅ ALWAYS: Generate libraries with clear type and scope prefixes
nx g @nx/angular:lib libs/billing/feature-dashboard --tags=scope:billing,type:feature
nx g @nx/angular:lib libs/billing/data-access --tags=scope:billing,type:data-access
nx g @nx/angular:lib libs/shared/ui-buttons --tags=scope:shared,type:ui
```

## 2. Enforcing Boundaries (The ESLint Rules)

If `billing/feature-dashboard` directly imports a private component from `auth/feature-login`, you have created a Spaghetti Monorepo. 
You MUST enforce architectural constraints using Nx Tags and ESLint.

**✅ ALWAYS** configure `@nx/enforce-module-boundaries` in your root `.eslintrc.json` (or `eslint.config.js`).

```json
// .eslintrc.json
"@nx/enforce-module-boundaries": [
  "error",
  {
    "enforceBuildableLibDependency": true,
    "allow": [],
    "depConstraints": [
      // 1. TYPE RULES (Vertical Boundaries)
      {
        "sourceTag": "type:feature",
        "onlyDependOnLibsWithTags": ["type:ui", "type:data-access", "type:util"]
      },
      {
        "sourceTag": "type:ui",
        "onlyDependOnLibsWithTags": ["type:util"] // UI cannot depend on Data-Access!
      },
      {
        "sourceTag": "type:data-access",
        "onlyDependOnLibsWithTags": ["type:util"]
      },
      
      // 2. SCOPE RULES (Horizontal Boundaries)
      {
        "sourceTag": "scope:billing",
        "onlyDependOnLibsWithTags": ["scope:billing", "scope:shared"]
      },
      {
        "sourceTag": "scope:shared",
        "onlyDependOnLibsWithTags": ["scope:shared"] // Shared cannot depend on specific domains!
      }
    ]
  }
]
```
*(If a developer breaks these rules, their IDE will throw a red error and the CI pipeline will fail).*

## 3. The Public API (`index.ts`)

Every library has a single `index.ts` file at its root. This is the **Public API** of that library.

**❌ NEVER** allow Deep Imports. (e.g., `import { MyService } from '@myorg/billing/data-access/src/lib/my.service'`).
**✅ ALWAYS** import from the library's alias (e.g., `import { MyService } from '@myorg/billing/data-access'`).

If a component or service is NOT exported in the `index.ts`, it is considered PRIVATE to that library. No other library can use it. This is how you achieve true encapsulation in TypeScript.

```typescript
// libs/billing/data-access/src/index.ts

// ✅ EXPORT the public interface and the main service
export * from './lib/models/invoice.model';
export * from './lib/services/billing.service';

// ❌ DO NOT EXPORT internal helpers or private state stores
// export * from './lib/state/internal-billing.store';
```

## 4. Micro-Frontends (Module Federation)

When an enterprise app reaches 50+ developers, a single runtime becomes unmanageable. You MUST split the app using Nx Module Federation.

1. **Host App**: The shell container (e.g., the Sidebar and Header).
2. **Remote Apps**: Independent Angular applications that are injected into the Host at runtime (e.g., the Billing App, the HR App).

**✅ ALWAYS** use Nx generators to scaffold Micro-frontends.

```bash
# 1. Create the Host
nx g @nx/angular:host apps/shell --remotes=billing,hr

# 2. Run the entire ecosystem
nx serve shell --devRemotes=billing,hr
```
*Architecture Note: Remotes can be deployed independently without recompiling the Host. This allows the Billing team to deploy 10 times a day without affecting the HR team.*

## 5. Performance: Caching & CI/CD (`nx affected`)

In a monorepo with 100 libraries, running `ng test` runs 100,000 tests. This will take hours in CI.

**❌ NEVER** run `nx test` or `nx build` globally in a CI pipeline.
**✅ ALWAYS** use `nx affected` to only run tasks on the libraries that were changed in the current Git branch.

```bash
# CI/CD Pipeline Protocol
# 1. Check code formatting for affected libs
nx format:check

# 2. Run ESLint ONLY on changed libs and libs that depend on them
nx affected -t lint

# 3. Run Unit Tests ONLY on affected libs
nx affected -t test

# 4. Build ONLY the apps that were affected by the library changes
nx affected -t build --configuration=production
```

Furthermore, Nx uses a Computation Cache. If you run `nx build billing` on your laptop, and the code hasn't changed, Nx will restore the build from cache in 0.5 seconds instead of recompiling for 5 minutes. If you connect to Nx Cloud, this cache is shared across the entire team and CI runners.

---

**Execution Protocol**
1. **Circular Dependencies**: ESLint will catch these. If Lib A depends on Lib B, and Lib B depends on Lib A, the architecture is flawed. Extract the shared logic into a new Lib C.
2. **Library Size**: If a library has more than 10-15 components, it is too big. Split it. (e.g., split `billing/feature` into `billing/feature-invoices` and `billing/feature-subscriptions`).
3. **Paths Configuration**: The `tsconfig.base.json` controls the aliases. Nx updates this automatically when you generate a lib. Do not edit it manually unless you are renaming a library.

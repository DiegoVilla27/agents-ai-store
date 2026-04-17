---
name: web-micro-frontends
description: >
  Distributed frontend architectures using Module Federation and Vite.
  Trigger: When breaking down monoliths, orchestrating multi-team repositories, or setting up host/remote communication.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Module Federation (REQUIRED)

Compose multiple independent builds into a single application.

```typescript
// ✅ ALWAYS: Configure shared dependencies to avoid duplication
// vite.config.ts (Remote)
federation({
  name: 'remote-app',
  filename: 'remoteEntry.js',
  exposes: {
    './Button': './src/components/Button.tsx',
  },
  shared: ['react', 'react-dom']
})

// ✅ ALWAYS: Dynamic loading in Host
const RemoteButton = lazy(() => import('remote-app/Button'));
```

---

## Communication & State (REQUIRED)

Keep micro-frontends decoupled.

| Method | Recommendation |
|--------|----------------|
| **Custom Events** | Use for low-frequency communication. |
| **Shared Store** | Pass a slice of a store (Zustand) via props or context. |
| **URL Params** | Preferred for state that should survive a refresh. |

---

## Shared Styling (REQUIRED)

Avoid CSS collisions between independent apps.

```typescript
// ✅ ALWAYS: Use Scoped CSS or Tailwind prefix
// Use tailwind.config.js 'important' property or CSS Modules.

// ❌ NEVER: Global CSS that might override other remotes
// Do not use generic class names like '.title' in global scope.
```

---

## Execution Protocol (REQUIRED)

1. **Orchestrate**: Define the Host app and its navigation structure.
2. **Expose**: Identify reusable assets in Remote apps and expose them via federation.
3. **Connect**: Update Host to point to the Remote's `remoteEntry.js`.
4. **Resilience**: Implement Error Boundaries around every Remote component to prevent "blast radius" failures.

---

## Uncompromising Constraints

- **Single Shell**: Only the Host should handle routing and orchestration logic.
- **Dependency Sync**: Critical shared libraries (React, etc.) must have compatible versioning.
- **Isolation**: Each micro-frontend must be able to run and be tested independently for local development.

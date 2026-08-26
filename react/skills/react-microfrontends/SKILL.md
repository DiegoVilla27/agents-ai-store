---
name: react-microfrontends
description: The ultimate architectural standard for React Microfrontends with Vite, Module Federation 2.0 (@originjs/vite-plugin-federation), Shared Dependencies, and Resilient Remote Loading.
author: Diego Villanueva
trigger: When designing modular microfrontends in React, configuring Module Federation with Vite, integrating remote applications, or sharing singleton dependencies across apps.
---

# Enterprise React Microfrontends Architecture (Module Federation 2.0)

For large enterprise web suites, decoupling massive monolithic frontends into independently deployable, autonomous **Microfrontends (MFEs)** accelerates deployment velocity and team autonomy. Modern React microfrontends utilize **Vite** with **Module Federation 2.0**.

---

## 1. Remote Microfrontend Configuration (`vite.config.ts`)

In the Remote MFE (`remote-app`):

```bash
npm install -D @originjs/vite-plugin-federation
```

```typescript
// remote-app/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import federation from '@originjs/vite-plugin-federation';

export default defineConfig({
  plugins: [
    react(),
    federation({
      name: 'remoteApp',
      filename: 'remoteEntry.js',
      // Expose components or full page sub-trees
      exposes: {
        './UserProfileCard': './src/components/UserProfileCard.tsx',
        './BillingRoutes': './src/routes/BillingRoutes.tsx',
      },
      shared: ['react', 'react-dom', 'zustand'],
    }),
  ],
  build: {
    target: 'esnext',
    minify: false,
    cssCodeSplit: false,
  },
});
```

---

## 2. Host / Shell Application Configuration

In the Host Shell (`host-app`):

```typescript
// host-app/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import federation from '@originjs/vite-plugin-federation';

export default defineConfig({
  plugins: [
    react(),
    federation({
      name: 'hostApp',
      remotes: {
        remoteApp: 'http://localhost:5001/assets/remoteEntry.js',
      },
      shared: ['react', 'react-dom', 'zustand'],
    }),
  ],
  build: {
    target: 'esnext',
  },
});
```

---

## 3. Dynamic Remote Loading with `<Suspense>` & Error Boundaries

Load remote components dynamically with full resilience against remote network failures:

```tsx
// host-app/src/pages/DashboardPage.tsx
import React, { Suspense, Component, type ReactNode } from 'react';

// Lazy-load remote component via module federation
const RemoteUserProfileCard = React.lazy(() => import('remoteApp/UserProfileCard'));

// Resilient Error Boundary for Remote failures
class MicrofrontendErrorBoundary extends Component<{ children: ReactNode; fallback: ReactNode }, { hasError: boolean }> {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error) {
    console.error('[MFE Load Error]', error);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}

export function DashboardPage() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Host Dashboard</h1>

      <MicrofrontendErrorBoundary
        fallback={
          <div className="p-6 border border-amber-300 bg-amber-50 rounded-lg text-amber-900">
            <h3 className="font-semibold">User Profile Temporarily Unavailable</h3>
            <p className="text-sm mt-1">The profile service is undergoing maintenance.</p>
          </div>
        }
      >
        <Suspense fallback={<div className="h-32 bg-gray-100 animate-pulse rounded-lg" />}>
          <RemoteUserProfileCard userId="usr-990" />
        </Suspense>
      </MicrofrontendErrorBoundary>
    </div>
  );
}
```

---

## 4. Cross-MFE Shared State Communication

Microfrontends must remain loosely coupled. Shared state contracts should be strictly defined:

```typescript
// shared-kernel/src/auth-store.ts
import { create } from 'zustand';

interface AuthSessionState {
  token: string | null;
  user: { id: string; name: string } | null;
  setSession: (token: string, user: any) => void;
  clearSession: () => void;
}

// Single instance shared across host and remotes via shared: ['zustand']
export const useAuthSession = create<AuthSessionState>((set) => ({
  token: null,
  user: null,
  setSession: (token, user) => set({ token, user }),
  clearSession: () => set({ token: null, user: null }),
}));
```

---

**Execution Protocol**
1. **Always declare `react` and `react-dom` in `shared`**: Prevents multiple copies of React from executing simultaneously.
2. **Always wrap remote components in `<Suspense>` and `ErrorBoundary`**: Prevents a failing remote from crashing the entire host app.
3. **Never allow bidirectional tight imports between remotes**: Host imports Remotes; Remotes do not import sister remotes.
4. **Use TypeScript Module Declarations**: Declare remote module types in a `remotes.d.ts` file in the host project to maintain type safety.

---
name: react-zustand
description: The ultimate architectural standard for global client state management using Zustand, focusing on atomic selections, slice patterns, and performance.
author: Diego Villanueva
trigger: When managing global client state, defining stores, or debugging excessive re-renders in Zustand.
---

# Zustand State Architecture

Zustand is a small, fast, and scalable bearbones state-management solution using simplified flux principles. It replaces Context API and Redux for **Client State** (UI toggles, dark mode, multi-step form data). 

*Do NOT use Zustand for Server State (API responses); use TanStack Query instead.*

## 1. The Core Paradigm & TypeScript Strictness

Always type your store exactly. The syntax requires `create<StoreType>()(...)` to ensure strict inference inside the `set` function.

```tsx
// ✅ ALWAYS: Strictly typed stores
import { create } from 'zustand';

interface UIStore {
  sidebarOpen: boolean;
  activeTheme: 'light' | 'dark';
  toggleSidebar: () => void;
  setTheme: (theme: 'light' | 'dark') => void;
}

export const useUIStore = create<UIStore>()((set) => ({
  sidebarOpen: false,
  activeTheme: 'light',
  // Use callback for state dependent on previous state
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
  // Direct object for independent state
  setTheme: (theme) => set({ activeTheme: theme }),
}));
```

## 2. Atomic Selections (The Re-render Killer)

The biggest mistake developers make with Zustand is destructuring the entire store. If you do this, your component will re-render EVERY time ANY property in the store changes.

```tsx
// ❌ ATROCIOUS: Component re-renders if `activeTheme` changes!
const { sidebarOpen } = useUIStore(); 

// ✅ ALWAYS: Atomic selection. Only re-renders when `sidebarOpen` changes.
const sidebarOpen = useUIStore((state) => state.sidebarOpen);
```

## 3. Multiple Selections & `useShallow`

If you need multiple properties from the store, calling the hook multiple times is fine. However, returning an object from the selector creates a *new reference* every render, causing infinite re-renders unless you use `useShallow` (Zustand v4.5+).

```tsx
// ✅ ALWAYS: Use `useShallow` for object selections
import { useShallow } from 'zustand/react/shallow';

function Header() {
  const { sidebarOpen, toggleSidebar } = useUIStore(
    useShallow((state) => ({
      sidebarOpen: state.sidebarOpen,
      toggleSidebar: state.toggleSidebar,
    }))
  );
}
```

## 4. Reading State Outside of React (No Hooks Needed)

Zustand lives *outside* of React's lifecycle. You don't need a hook to read or write to it. This is invaluable for Axios interceptors, WebSockets, or standard utility functions where React hooks are forbidden.

```typescript
// ✅ ALWAYS: Access state in vanilla JS functions
import { useUIStore } from './store';

export function handleNetworkError() {
  const currentTheme = useUIStore.getState().activeTheme;
  
  if (currentTheme === 'dark') {
    // Write state directly!
    useUIStore.setState({ sidebarOpen: true });
  }
}
```

## 5. The Slice Pattern (Scaling Large Stores)

Do not create a massive 1000-line store file. Do not create 20 different tiny stores. The ideal architecture for a domain is the **Slice Pattern**: independent functions that are merged into a single bounded context store.

```typescript
// ✅ ALWAYS: The Slice Pattern for modularity
import { StateCreator, create } from 'zustand';

// 1. Define Slices
interface CartSlice { cart: string[]; addToCart: (id: string) => void; }
interface UserSlice { user: string | null; login: (name: string) => void; }

const createCartSlice: StateCreator<CartSlice & UserSlice, [], [], CartSlice> = (set) => ({
  cart: [],
  addToCart: (id) => set((state) => ({ cart: [...state.cart, id] })),
});

const createUserSlice: StateCreator<CartSlice & UserSlice, [], [], UserSlice> = (set) => ({
  user: null,
  login: (name) => set({ user: name }),
});

// 2. Combine them into one store
export const useAppStore = create<CartSlice & UserSlice>()((...a) => ({
  ...createCartSlice(...a),
  ...createUserSlice(...a),
}));
```

## 6. Middlewares: Immer and Persist

Zustand supports powerful middlewares out of the box.

- **Immer**: If your state is deeply nested (e.g., `state.user.profile.settings.theme`), updating it with standard spread operators is a nightmare. Use the `immer` middleware to mutate state directly.
- **Persist**: Automatically syncs your state to `localStorage` (Web) or `AsyncStorage` (React Native).

```typescript
// ✅ ALWAYS: Use middlewares for complex stores
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

export const useSettingsStore = create<SettingsStore>()(
  persist(
    immer((set) => ({
      nested: { deeply: { value: 0 } },
      updateDeep: () => 
        // Immer allows direct mutation!
        set((state) => {
          state.nested.deeply.value += 1; 
        }),
    })),
    { name: 'settings-storage' } // Key in localStorage
  )
);
```

---

**Execution Protocol**
1. **Never sync props to Zustand**: Zustand is global. If a component receives a prop, do not try to dump it into Zustand in a `useEffect`. Zustand should be the single source of truth from the top down.
2. **Avoid Action Boilerplate**: You do not need Redux-style action types or reducers. Expose functions directly in the store that mutate the state.
3. **DevTools Middleware**: Always wrap your root stores in the `devtools` middleware so you can time-travel and inspect your state using the Redux DevTools browser extension.
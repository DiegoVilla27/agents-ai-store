---
name: react-core
description: The ultimate architectural standard for React 19+, embracing the React Compiler, Server Components (RSC), Server Actions, and modern state management patterns.
author: Diego Villanueva
trigger: When building React components, managing state, handling forms, fetching data, or defining component boundaries.
---

# React 19 Core Architecture

React has evolved from a simple UI library into a full-stack architectural framework. React 19 introduces a massive paradigm shift: the React Compiler, Server Components (RSC), and Actions. You must discard legacy React 16-18 patterns (like manual memoization and `useEffect` data fetching) to write modern, performant React.

## 1. The React Compiler (The End of Manual Memoization)

The React Compiler automatically memoizes values and functions at build time. 

- **Prohibited Hooks**: NEVER write `useMemo`, `useCallback`, or `React.memo()`. The compiler handles this automatically.
- **Rule Strictness**: The compiler ONLY works if your code strictly follows the Rules of React. If you mutate a prop or a state object directly, the compiler will fail and your component will de-optimize.

```tsx
// ✅ ALWAYS: Write plain JavaScript. The compiler optimizes it.
export function ProductList({ items }) {
  // Automatically memoized by the compiler
  const activeItems = items.filter(item => item.isActive);
  const sortedItems = activeItems.sort((a, b) => a.price - b.price);

  // Automatically memoized by the compiler
  const handleCheckout = (id) => {
    console.log("Checkout", id);
  };

  return <List data={sortedItems} onAction={handleCheckout} />;
}

// ❌ NEVER: Do not pollute the codebase with legacy memoization
const activeItems = useMemo(() => items.filter(...), [items]);
const handleCheckout = useCallback((id) => {...}, []);
```

## 2. React Server Components (RSC) vs Client Components

By default, every component is a **Server Component**. They render exclusively on the server, send zero JavaScript to the client, and can access backend resources (databases, file systems) directly.

- **The `'use client'` Directive**: Only add this at the top of a file if the component absolutely requires browser APIs (e.g., `window`), interactivity (`onClick`, `onChange`), or client state (`useState`, `useEffect`).
- **Pushing Client Boundaries Down**: Keep `'use client'` as far down the component tree as possible. Do not make a whole page a Client Component just because it has one interactive button.
- **Interleaving**: You CAN pass Server Components as `children` to Client Components.

```tsx
// ✅ ALWAYS: Default to Server Components for data fetching
import { db } from '@/lib/db';
import { InteractiveLikeButton } from './InteractiveLikeButton'; // This is a 'use client' component

export default async function ProductPage({ id }) {
  const product = await db.getProduct(id); // Direct DB access

  return (
    <article>
      <h1>{product.title}</h1>
      {/* Client component as a leaf node */}
      <InteractiveLikeButton productId={id} /> 
    </article>
  );
}
```

## 3. Actions and Modern Forms

React 19 replaces the traditional `onSubmit={e => e.preventDefault(); ...}` pattern with **Actions**.

- **Server Actions**: Functions marked with `'use server'` that execute on the backend but can be called directly from client forms.
- **`useActionState`**: Replaces `useState` for managing form submission state, returning the current state, a dispatch function, and a pending boolean.
- **`useFormStatus`**: Allows nested form components (like submit buttons) to read the loading state without prop drilling.
- **`useOptimistic`**: Instantly update the UI while the background Action is running.

```tsx
// ✅ ALWAYS: Use Server Actions and Form Actions
'use client';
import { useActionState } from 'react';
import { updateProfile } from './actions'; // 'use server' function

export function ProfileForm() {
  const [state, formAction, isPending] = useActionState(updateProfile, null);

  return (
    <form action={formAction}>
      <input name="username" />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Saving...' : 'Save'}
      </button>
      {state?.error && <p>{state.error}</p>}
    </form>
  );
}
```

## 4. The `use` API (Promises & Context)

The `use()` API allows you to read the value of a Promise or Context *during render*. 

- **Context**: Replaces `useContext(MyContext)`. Unlike hooks, `use(MyContext)` can be called conditionally inside `if` blocks.
- **Promises**: Replaces fetching in `useEffect`. If the Promise is not resolved, it suspends the component (triggering the nearest `<Suspense>` boundary).

```tsx
// ✅ ALWAYS: Use `use` for conditional context reading
import { use } from 'react';

function ThemePanel({ showDetails }) {
  if (!showDetails) return null;
  // This is perfectly valid in React 19
  const theme = use(ThemeContext); 
  return <div>{theme}</div>;
}
```

## 5. Derived State & Prop Synchronization (The Anti-Pattern)

The most common source of bugs in React is duplicating props into state. 

- **Rule**: If a value can be computed from existing props or state during render, **do not put it in state**. 
- **Rule**: NEVER use `useEffect` to synchronize a prop to a state variable. If you need to reset state when a prop changes, pass a `key` to the component to force a remount.

```tsx
// ❌ ATROCIOUS: Syncing props to state (causes double renders & stale bugs)
function Profile({ user }) {
  const [name, setName] = useState(user.name);
  useEffect(() => { setName(user.name); }, [user.name]);
}

// ✅ ALWAYS: Derive state during render
function Profile({ user }) {
  const name = user.name; // Always fresh!
}
```

## 6. The `useEffect` Prohibition

`useEffect` is an escape hatch for synchronizing with external systems (like WebSockets, analytics, or DOM APIs). It is NOT for data fetching, and it is NOT for reacting to state changes.

- **Data Fetching**: Use Server Components, React Query, or SWR. Never `useEffect`.
- **State Reactions**: If you want to trigger an event when state changes, do it in the event handler that caused the state change, not in an effect.

```tsx
// ❌ WRONG: Reacting to state in an effect
const [items, setItems] = useState([]);
useEffect(() => {
  if (items.length > 0) notifyServer(items);
}, [items]);

// ✅ ALWAYS: Handle side effects in the event handler
const handleAddItem = (newItem) => {
  const newItems = [...items, newItem];
  setItems(newItems);
  notifyServer(newItems); // Do it here!
};
```

---

**Execution Protocol**
1. **Named Imports Only**: Always use `import { useState } from 'react'`. Never `import React from 'react'`. The default export is deprecated in modern React.
2. **Immutability Strictness**: React relies on referential equality (`Object.is`) to know when to re-render. `state.push(item); setState(state)` does absolutely nothing. You must use `setState([...state, item])`.
3. **Embrace StrictMode**: React mounts, unmounts, and remounts components in development to expose bugs in your `useEffect` cleanups. If your app breaks in StrictMode, your code is broken. Do not disable it.
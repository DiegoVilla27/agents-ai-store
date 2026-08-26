---
name: react-compiler
description: The ultimate architectural standard for the React 19 Compiler (Forget), Rules of React, eslint-plugin-react-compiler, and Eliminating Manual useMemo/useCallback.
author: Diego Villanueva
trigger: When configuring the React 19 Compiler, debugging compiler bailouts, removing legacy useMemo/useCallback boilerplate, or enforcing Rules of React.
---

# Enterprise React 19 Compiler Architecture (React Forget)

The **React Compiler** (formerly code-named *React Forget*) is an optimizing build-time compiler that analyzes component dependencies and automatically inserts fine-grained memoization across JSX, functions, and derived values. It guarantees optimal re-render performance without requiring manual `useMemo`, `useCallback`, or `React.memo()`.

---

## 1. Compiler Configuration (`vite.config.ts`)

Enable the compiler via the official Babel/Vite plugin:

```bash
npm install -D babel-plugin-react-compiler eslint-plugin-react-compiler
```

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [
          ['babel-plugin-react-compiler', { target: '19' }],
        ],
      },
    }),
  ],
});
```

```json
// .eslintrc.json
{
  "plugins": ["eslint-plugin-react-compiler"],
  "rules": {
    "react-compiler/react-compiler": "error"
  }
}
```

---

## 2. Writing Idiomatic React (The End of Manual Memoization)

**❌ NEVER** write `useMemo`, `useCallback`, or `React.memo()` in React 19 codebases.
**✅ ALWAYS** write clean, idiomatic JavaScript. The compiler automatically determines what to cache.

```tsx
// ❌ OBSOLETE: React 16-18 Manual Memoization Boilerplate
export function UserDirectory({ users, filter }) {
  const filteredUsers = useMemo(() => {
    return users.filter(u => u.name.toLowerCase().includes(filter.toLowerCase()));
  }, [users, filter]);

  const handleSelect = useCallback((id: string) => {
    console.log('Selected user:', id);
  }, []);

  return <UserList data={filteredUsers} onSelect={handleSelect} />;
}

// ✅ ALWAYS: Modern React 19 (Zero Memo Boilerplate, 100% Optimized by Compiler)
export function UserDirectory({ users, filter }) {
  const filteredUsers = users.filter(u => u.name.toLowerCase().includes(filter.toLowerCase()));

  const handleSelect = (id: string) => {
    console.log('Selected user:', id);
  };

  return <UserList data={filteredUsers} onSelect={handleSelect} />;
}
```

---

## 3. Strict Adherence to the Rules of React

The React Compiler relies on mathematical purity to optimize code safely. If a component violates the Rules of React, the compiler **bails out** (skips optimization) for that component.

### Rule 1: Components and Hooks Must Be Pure
**❌ NEVER** mutate values created outside render (like global variables or props):

```tsx
// ❌ BROKEN: Mutating a prop causes compiler bailout & runtime bugs
function BadComponent({ user }) {
  user.lastViewed = Date.now(); // Mutating prop!
  return <div>{user.name}</div>;
}

// ✅ ALWAYS: Treat all props and state as immutable
function GoodComponent({ user }) {
  const displayUser = { ...user, lastViewed: Date.now() };
  return <div>{displayUser.name}</div>;
}
```

### Rule 2: Never Mutate Existing State References

```tsx
// ❌ BROKEN: Mutating state array in place
function TaskList() {
  const [tasks, setTasks] = useState(['Task 1', 'Task 2']);

  const addTask = (newTask: string) => {
    tasks.push(newTask); // Mutates reference!
    setTasks(tasks);     // Compiler and React will fail to re-render
  };
}

// ✅ ALWAYS: Create a new array reference
function TaskList() {
  const [tasks, setTasks] = useState(['Task 1', 'Task 2']);

  const addTask = (newTask: string) => {
    setTasks(prev => [...prev, newTask]); // Safe immutable update
  };
}
```

---

## 4. Compiler Escape Hatches (Debugging Only)

If a complex third-party library or legacy code causes a compiler error, you can opt-out a single component using the `"use no memo"` directive:

```tsx
export function LegacyThirdPartyWrapper() {
  "use no memo"; // Tells React Compiler to skip this specific function
  // Legacy non-pure code...
}
```

---

**Execution Protocol**
1. **Always enforce `eslint-plugin-react-compiler` as an error**: Catch rule violations at build time.
2. **Never import `useMemo` or `useCallback` in new components**: Trust the compiler.
3. **Keep render functions pure**: Do not perform I/O, timers, or prop mutations during render.
4. **Treat all object and array inputs as immutable**: Always use spread syntax or functional updates.

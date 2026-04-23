---
name: web-javascript
description: >
  Senior-level JavaScript fundamentals and runtime behavior.
  Trigger: When writing pure JavaScript logic, utility functions, or optimizing runtime performance.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Event Loop & Macrotasks (REQUIRED)

Understand the order of execution to avoid blocking the main thread.

```javascript
// ✅ ALWAYS: Use Promise.then (Microtask) for high priority async
Promise.resolve().then(() => console.log('Microtask'));

// ❌ NEVER: Heavy blocking loops in the main thread
// Use Web Workers or break heavy loops into smaller chunks with setTimeout (Macrotask).
```

---

## Closures & Memory Management (REQUIRED)

```javascript
// ✅ ALWAYS: Create factories and private state with closures
function createCounter() {
  let count = 0;
  return () => ++count;
}

// ❌ NEVER: Unintentional memory leaks
// Common mistake: holding references to heavy objects in global closures.
```

---

## Prototypes & Class Patterns (REQUIRED)

| Feature | Recommendation |
|---------|----------------|
| **Prototypes** | Use for memory-efficient method sharing. |
| **Classes** | Preferred for readability; they are syntactic sugar over prototypes. |
| **Factories** | Use when 'new' keyword ceremony isn't needed. |

---

## ESNext Features (REQUIRED)

```javascript
// ✅ ALWAYS: Use modern array methods (ES2023+)
const people = [{ name: 'Diego', age: 30 }];
const newPeople = people.toSorted((a, b) => a.age - b.age); // Non-mutating
const groups = Object.groupBy(people, (p) => p.age);

// ❌ NEVER: Mutating original arrays in functional logic
// Avoid sort(), reverse(), splice() when working with immutable state.
```

---

## Execution Protocol (REQUIRED)

1. **Async Control**: Use `async/await` for readability, but understand the underlying Promises.
2. **Scope**: Prefer `const` and `let` over `var` (always).
3. **Purity**: Aim for pure functions where possible for easier testing.
4. **Optimality**: Use `requestIdleCallback` for non-critical tasks.

---

## Uncompromising Constraints

- **Single Thread**: Never perform heavy computations (e.g., massive JSON parsing) on the main thread during navigation.
- **Strict Equality**: Always use `===` and `!==`.
- **Global Scope**: Polluting the global `window` or `globalThis` object is strictly prohibited.

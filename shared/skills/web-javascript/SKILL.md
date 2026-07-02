---
name: web-javascript
description: An exhaustive, senior-level compendium of modern JavaScript mechanics, best practices, and runtime behavior.
author: Diego Villanueva
trigger: When writing pure JavaScript/TypeScript logic, optimizing runtime performance, or debugging complex JS behaviors.
---

# JavaScript Engineering Mastery

You are developing with the most widely used language in the world. Your code must be resilient, predictable, and highly optimized. Master the runtime, embrace the asynchronous nature of the web, and write code that is unassailably clean.

## 1. Variables, Scoping, and the TDZ

- **Immutability First**: Default to `const`. If a variable must be reassigned, use `let`. Never, under any circumstances, use `var`.
- **Block Scoping**: `let` and `const` are block-scoped. Leverage blocks `{}` to limit variable lifespans.
- **The Temporal Dead Zone (TDZ)**: Unlike `var`, `let` and `const` are not initialized until their definition is evaluated. Accessing them beforehand throws a `ReferenceError`.

## 2. Hoisting & Strict Mode

- **Function Hoisting**: Function declarations (`function foo() {}`) are hoisted to the top of their scope, meaning they can be called before they are defined.
- **Variable Hoisting**: `var` is hoisted but initialized to `undefined`. `let` and `const` are hoisted but remain in the TDZ.
- **Strict Mode**: Always operate in strict mode (`"use strict";` or natively within ES Modules) to prevent accidental globals and silent failures.

## 3. Data Types, Equality & Coercion

- **Strict Equality**: Always use `===` and `!==`. Never use `==` or `!=` to avoid unpredictable type coercion.
- **Falsy Values**: Know the 6 falsy values natively: `false`, `0`, `""`, `null`, `undefined`, and `NaN`.
- **Nullish Coalescing (`??`)**: Use `??` to fall back on defaults only when the left side is `null` or `undefined` (unlike `||` which triggers on any falsy value, like `0` or `""`).
- **Optional Chaining (`?.`)**: Safely access deep object properties without throwing `TypeError`s if a reference is nullish. Example: `user?.profile?.address?.city`.

## 4. Functions & Context (`this`)

- **Arrow Functions**: Use arrow functions for anonymous callbacks and when you want to inherit `this` lexically from the surrounding scope.
- **Standard Functions**: Use `function` declarations when you need a dynamic `this` context, or for top-level module exports to leverage hoisting for cleaner file structure.
- **Default Parameters**: Use default parameters instead of short-circuit evaluation. `function create(x = 10) {}`.
- **Rest & Spread (`...`)**: Use the rest operator `...args` instead of the legacy `arguments` object. Use the spread operator to immutably clone arrays or objects.

## 5. Closures & Memory Management

- **Encapsulation**: Use closures to create private state and factory functions. A closure gives you access to an outer function's scope from an inner function.
  ```javascript
  const createCounter = () => {
    let count = 0; // Private
    return () => ++count;
  };
  ```
- **Memory Leaks**: Be wary of accidental closures retaining large objects, uncleared `setInterval`s, detached DOM nodes referenced in JS, or global variables.
- **WeakMap & WeakSet**: Use these for caching or storing metadata on objects without preventing garbage collection.

## 6. Asynchronous Programming & The Event Loop

JavaScript is single-threaded. Blocking the main thread is a catastrophic failure.

- **The Event Loop**: Understand the Call Stack, Microtask Queue (Promises, MutationObserver), and Macrotask Queue (`setTimeout`, `setInterval`). Microtasks always execute before the next Macrotask.
- **Promises over Callbacks**: Avoid callback hell. Return and chain Promises.
- **Async/Await**: Prefer `async/await` for readable asynchronous control flow. 
- **Parallel Execution**: Do not `await` independent promises sequentially. Use `Promise.all()` or `Promise.allSettled()` to fire them in parallel.
  ```javascript
  // ✅ ALWAYS: Parallelize independent requests
  const [users, posts] = await Promise.all([fetchUsers(), fetchPosts()]);
  ```
- **Unhandled Rejections**: Always handle promise rejections. In `async` functions, wrap awaits in `try/catch` blocks.

## 7. Error Handling

- **Throw Custom Errors**: Subclass the native `Error` class to create domain-specific errors (`class ValidationError extends Error {}`).
- **Throw Objects, Not Strings**: Always `throw new Error('msg')`, never `throw 'msg'`. Only objects capture the stack trace.
- **Finally**: Use `try/catch/finally` to guarantee resource cleanup regardless of success or failure.

## 8. Objects, Arrays & Iterability

- **Destructuring**: Use object and array destructuring to extract values concisely.
- **Immutability**: Avoid mutating arrays (`push`, `pop`, `splice`). Prefer immutable methods (`map`, `filter`, `reduce`, `concat`, `slice`) or the spread operator.
- **Map & Set**: Use `Map` for key-value stores where keys are not strings/symbols or when order matters. Use `Set` to store unique primitive values or object references.

## 9. Classes & Prototypes

- **Prototypal Inheritance**: JavaScript uses prototypes, not classical inheritance. Classes are primarily syntactic sugar.
- **Composition over Inheritance**: Favor composing objects with small, focused behaviors over deep, brittle class inheritance chains.
- **Class Fields**: Use private class fields (`#privateVar`) to enforce encapsulation at the language level.

## 10. Modules (ESM)

- **Import/Export**: Use ES Modules (`import`/`export`) universally.
- **Named vs Default**: Prefer **Named Exports** over Default Exports. They enforce consistent naming across the codebase, improve IDE refactoring, and play better with tree-shaking.

## 11. Performance & Optimization

- **Debounce & Throttle**: Rate-limit expensive function calls (like window resize or scroll handlers).
- **RequestAnimationFrame**: Synchronize DOM manipulations with the browser's refresh rate using `requestAnimationFrame`, never `setTimeout`.
- **V8 Optimizations**: Initialize object properties in the same order to allow JS engines to reuse Hidden Classes. Avoid deleting properties (`delete obj.prop`); set them to `null` instead if necessary.

## 12. Naming Conventions

- **camelCase**: Variables, functions, methods, instances (`const userProfile = {}`).
- **PascalCase**: Classes, Constructors, React Components (`class DataService {}`).
- **UPPER_SNAKE_CASE**: Immutable, global, or deeply contextual magic constants (`const MAX_RETRY_COUNT = 3`).
- **Booleans**: Prefix boolean variables with `is`, `has`, `can`, or `should` (`const isVisible = true`).

---

**Execution Protocol**
1. **Linting**: Enforce rules strictly via ESLint (e.g., `eslint-config-airbnb` o `eslint-plugin-unicorn`).
2. **Type Safety**: While this covers pure JS, siempre aboga por TypeScript para capturar errores de ejecución en tiempo de compilación.
3. **Purity**: Esfuérzate por escribir funciones puras que no tengan efectos secundarios y devuelvan salidas consistentes para entradas consistentes.

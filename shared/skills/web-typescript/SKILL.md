---
name: web-typescript
description: The definitive architectural standard for writing strict, scalable, and type-safe TypeScript.
author: Diego Villanueva
trigger: When writing TypeScript code, defining data models, generics, utility types, or debugging type errors.
---

# TypeScript Engineering & Type-Safety Mastery

You are writing TypeScript, not JavaScript with hints. The type system is a powerful theorem prover. If your types are weak, your architecture is weak. Your goal is to make invalid states unrepresentable at compile time.

## 1. The Strictness Mandate

- **Strict Mode**: `tsconfig.json` must always have `"strict": true`.
- **Never Use `any`**: `any` disables the compiler. Use `unknown` for truly unknown data (like API payloads) and validate it at runtime, or use generics.
- **No Non-Null Assertions (`!`)**: Never use `obj!.prop`. If the compiler thinks it can be null, you must handle the null case explicitly in the logic.

## 2. Type vs Interface

- **Use `interface`**: For object shapes, class implementations, and public APIs. Interfaces are open and can be merged (Declaration Merging).
- **Use `type`**: For primitives, unions, intersections, tuples, mapped types, and complex generic utilities.

## 3. Discriminated Unions (State Machines)

Make invalid states unrepresentable. Never use optional flags to represent mutually exclusive states.

```typescript
// ❌ WRONG: A request can't be loading AND have an error AND have data.
interface RequestState<T> {
  isLoading?: boolean;
  error?: string;
  data?: T;
}

// ✅ ALWAYS: Discriminated Unions
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };
```

## 4. The Const Types Pattern (Dictionaries vs Enums)

TypeScript `enum`s compile to unpredictable JavaScript objects and behave strangely with numbers. 

```typescript
// ✅ ALWAYS: Create a const object first, then extract the type
const STATUS = {
  ACTIVE: "active",
  INACTIVE: "inactive",
  PENDING: "pending",
} as const; // Freezes the object deeply

type Status = (typeof STATUS)[keyof typeof STATUS]; // "active" | "inactive" | "pending"

// ❌ NEVER: Direct union types for business logic that requires runtime checks
// type Status = "active" | "inactive" | "pending"; // You can't loop over this!
```
*Why?* You get a single source of truth, runtime values (Object.values(STATUS)), autocomplete, and safe refactoring.

## 5. Flat Interfaces

Deeply nested objects make types impossible to extract and reuse.

```typescript
// ✅ ALWAYS: One level depth, nested objects → dedicated interface
interface UserAddress {
  street: string;
  city: string;
}

interface User {
  id: string;
  name: string;
  address: UserAddress;  // Reference, not inline
}

// ❌ NEVER: Inline nested objects
interface User {
  address: { street: string; city: string };  // How do I pass just the address to a function?
}
```

## 6. Type Guards & Asserts

When dealing with `unknown` data, you must prove its shape to the compiler.

```typescript
// Type Guard (Returns boolean, narrows type in true branch)
function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    "name" in value
  );
}

// Assertion Function (Throws if false, narrows type in rest of scope)
function assertIsUser(value: unknown): asserts value is User {
  if (!isUser(value)) {
    throw new Error("Value is not a User");
  }
}
```

## 7. Generics (The Right Way)

Generics make code reusable but can quickly become unreadable.
- **Meaningful Names**: Use `<T, U>` for simple functions, but use descriptive names `<TData, TError>` for complex ones.
- **Constraints**: Always constrain generics when possible using `extends`.

```typescript
// Restrict T to only types that have an 'id' string property
function extractIds<T extends { id: string }>(items: T[]): string[] {
  return items.map(item => item.id);
}
```

## 8. Utility Types (The Standard Library)

Master the built-in utility types before creating custom mapped types.

```typescript
Pick<User, "id" | "name">     // Creates a new type selecting only 'id' and 'name'
Omit<User, "id">              // Creates a new type excluding 'id'
Partial<User>                 // Makes all properties optional
Required<User>                // Makes all properties required
Readonly<User>                // Makes all properties readonly (shallow)
Record<string, User>          // Dictionary object { [key: string]: User }
Extract<Union, "a" | "b">     // Extract from union
Exclude<Union, "a">           // Exclude from union
NonNullable<T | null>         // Remove null/undefined from a union
ReturnType<typeof fn>         // Extracts the return type of a function
Parameters<typeof fn>         // Extracts the params tuple of a function
Awaited<Promise<string>>      // Unwraps a Promise (results in string)
```

## 9. Mapped & Conditional Types (Advanced)

For framework-level typing, you need mapped types.

```typescript
// Conditional Type: If T is string, return string, else return number
type StringOrNumber<T> = T extends string ? string : number;

// Mapped Type: Modify keys (e.g., prefix all keys with "get")
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
};
```

## 10. Imports & Exports

Always isolate type imports from runtime imports. This allows the bundler to strip them entirely.

```typescript
// ✅ ALWAYS
import type { User, Config } from "./types";
import { createUser } from "./utils";

// Or inline:
import { createUser, type Config } from "./utils";
```

## 11. Immutability & `readonly`

By default, objects and arrays in TypeScript are mutable. Force immutability where data should not change.

```typescript
// Readonly array
function printNames(names: readonly string[]) { ... }

// Readonly interface properties
interface Config {
  readonly apiUrl: string;
}
```

---

**Execution Protocol**
1. **Type Coverage**: The build must fail if strict mode violations are found.
2. **No `@ts-ignore`**: Never use `@ts-ignore`. If you must bypass the compiler, use `@ts-expect-error` and document *why*.
3. **Infer when possible**: Do not explicitly type things the compiler can infer natively (e.g., `const x: number = 5` is redundant, `const x = 5` is correct).
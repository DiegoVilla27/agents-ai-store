---
name: web-tsdoc
description: >
  TSDoc and API documentation standards for TypeScript projects.
  Trigger: When documenting functions, interfaces, classes, or complex types.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Core Documentation Tags (REQUIRED)

Professional documentation must address the WHAT, the HOW, and the "WHAT IF IT FAILS".

| Tag | Usage | Requirement |
|:---|:---|:---|
| @param | Describes an input parameter. | Mandatory if arguments exist. |
| @returns | Describes the return value. | Mandatory if not `void`. |
| @throws | Documents potential exceptions. | Critical for software robustness. |
| @example | Provides a real-world usage case. | High priority for AI agents. |
| @typeParam | Documents generic parameters <T>. | Mandatory for generics. |

## Standards & Best Practices

### 1. Documenting Generics
Never leave a generic parameter unexplained; its intent is often the most complex part of the abstraction.

```typescript
// ✅ ALWAYS
/**
 * Synchronizes local assets with the remote store.
 * @typeParam T - The type of asset being synchronized.
 * @param assets - Array of assets to process.
 */
export async function sync<T extends Asset>(assets: T[]): Promise<void> { ... }
```

### 2. Error Handling & Contracts
A function's contract is incomplete without documenting how it might fail.

```typescript
// ✅ ALWAYS
/**
 * Fetches a user from the API.
 * @param id - Unique identifier.
 * @returns The user object.
 * @throws {@link UnauthorizedError} If the authentication token is invalid.
 * @throws {@link NotFoundError} If the user does not exist in the database.
 */
export async function getUser(id: string): Promise<User> { ... }
```

### 3. Usage Examples
Examples must be syntactically correct and reflect real-world implementation patterns.

```typescript
// ✅ ALWAYS
/**
 * @example
 * ```typescript
 * const config = await loadConfig('production');
 * if (config.isReady) {
 *   await startServer(config.port);
 * }
 * ```
 */
```

### 4. Semantic Descriptions
Use @summary for short descriptions and @remarks for detailed technical implementation notes or side effects.

## Always / Never

```typescript
// ❌ NEVER: Vague or obvious comments
/** 
 * Sets the username.
 * @param name - The name.
 */
function setName(name: string) { ... }

// ✅ ALWAYS: Contextual and semantic documentation
/**
 * Updates the user's display name across the entire ecosystem.
 * @param name - The new sanitized name. Must be between 3-20 characters.
 * @remarks This action triggers a cache invalidation for the 'users' tag.
 */
function setName(name: string) { ... }
```

## Resources

- [TSDoc Official Website](https://tsdoc.org/)
- [Microsoft TSDoc Reference](https://github.com/microsoft/tsdoc)

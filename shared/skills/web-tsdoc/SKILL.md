---
name: web-tsdoc
description: The ultimate architectural standard for TSDoc and API documentation in enterprise TypeScript projects.
author: Diego Villanueva
trigger: When documenting functions, interfaces, classes, React components, complex types, or configuring API extractors.
---

# TSDoc & TypeScript Documentation Mastery

You are the author of the system's contract. Good code documents itself in terms of *what* it does, but TSDoc documents the *why*, the *how*, and the *edge cases*. In the age of AI coding assistants, robust TSDoc is the primary vector for providing context to agents, enabling them to use your code correctly without hallucinating.

## 1. The Core Philosophy

- **Never Repeat the Type System**: TypeScript already knows that `id` is a `string`. Your documentation should explain that `id` is a "UUID v4 representing the user's primary key", not just "the id string".
- **The Three Pillars of a Contract**: Every public API must explain: 
  1. What it does (Summary).
  2. What it requires (Parameters/Inputs).
  3. How it fails (Throws/Errors).
- **TSDoc != JSDoc**: We use the strict TSDoc standard. Do not use legacy JSDoc type annotations (e.g., `/** @param {string} id */`) because TypeScript handles the types natively.

## 2. Core Documentation Tags (REQUIRED)

| Tag | Usage | Requirement |
|:---|:---|:---|
| `@param <name> - <desc>` | Describes an input parameter. | Mandatory if arguments exist. |
| `@returns <desc>` | Describes the return value. | Mandatory if not `void`. |
| `@throws {<ErrorType>} <desc>`| Documents potential exceptions. | Critical for robust execution. |
| `@example` | Provides a real-world usage case. | **High priority for AI agents**. |
| `@typeParam <T> - <desc>` | Documents generic type parameters. | Mandatory for complex generics. |

## 3. Modifiers & Lifecycle Tags

Use these to define the visibility and stability of your APIs.

- **`@internal`**: The API is meant for internal use within the package/monorepo and should not be used by external consumers.
- **`@public`** / **`@alpha`** / **`@beta`**: Defines the release stage of the API.
- **`@deprecated`**: Marks an API as obsolete. **Always** include a message explaining what to use instead.

```typescript
/**
 * @deprecated Use {@link fetchUserById} instead. This function will be removed in v3.0.
 */
export function getUser() { ... }
```

## 4. The Anatomy of a Perfect Function Doc

```typescript
/**
 * Processes a financial transaction and updates the user's ledger.
 * 
 * @remarks
 * This function is not idempotent. Calling it twice will result in two separate
 * transactions being recorded. It relies on the global payment gateway.
 * 
 * @typeParam T - The specific currency payload type extending `BaseCurrency`.
 * 
 * @param transactionId - The unique UUIDv4 idempotency key for the request.
 * @param amount - The transaction amount in the smallest currency unit (e.g., cents).
 * 
 * @returns A promise resolving to the confirmed transaction receipt.
 * 
 * @throws {InsufficientFundsError} When the user's balance is below the amount.
 * @throws {GatewayTimeoutError} When the payment provider fails to respond in 5s.
 * 
 * @example
 * ```typescript
 * try {
 *   const receipt = await processTransaction('uuid-1234', 5000);
 *   console.log(receipt.status);
 * } catch (error) {
 *   if (error instanceof InsufficientFundsError) {
 *     // Handle empty wallet
 *   }
 * }
 * ```
 */
export async function processTransaction<T extends BaseCurrency>(
  transactionId: string, 
  amount: number
): Promise<Receipt> {
  // implementation...
}
```

## 5. Documenting Interfaces and Types

Interfaces define the shape of your data. The properties are often more important to document than the interface itself.

```typescript
/**
 * Represents a normalized user profile in the caching layer.
 */
export interface UserProfile {
  /**
   * The globally unique identifier (UUID v4).
   * @readonly
   */
  readonly id: string;

  /**
   * The user's preferred display name. 
   * Falls back to the email prefix if not provided during registration.
   */
  displayName: string;

  /**
   * The timestamp of their last successful login.
   * @remarks Can be null if the user has registered but never logged in.
   */
  lastLoginAt: Date | null;
}
```

## 6. Documenting React Components

When documenting React components, document the `Props` interface rather than the component function itself. IDEs will automatically surface the prop documentation when consumers use the component.

```typescript
/**
 * Props for the PrimaryButton component.
 */
export interface PrimaryButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /**
   * Shows a loading spinner and disables interaction.
   * @default false
   */
  isLoading?: boolean;

  /**
   * The visual variant of the button.
   * - `solid`: High emphasis, primary actions.
   * - `outline`: Medium emphasis, secondary actions.
   */
  variant?: 'solid' | 'outline';
}

/**
 * A highly accessible button component used for primary user actions.
 * 
 * @example
 * ```tsx
 * <PrimaryButton isLoading={true} variant="solid">
 *   Submit Order
 * </PrimaryButton>
 * ```
 */
export const PrimaryButton: React.FC<PrimaryButtonProps> = ({ 
  isLoading = false, 
  variant = 'solid', 
  ...props 
}) => {
  // implementation
}
```

## 7. Linking and Cross-Referencing

Help developers (and AI) navigate the codebase by linking related concepts.

- **`{@link Target}`**: Creates an inline link to another class, interface, or function.
- **`@see`**: Adds a "See also" reference block at the end of the documentation.

```typescript
/**
 * Refreshes the authentication token.
 * 
 * For detailed lifecycle rules, see {@link AuthService.login}.
 * 
 * @see {@link https://oauth.net/2/ OAuth 2.0 Specification}
 */
export async function refreshToken() { ... }
```

## 8. Avoid Common Anti-Patterns

### ❌ The "Echo" Anti-pattern
Do not write documentation that simply echoes the name and type.
```typescript
// ❌ ATROCIOUS
/**
 * The user id.
 * @param id - The id.
 * @returns The user.
 */
function getUser(id: string): User { ... }
```

### ❌ JSDoc Type Annotations
Never use `@param {Type}` in a TypeScript file.
```typescript
// ❌ WRONG
/**
 * @param {string} name - The name.
 */
function greet(name: string) { ... }

// ✅ CORRECT
/**
 * @param name - The name.
 */
function greet(name: string) { ... }
```

## 9. Formatting with Markdown

TSDoc fully supports Markdown inside the comment blocks.
- Use `**bold**` for emphasis.
- Use `` `backticks` `` for variable names and inline code.
- Use standard Markdown lists `- item` for bullet points.
- Use fenced code blocks ` ```typescript ... ``` ` inside `@example` tags.

---

**Execution Protocol**
1. **ESLint Integration**: Configure `eslint-plugin-tsdoc` to enforce strict TSDoc syntax parsing on CI.
2. **Mandatory Documentation**: Require TSDoc for all exported members (`@public` o `@internal`) in libraries or shared modules.
3. **AI Context Optimization**: When writing `@example` tags, assume an AI agent will use it to learn how to interact with your API. Make the examples robust and self-contained.

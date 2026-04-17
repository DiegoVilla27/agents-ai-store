---
description: 'React-specific coding standards and best practices for React 19 and Next.js'
applyTo: '**/*.tsx, **/*.ts, **/*.js, **/*.jsx, **/*.scss, **/*.css'
---

# React Development Instructions

Instructions for generating high-performance React applications using **React 19**, **TypeScript**, and modern architectural patterns.

## Project Context

- **Framework**: React 19 (React Compiler enabled)
- **Routing**: Next.js App Router (Server Components by default) or Vite (SPA)
- **Language**: TypeScript (Strict Mode)
- **Styling**: Tailwind CSS for utility-first styling
- **State Management**: Zustand (Client) & TanStack Query v5 (Server)

## Development Standards

### Architecture & Components

- **React Compiler**: **NEVER** use `useMemo` or `useCallback` manually. The compiler handles memoization automatically.
- **Server Components First**: Use Server Components (default) for data fetching and heavy logic. Use `"use client"` only for interactivity or browser APIs.
- **Modular Architecture (Vertical Slices)**: Organize code by features/screens. Each feature folder should contain its own assets:
  - `/features/[feature]/components/`
  - `/features/[feature]/hooks/`
  - `/features/[feature]/validations/`
  - `/features/[feature]/data/`
- **Index Pattern**: Use `index.ts` or `index.tsx` files within folders to keep imports clean.
  - *Example*: `import { Home } from './screens/home'` instead of `./screens/home/home-screen`.
- **File Naming**: Use **kebab-case** for folders and non-component files, and **PascalCase** for component names (or **kebab-case** for the file name itself if preferred, but always with an `index` export).

### TypeScript Patterns

- Use `interface` for component props and `type` for complex unions or intersections.
- Define strict types for all event handlers and API responses.
- Use Discriminated Unions for handling complex UI states (e.g., `Loading | Success | Error`).
- Avoid `any`. Use `unknown` with type guards if the type is truly dynamic.

### State Management (Zustand)

- **Selectors**: Always use selectors to extract specific state fields and prevent unnecessary re-renders.
  ```tsx
  const user = useUserStore((state) => state.user);
  ```
- **Shallow**: Use `useShallow` when selecting multiple primitive fields.
- **Immer**: Use the `immer` middleware for complex state mutations.
- **Slices**: Organize large stores into slices for better maintainability.

### Data Fetching (TanStack Query)

- **Custom Hooks**: Wrap all `useQuery` and `useMutation` calls in custom hooks (e.g., `use-user-data.ts`).
- **Object Syntax**: Always use the object-based syntax for `useQuery`.
- **Query Keys**: Use centralized query key factories to maintain consistency.
- **Optimistic Updates**: Implement `onMutate` for a premium, snappy user experience during mutations.

### UI & Styling

- **Tailwind CSS**: Use utility classes for all styling. Use the `cn()` utility (via `clsx` and `tailwind-merge`) for conditional classes.
- **Accessibility (a11y)**: Use semantic HTML and appropriate ARIA roles. Ensure keyboard navigability.
- **Icons**: Use `lucide-react` for consistent iconography.
- **Transitions**: Implement smooth micro-animations using CSS transitions or Framer Motion (if available).

### Forms & Validation

- Use **React 19 Actions** and the `useActionState` hook for form submissions.
- Leverage `useFormStatus` for handling "pending" states in nested components.
- Validate inputs using **Zod** or standard browser validation APIs.

### Testing

- Write unit tests using **Jest** and **React Testing Library**.
- Focus on testing user behavior rather than implementation details.
- Mock API calls using **MSW** (Mock Service Worker) for reliable integration tests.

## Implementation Workflow

1. **Plan Architecture**: Define Server vs Client component boundaries.
2. **Define Schema**: Create TypeScript interfaces and Zod schemas.
3. **Build UI**: Create atomic components with Tailwind CSS.
4. **Manage State**: Implement Zustand stores for global client state.
5. **Integrate APIs**: Scaffold TanStack Query hooks for server data.
6. **Add Logic**: Implement Actions and interactivity.
7. **Refine**: Add `@defer` equivalent logic (like Suspense) and optimizations.
8. **Verify**: Test accessibility and ensure performance benchmarks.

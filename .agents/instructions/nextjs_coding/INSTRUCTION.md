---
description: 'Next.js 15 App Router standards and vertical slicing'
applyTo: '**/*.tsx, **/*.ts, **/*.js, **/*.jsx'
---

# Next.js Development Instructions

Instructions for generating high-performance **Next.js 15** applications using the **App Router**, **Server Components**, and **Modern Architecture**.

## Project Context

- **Framework**: Next.js 15+ (App Router)
- **State Management**: Server Actions + TanStack Query (if needed) + Zustand
- **Architecture**: Vertical Slices with App Router conventions
- **Styling**: Tailwind CSS

## Development Standards

### Architecture & Routing

- **App Router Conventions**: Strict adherence to `page.tsx`, `layout.tsx`, `loading.tsx`, and `error.tsx`.
- **Modular Architecture (Vertical Slices)**: Keep assets close to the route they serve. Use private folders (starting with `_`) for assets that shouldn't be routed:
  - `app/(home)/_components/`: Local components.
  - `app/(home)/_hooks/`: Local hooks.
  - `app/(home)/_validations/`: Zod schemas or form logic.
- **Index Pattern**: Use `index.tsx` within component folders inside `_components/` or global `components/` to keep imports clean.
  - *Example*: `import { Button } from '@/components/button'` (where `button/index.tsx` exists).

### Server & Client Components

- **Server Components by Default**: All components are Server Components unless `"use client"` is explicitly required (Interactivity, Hooks, Browser APIs).
- **Server Actions**: Use `"use server"` for mutations. Centralize them in `actions.ts` within the feature folder or the root.
- **Streaming & Suspense**: Use `Suspense` with `loading.tsx` or manual boundaries for data-heavy components.
- **server-only**: Use the `import "server-only"` package to ensure sensitive logic stays on the server.

### UI & Styling

- **Tailwind CSS**: Utility-first styling with `cn()` for conditional classes.
- **Metadata**: Define static metadata in `layout.tsx` or dynamic metadata using `generateMetadata` in `page.tsx`.
- **Images**: Always use `next/image` with proper `priority` and `sizes` or `NgOptimizedImage` equivalents.

### Testing

- **Vitest**: Preferred for unit and component testing.
- **Playwright**: Preferred for end-to-end testing of routes and actions.

## Implementation Protocol

1. **Routing Strategy**: Layout the folder structure in `app/` using Groups `()` and Private folders `_`.
2. **Data Model**: Define TypeScript interfaces and Server Action signatures.
3. **Draft Components**: Start as Server Components; add `"use client"` only when necessary.
4. **Optimization**: Implement Suspense boundaries and metadata.
5. **Security**: Ensure `server-only` is applied to DB calls or sensitive utils.

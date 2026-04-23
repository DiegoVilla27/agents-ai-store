---
description: 'Advanced TypeScript Patterns for React and Next.js'
author: 'Diego Villanueva'
trigger: 'When defining complex prop types, generic components, or strictly-typed hooks.'
---

# Advanced TypeScript for React

Mastering the intersection of React and TypeScript for maximum safety.

## ✅ ALWAYS
- Use `interface` for Props and `type` for complex unions.
- Use `ComponentPropsWithoutRef<"button">` for extending native elements.
- Leverage **Generics** for reusable components (e.g., `List<T>`).
- Use `React.ReactNode` for children and `React.CSSProperties` for styles.
- Use `exhaustive-deps` equivalent check via `satisfies` or strict typing.

## ❌ NEVER
- Use `any` for props or state; use `unknown` if truly dynamic.
- Use `React.FC` or `React.FunctionComponent` (It's often considered redundant/legacy).
- Manually type event handlers; let TS infer them from the element.

## 🛠 Patterns
- **Polymorphic Components**: Components that can change their HTML tag via an `as` prop.
- **Discriminated Unions**: For handling complex component states (e.g., `type Status = Loading | Success | Error`).

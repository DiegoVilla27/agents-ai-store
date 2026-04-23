---
description: 'Schema-based Validation for React Hook Form'
author: 'Diego Villanueva'
trigger: 'When implementing Zod validation schemas within React Hook Form.'
---

# React Hook Form + Zod

Strictly-typed form validation using the Zod resolver.

## ✅ ALWAYS
- Use `zodResolver(schema)` from `@hookform/resolvers/zod`.
- Infer the form's TypeScript type from the Zod schema: `type FormSchema = z.infer<typeof schema>`.
- Use the inferred type in `useForm<FormSchema>({...})`.
- Define clear error messages within the Zod schema.
- Validate complex object structures and arrays using Zod's powerful API.

## ❌ NEVER
- Define types manually if you already have a Zod schema (Avoid duplication).
- Perform validation logic inside the `onSubmit` handler; let the resolver handle it.

## 🛠 Patterns
- **Conditional Validation**: Using `z.union` or `z.discriminatedUnion` for dynamic form fields.
- **Refinement**: Using `.refine()` for cross-field validation (e.g., password confirmation).

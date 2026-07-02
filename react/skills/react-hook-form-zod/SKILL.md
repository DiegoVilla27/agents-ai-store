---
name: react-hook-form-zod
description: The ultimate architectural standard for strict type-safe form validation, cross-field rules, and data transformation using React Hook Form and Zod.
author: Diego Villanueva
trigger: When configuring form validation, handling complex cross-field dependencies (like password confirmation), or extracting TypeScript types from schemas.
---

# Zod Validation Architecture for Forms

A form without strict validation is a security risk and a UX nightmare. A form with duplicated validation (one for TypeScript types, one for React Hook Form rules, one for the backend) is an unmaintainable mess. Zod solves this by providing a single, runtime-executable source of truth that also generates static TypeScript types.

## 1. The Single Source of Truth Paradigm

You must never define a TypeScript `interface` or `type` for a form manually if a Zod schema exists. The schema *is* the type.

```tsx
// ❌ ATROCIOUS: Duplicating types and schemas
interface UserForm { name: string; age: number; }
const schema = z.object({ name: z.string(), age: z.number() });

// ✅ ALWAYS: Infer types directly from the schema
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const userSchema = z.object({
  name: z.string().min(2, "Name is too short"),
  age: z.coerce.number().min(18, "Must be an adult")
});

type UserFormValues = z.infer<typeof userSchema>;

export function Form() {
  const { register, handleSubmit } = useForm<UserFormValues>({
    resolver: zodResolver(userSchema)
  });
}
```

## 2. Cross-Field Validation (The `.refine` Pattern)

React Hook Form's built-in validation struggles when one field depends on another (e.g., Password Confirmation, or ensuring an End Date comes after a Start Date). Zod handles this gracefully at the object level.

```tsx
// ✅ ALWAYS: Use object-level .refine for cross-field dependencies
const passwordSchema = z.object({
  password: z.string().min(8),
  confirmPassword: z.string()
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords do not match",
  path: ["confirmPassword"], // Highlights the exact field in RHF
});
```

## 3. Data Transformation (Type Coercion)

HTML inputs always return strings. If you have an `<input type="number">`, the DOM still returns `"18"`. Instead of manually parsing this in `onSubmit`, let Zod transform it during the validation phase.

- **`z.coerce`**: Coerces strings to primitives.
- **`.transform()`**: Run custom functions.

```tsx
// ✅ ALWAYS: Transform data at the schema boundary
const bookingSchema = z.object({
  // Automatically turns the string input into a real Number
  guests: z.coerce.number().min(1).max(10),
  
  // Converts standard YYYY-MM-DD strings into a real Date object
  checkInDate: z.string().transform((str) => new Date(str)),
  
  // Trims whitespace and enforces lowercase
  promoCode: z.string().trim().toLowerCase().optional()
});
```

## 4. Asynchronous Validation (e.g., Username Check)

You can run asynchronous checks during validation, such as verifying with the database if an email is already taken. RHF handles this seamlessly if the resolver returns a Promise.

```tsx
// ✅ ALWAYS: Async refinement for server-side checks
const usernameSchema = z.object({
  username: z.string().min(3)
}).refine(async (data) => {
  const response = await fetch(`/api/check-username?q=${data.username}`);
  const result = await response.json();
  return result.isAvailable;
}, {
  message: "Username is already taken",
  path: ["username"]
});
```

## 5. Discriminated Unions (Polymorphic Forms)

If you have a form where selecting "Business" shows a Tax ID field, but selecting "Personal" shows a SSN field, standard validation fails because it expects all fields to exist.

Use `z.discriminatedUnion` to validate completely different branches of fields based on a specific key (the discriminator).

```tsx
// ✅ ALWAYS: Discriminated Unions for dynamic forms
const accountSchema = z.discriminatedUnion("accountType", [
  z.object({
    accountType: z.literal("personal"),
    ssn: z.string().length(9, "Invalid SSN")
  }),
  z.object({
    accountType: z.literal("business"),
    companyName: z.string().min(1),
    taxId: z.string().min(5)
  })
]);

// If the user selects "business", Zod won't complain that "ssn" is missing!
```

---

**Execution Protocol**
1. **Never Validate in `onSubmit`**: If you find yourself writing `if (data.age < 18) throw Error()` inside your `onSubmit` handler, you have failed the architecture. All validation and transformation must happen in the Zod schema before `onSubmit` is even called.
2. **Global Error Maps**: Do not copy-paste standard error messages ("Required field", "Invalid email") into every single schema. Use `z.setErrorMap` globally to define your app's default localized error messages.
3. **Partial Validation (`.partial()`)**: When building "Draft" saving features or massive multi-step forms, use `mySchema.partial()` to validate only the fields that the user has filled out so far, avoiding throwing errors for incomplete pages.

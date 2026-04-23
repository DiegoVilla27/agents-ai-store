---
description: 'Performant and Flexible Form Management'
author: 'Diego Villanueva'
trigger: 'When building complex forms, multi-step wizards, or high-performance inputs.'
---

# React Hook Form

Mastery of form state management with minimal re-renders.

## ✅ ALWAYS
- Use `useForm` for primary form state.
- Use `register` for native HTML inputs and `Controller` for UI libraries (MUI, Shadcn).
- Leverage `useFieldArray` for dynamic list-based forms.
- Use `formState: { errors }` for real-time validation feedback.
- Use `mode: 'onChange'` or `'onBlur'` to control validation frequency.

## ❌ NEVER
- Use `useState` to manage every single input value; let RHF handle the uncontrolled state.
- Re-render the entire page on every keystroke; keep form state localized.
- Hardcode validation rules; use a schema-based approach (Zod).

## 🛠 Patterns
- **Deep Nesting**: Using `FormProvider` and `useFormContext` for complex nested forms.
- **Async Validation**: Implementing server-side validation checks within the form flow.

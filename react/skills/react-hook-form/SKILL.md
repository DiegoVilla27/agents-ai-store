---
name: react-hook-form
description: The ultimate architectural standard for building high-performance, strictly typed, and scalable forms in React using React Hook Form (RHF) and Zod.
author: Diego Villanueva
trigger: When building data entry forms, multi-step wizards, dynamic field arrays, or integrating form validation.
---

# React Hook Form Architecture

Forms are the most complex part of frontend development. Managing validation, touched states, dirty states, and dynamic arrays usually results in terrible performance and unmaintainable code. React Hook Form (RHF) solves this by using **uncontrolled components and refs** to bypass React's render cycle until absolutely necessary.

## 1. The Core Paradigm: Uncontrolled vs Controlled

Standard React forms use `useState` for every input, causing the entire form (and all its children) to re-render on every single keystroke. RHF is built on **uncontrolled inputs**. 

- **The `register` API**: Injects a `ref`, `onChange`, and `onBlur` directly into a native `<input>`. The input holds its own state, and RHF only extracts the value when the form is submitted or validation fails.

```tsx
// ❌ ATROCIOUS: React renders on every keystroke
const [name, setName] = useState('');
<input value={name} onChange={e => setName(e.target.value)} />

// ✅ ALWAYS: Uncontrolled rendering with RHF
const { register, handleSubmit } = useForm();
<input {...register('firstName')} />
```

## 2. Schema-Driven Validation (Zod)

Never write manual validation logic or use inline rules (like `{ required: true, minLength: 3 }`) for production applications. Forms must be backed by a strictly typed schema.

- **Zod Resolvers**: Use `@hookform/resolvers/zod`.
- **Type Inference**: Extract your TypeScript interfaces directly from the Zod schema. Never duplicate type definitions.

```tsx
// ✅ ALWAYS: Zod Schema as the Single Source of Truth
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const userSchema = z.object({
  email: z.string().email("Invalid email address"),
  age: z.number().min(18, "Must be an adult")
});

// Infer TypeScript type directly from Zod
type UserFormValues = z.infer<typeof userSchema>;

export function UserForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<UserFormValues>({
    resolver: zodResolver(userSchema)
  });

  const onSubmit = (data: UserFormValues) => {
    // data is fully typed and guaranteed valid here
    api.saveUser(data);
  };
}
```

## 3. Integrating Custom UI Libraries (`Controller`)

The `register` function only works with native HTML inputs that accept a `ref`. If you are using UI libraries (like Material UI, Ant Design, or complex Shadcn UI components like Select or DatePicker), you MUST use the `Controller` component.

```tsx
// ✅ ALWAYS: Use Controller for complex or controlled components
import { Controller, useForm } from "react-hook-form";
import DatePicker from "react-datepicker";

export function DateForm() {
  const { control } = useForm();

  return (
    <Controller
      control={control}
      name="birthDate"
      render={({ field: { onChange, onBlur, value, ref }, fieldState: { error } }) => (
        <>
          <DatePicker 
            onChange={onChange} // Send value into RHF
            onBlur={onBlur} // Notify RHF the field was touched
            selected={value} // Read value from RHF
            ref={ref}
          />
          {error && <span className="text-red-500">{error.message}</span>}
        </>
      )}
    />
  );
}
```

## 4. High-Performance Field Arrays

When building forms with dynamic lists (e.g., "Add another passenger", "Add another tag"), mapping over standard arrays and re-rendering is a performance killer.

- **`useFieldArray`**: Automatically handles adding, removing, swapping, and moving items in an array without re-rendering the entire form list.

```tsx
// ✅ ALWAYS: useFieldArray for dynamic lists
import { useForm, useFieldArray } from "react-hook-form";

export function PassengerList() {
  const { control, register } = useForm();
  const { fields, append, remove } = useFieldArray({
    control,
    name: "passengers"
  });

  return (
    <ul>
      {fields.map((item, index) => (
        <li key={item.id}> {/* MUST use item.id, not index */}
          <input {...register(`passengers.${index}.name`)} />
          <button type="button" onClick={() => remove(index)}>Remove</button>
        </li>
      ))}
      <button type="button" onClick={() => append({ name: "" })}>Add</button>
    </ul>
  );
}
```

## 5. Subscribing to Form State (`useWatch` vs `watch`)

If you need to show/hide a field based on the value of another field, you need to read the form state.

- **`watch('fieldName')`**: Triggers a re-render of the *entire component* where it is called whenever the field changes.
- **`useWatch({ name: 'fieldName' })`**: Triggers a re-render *only at the level of the component that calls the hook*. Use this to isolate re-renders in massive forms.

```tsx
// ✅ ALWAYS: Isolate re-renders for conditional fields
import { useWatch } from "react-hook-form";

function ConditionalTaxField({ control }) {
  // Only this tiny component re-renders when isBusiness changes
  const isBusiness = useWatch({ control, name: "isBusiness" });

  return isBusiness ? <input {...register("taxId")} /> : null;
}
```

## 6. Avoiding Prop Drilling (`FormProvider`)

For massive, multi-step forms (Wizards), passing `register` and `control` down 5 levels of components is an anti-pattern.

- **`FormProvider`**: Wrap your root form.
- **`useFormContext`**: Call this inside any deeply nested child to access the form methods instantly.

```tsx
// ✅ ALWAYS: FormContext for deep forms
import { useForm, FormProvider, useFormContext } from "react-hook-form";

function App() {
  const methods = useForm();
  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(onSubmit)}>
        <DeeplyNestedInput />
      </form>
    </FormProvider>
  );
}

function DeeplyNestedInput() {
  const { register } = useFormContext(); // Magic!
  return <input {...register("deepField")} />;
}
```

---

**Execution Protocol**
1. **Destructuring Re-renders**: RHF uses proxy objects for `formState` (e.g., `isValid`, `isDirty`, `errors`). If you do not destructure them or read them, RHF will not subscribe to them, saving re-renders. Do not read `isValid` if you don't actually need to disable a button.
2. **Default Values**: You MUST provide `defaultValues` in `useForm`. If you leave them undefined, React will throw uncontrolled-to-controlled component warnings.
3. **Resetting Forms**: Never manually clear inputs. Call `reset(newDefaultValues)` after a successful API submission to cleanly reset the form, touched states, and dirty states.

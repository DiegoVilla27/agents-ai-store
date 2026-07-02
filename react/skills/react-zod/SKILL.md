---
name: react-zod
description: The ultimate architectural standard for runtime validation, type coercion, and data transformation using Zod (v4).
author: Diego Villanueva
trigger: When validating API responses, parsing URL parameters, defining form schemas, or migrating to Zod 4.
---

# Zod Architecture (v4)

TypeScript is a lie at runtime. When you fetch data from an API or read a URL parameter, TypeScript assumes the data matches your `interface`, but if the API changes, your app crashes silently. Zod is the boundary layer that validates untrusted data at runtime and forces it to match your static types.

## 1. Zod 4 Breaking Changes (CRITICAL)

Zod 4 overhauled string-specific validators to be top-level functions and simplified error messages.

```typescript
import { z } from 'zod';

// ❌ NEVER (Zod 3 syntax - will crash in v4)
const oldEmail = z.string().email();
const oldRequired = z.object({ name: z.string() }).required_error("Required");
const oldNonEmpty = z.string().nonempty();

// ✅ ALWAYS (Zod 4 syntax)
const newEmail = z.email();
const newUuid = z.uuid();
const newUrl = z.url();
const newNonEmpty = z.string().min(1);

// Error mapping is now passed in the config object
const newRequired = z.object({ name: z.string() }, { error: "Name is required" });
```

## 2. The Single Source of Truth

Never write a TypeScript interface manually if a Zod schema exists for it.

```typescript
// ✅ ALWAYS: Infer the type from the schema
const UserSchema = z.object({
  id: z.uuid(),
  name: z.string().min(2),
  role: z.enum(["admin", "user"])
});

export type User = z.infer<typeof UserSchema>;
```

## 3. Safe Parsing (Defensive Programming)

If you use `.parse()`, Zod will throw an Error if validation fails. This crashes React if not caught.

- **External Data**: ALWAYS use `.safeParse()` for API responses, URL parameters, or localStorage. Handle the `success: false` case gracefully.

```typescript
// ✅ ALWAYS: Safe parsing for untrusted data
function loadSettings() {
  const rawData = localStorage.getItem('settings');
  const result = SettingsSchema.safeParse(JSON.parse(rawData || '{}'));

  if (!result.success) {
    console.error("Invalid settings, resetting to default", result.error.format());
    return defaultSettings;
  }

  return result.data; // Fully typed and validated
}
```

## 4. Coercion (URL Params & FormData)

Data coming from URLs (e.g., `?page=2`) or native `FormData` is ALWAYS a string. Do not parse it manually.

```typescript
// ✅ ALWAYS: Let Zod handle string coercion
const SearchParamsSchema = z.object({
  page: z.coerce.number().min(1).default(1),
  isActive: z.coerce.boolean().default(true)
});

// If URL has ?page=5, it becomes the number 5
const params = SearchParamsSchema.parse(Object.fromEntries(urlSearchParams));
```

## 5. Transformations (The Boundary Layer)

Sometimes the API sends data in a format you don't want to use in your UI (e.g., ISO strings instead of Date objects, or all-caps text).

- **`.transform()`**: Run the data through a function *during* validation. The inferred TypeScript type will automatically be the *output* of the transform.

```typescript
// ✅ ALWAYS: Transform data at the boundary
const EventSchema = z.object({
  title: z.string().trim(),
  // Input is string, Output is a Date object
  startDate: z.string().transform((val) => new Date(val)), 
});

type Event = z.infer<typeof EventSchema>; 
// Event.startDate is natively typed as Date!
```

## 6. Discriminated Unions (Polymorphic Data)

If an API returns different shapes of data based on a "type" field (e.g., an activity feed with "posts", "images", and "links"), standard `z.union()` is slow and has terrible TypeScript inference.

- **`z.discriminatedUnion`**: Orders of magnitude faster because it checks a single literal field to know which schema to apply.

```typescript
// ✅ ALWAYS: Use discriminatedUnion for polymorphic objects
const BlockSchema = z.discriminatedUnion("type", [
  z.object({ type: z.literal("text"), content: z.string() }),
  z.object({ type: z.literal("image"), url: z.url(), alt: z.string() })
]);

const block = BlockSchema.parse(data);
if (block.type === "text") {
  // TS knows 'content' exists, and 'url' does not!
  console.log(block.content); 
}
```

## 7. Refinements (Cross-field Validation)

When a validation rule depends on multiple fields in an object (e.g., `endDate` must be after `startDate`), you cannot validate the fields individually. You must refine the entire object.

```typescript
// ✅ ALWAYS: Use object-level refinements
const DateRangeSchema = z.object({
  start: z.coerce.date(),
  end: z.coerce.date()
}).refine(data => data.end > data.start, {
  message: "End date must be after start date",
  path: ["end"] // Attaches the error to the 'end' field specifically
});
```

---

**Execution Protocol**
1. **Never Trust the Backend**: The backend is an external system. Even if you share types via a monorepo, always pass the `fetch` response through a Zod `.safeParse()` before putting it in your global state or passing it to components.
2. **Partial Updates**: If you are sending a PATCH request or building a multi-step form, use `UserSchema.partial()` to make all properties temporarily optional while retaining their base validation rules.
3. **Catch-All for Objects**: By default, Zod strips out unrecognized keys from objects. If you absolutely need to retain them, use `.passthrough()`. If you want to strictly reject unknown keys (useful for config files), use `.strict()`.

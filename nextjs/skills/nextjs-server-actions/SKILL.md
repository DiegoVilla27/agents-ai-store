---
name: nextjs-server-actions
description: The ultimate architectural standard for native Server Actions, data mutations, React 19 hooks (useActionState), and cache revalidation in Next.js 15.
author: Diego Villanueva
trigger: When building native Server Actions, handling form submissions without libraries, implementing useOptimistic, or mutating data.
---

# Next.js Server Actions Architecture

Server Actions are the native replacement for traditional API endpoints (`pages/api`). They are RPC (Remote Procedure Call) functions executed on the backend but called directly from the frontend. 

**WARNING**: A Server Action is literally a public `POST` endpoint. If you do not validate the input and check user authentication inside the action, your application will be compromised.

## 1. Defining Server Actions (The Rules of Engagement)

Always define your actions in a separate file marked with `"use server"` at the very top. This ensures the entire file is compiled exclusively for the backend.

```typescript
// ✅ ALWAYS: Separate actions file (actions.ts)
"use server";

import { z } from "zod";
import { revalidateTag } from "next/cache";
import { auth } from "@/auth";

// 1. Zod Schema
const CreatePostSchema = z.object({
  title: z.string().min(3),
  content: z.string(),
});

// 2. Standardized Return Type
export type ActionState = {
  errors?: {
    title?: string[];
    content?: string[];
    _form?: string[];
  };
  message?: string | null;
};

// 3. The Action Signature (For useActionState)
export async function createPost(
  prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  // 4. Security Check
  const session = await auth();
  if (!session?.user) {
    return { errors: { _form: ["Unauthorized"] } };
  }

  // 5. Validation
  const validatedFields = CreatePostSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
  });

  if (!validatedFields.success) {
    return { errors: validatedFields.error.flatten().fieldErrors };
  }

  // 6. Execution and Error Handling
  try {
    await db.post.create({ data: validatedFields.data });
  } catch (error) {
    return { errors: { _form: ["Failed to create post. Please try again."] } };
  }

  // 7. Cache Revalidation (Crucial!)
  revalidateTag("posts-list");
  
  return { message: "Post created successfully" };
}
```

## 2. React 19 Forms (`useActionState`)

Never use `useState`, `useEffect`, or `onSubmit={async (e) => ...}` for standard form submissions. React 19 introduces `useActionState` (formerly `useFormState`), which perfectly marries Server Actions to Client Components.

```tsx
// ✅ ALWAYS: useActionState for form handling
"use client";
import { useActionState } from "react";
import { createPost } from "./actions";
import { SubmitButton } from "./SubmitButton";

export function PostForm() {
  // state holds the return value of the action (errors and messages)
  const [state, formAction, isPending] = useActionState(createPost, {});

  return (
    <form action={formAction}>
      <div>
        <input name="title" />
        {state.errors?.title && <p className="text-red-500">{state.errors.title}</p>}
      </div>
      
      <div>
        <textarea name="content" />
        {state.errors?.content && <p className="text-red-500">{state.errors.content}</p>}
      </div>

      {state.errors?._form && <p className="text-red-500">{state.errors._form}</p>}
      {state.message && <p className="text-green-500">{state.message}</p>}

      <button disabled={isExecuting}>
        {isExecuting ? "Saving..." : "Save"}
      </button>
    </form>
  );
}
```

## 3. Invoking Actions Outside of Forms

You can call a Server Action just like a normal async function from an `onClick`, `onChange`, or `useEffect`. However, you must manage the loading state manually or use the `useTransition` hook.

```tsx
// ✅ ALWAYS: useTransition for non-form action invocations
"use client";
import { useTransition } from "react";
import { deletePost } from "./actions";

export function DeleteButton({ id }: { id: string }) {
  const [isPending, startTransition] = useTransition();

  const handleDelete = () => {
    startTransition(async () => {
      const result = await deletePost(id);
      if (result.error) alert(result.error);
    });
  };

  return (
    <button onClick={handleDelete} disabled={isPending}>
      {isPending ? "Deleting..." : "Delete"}
    </button>
  );
}
```

## 4. Optimistic UI (`useOptimistic`)

If your action takes 1 second, the UI shouldn't freeze. React 19's `useOptimistic` hook allows you to mutate the state instantly, and it automatically rolls back if the Server Action fails.

```tsx
// ✅ ALWAYS: useOptimistic for instant UI feedback
"use client";
import { useOptimistic, useTransition } from "react";
import { toggleLike } from "./actions";

export function LikeButton({ post }) {
  const [isPending, startTransition] = useTransition();
  
  // Define optimistic state
  const [optimisticLikes, addOptimisticLike] = useOptimistic(
    post.likes,
    (state, amount: number) => state + amount
  );

  const handleLike = () => {
    startTransition(async () => {
      // 1. Instantly update UI (no waiting for server)
      addOptimisticLike(1); 
      
      // 2. Fire the server action in the background
      await toggleLike(post.id); 
      // If it fails, React automatically rolls back optimisticLikes!
    });
  };

  return (
    <button onClick={handleLike} disabled={isPending}>
      Likes: {optimisticLikes}
    </button>
  );
}
```

---

**Execution Protocol**
1. **Never throw errors to the client**: If your Server Action `throw new Error("DB Connection failed")`, Next.js will crash the client-side boundary. ALWAYS `try/catch` and return an object with the error message so the UI can display it gracefully.
2. **Revalidation**: You MUST call `revalidatePath` or `revalidateTag` at the end of your action if the mutation changes data that is currently cached on the screen. If you don't, the user will submit the form but the old data will still be visible.
3. **Security Context**: The `req` object is not available in Server Actions. To get the user IP or Headers, you must use `headers()` from `next/headers`. To get cookies, use `cookies()`.

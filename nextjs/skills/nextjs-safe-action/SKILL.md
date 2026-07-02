---
name: nextjs-safe-action
description: The ultimate architectural standard for secure, validated, and type-safe Server Actions using next-safe-action and Zod in Next.js 15.
author: Diego Villanueva
trigger: When building Server Actions, handling form submissions, validating inputs, or implementing authenticated mutations.
---

# Next Safe Action Architecture

Raw Server Actions in Next.js are inherently insecure. They are public API endpoints disguised as functions. If you do not validate the input and check authentication on *every single one*, your app will be hacked. 

`next-safe-action` is the enterprise standard for wrapping Server Actions in strict Zod validation, injecting authentication middleware, and returning standardized error objects.

## 1. The Global Action Clients (`lib/safe-action.ts`)

You must NEVER define an action from a blank slate. You must define a base `actionClient` that handles global errors (to prevent leaking DB errors to the client), and an `authActionClient` that guarantees the user is logged in.

```typescript
// ✅ ALWAYS: Define standard Action Clients
import { createSafeActionClient } from "next-safe-action";
import { auth } from "@/auth"; // Your auth provider

// 1. The Base Client (Public Actions)
export const actionClient = createSafeActionClient({
  // Global Error Handler: Never leak raw errors to the client
  handleReturnedServerError(e) {
    if (e instanceof CustomError) return e.message;
    return "An unexpected internal error occurred.";
  },
});

// 2. The Authenticated Client (Protected Actions)
export const authActionClient = actionClient.use(async ({ next }) => {
  const session = await auth();
  
  if (!session?.user?.id) {
    throw new Error("Unauthorized");
  }

  // Inject the user ID into the action context (ctx)
  return next({ ctx: { userId: session.user.id } });
});
```

## 2. Defining a Secure Action

Actions must always be placed in a file marked with `"use server"`. Use your pre-configured clients to enforce Zod validation.

```typescript
// ✅ ALWAYS: Use Zod schemas and the auth client
"use server";
import { z } from "zod";
import { authActionClient } from "@/lib/safe-action";
import { db } from "@/lib/db";
import { revalidatePath } from "next/cache";

const CreatePostSchema = z.object({
  title: z.string().min(3, "Title is too short"),
  content: z.string(),
});

export const createPostAction = authActionClient
  .schema(CreatePostSchema)
  .action(async ({ parsedInput, ctx }) => {
    // 1. parsedInput is fully typed and validated by Zod!
    // 2. ctx.userId is guaranteed to exist by the middleware!
    
    const post = await db.post.create({
      data: {
        ...parsedInput,
        authorId: ctx.userId, 
      },
    });

    revalidatePath("/posts");
    
    // 3. Return structured data
    return { success: true, post };
  });
```

## 3. Consuming Actions in Client Components (`useAction`)

Do not call the action function directly in an `onClick` or `onSubmit` unless you want to manually manage try/catch blocks and loading states. Use the `useAction` hook.

```tsx
// ✅ ALWAYS: Use the hook for automatic state management
"use client";
import { useAction } from "next-safe-action/hooks";
import { createPostAction } from "./actions";
import { toast } from "sonner";

export function PostForm() {
  const { execute, isExecuting, result } = useAction(createPostAction, {
    onSuccess: (data) => {
      toast.success("Post created!");
    },
    onError: ({ error }) => {
      if (error.serverError) toast.error(error.serverError);
      if (error.validationErrors) toast.error("Invalid form data");
    },
  });

  return (
    <form action={(formData) => {
      // Execute the action with the raw FormData, next-safe-action handles the rest
      execute({ 
        title: formData.get("title") as string, 
        content: formData.get("content") as string 
      });
    }}>
      <input name="title" />
      <textarea name="content" />
      <button disabled={isExecuting}>
        {isExecuting ? "Saving..." : "Save"}
      </button>
      
      {/* Inline validation errors */}
      {result.validationErrors?.title && (
        <p className="text-red-500">{result.validationErrors.title[0]}</p>
      )}
    </form>
  );
}
```

## 4. Optimistic UI (`useOptimisticAction`)

For operations like "Liking" a post, you cannot wait 500ms for the Server Action to finish before updating the heart icon to red. You must use optimistic updates.

```tsx
// ✅ ALWAYS: Optimistic updates for instantaneous feedback
"use client";
import { useOptimisticAction } from "next-safe-action/hooks";
import { likePostAction } from "./actions";

export function LikeButton({ post }) {
  const { execute, optimisticState } = useOptimisticAction(
    likePostAction,
    { likes: post.likes }, // Initial state
    (state, input) => {
      // Optimistic state mutation (runs immediately)
      return { likes: state.likes + 1 };
    }
  );

  return (
    <button onClick={() => execute({ postId: post.id })}>
      Likes: {optimisticState.likes}
    </button>
  );
}
```

---

**Execution Protocol**
1. **Never trust the Client**: Just because a button is hidden on the frontend doesn't mean a user can't trigger the Server Action via the console. The action itself MUST verify permissions.
2. **Action Modularity**: Keep your Server Actions small. If an action becomes complex, move the business logic into a separate Service/DAL file and call that service from the action. Server Actions are Controllers, not Services.
3. **Form Integration**: If you are using React Hook Form, you can seamlessly pass the `handleSubmit` data directly into the `execute` function. They share the same Zod schema!

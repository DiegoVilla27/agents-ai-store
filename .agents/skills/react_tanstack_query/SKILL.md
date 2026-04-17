---
name: react-tanstack-query
description: >
  Server state management for React and Next.js (TanStack Query v5).
  Trigger: When fetching data from an API, managing server state, or implementing caching and optimistic updates.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Query Basics (REQUIRED)

Manage asynchronous state with automatic caching and background updates.

```typescript
// ✅ ALWAYS: Use object-based syntax and functional queryFn
const { data, isLoading } = useQuery({
  queryKey: ["users", userId],
  queryFn: () => fetchUser(userId),
  staleTime: 1000 * 60 * 5, // 5 minutes
});

// ❌ NEVER: String query keys or manual loading states
// Do not use global loading variables; rely on useQuery status.
```

---

## Mutations & Optimistic Updates (REQUIRED)

```typescript
// ✅ ALWAYS: Handle success, error, and settle for cache sync
const mutation = useMutation({
  mutationFn: updateUser,
  onMutate: async (newUser) => {
    await queryClient.cancelQueries({ queryKey: ["users"] });
    const previous = queryClient.getQueryData(["users"]);
    queryClient.setQueryData(["users"], (old) => [...old, newUser]);
    return { previous };
  },
  onError: (err, newUser, context) => {
    queryClient.setQueryData(["users"], context.previous);
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ["users"] });
  },
});
```

---

## Cache Configuration (v5 Patterns)

| Setting | Recommendation |
|---------|----------------|
| **staleTime** | Set higher for data that doesn't change frequently. |
| **gcTime** | (Formerly cacheTime) How long to keep inactive data. |
| **retry** | 1 or 2 for production; avoid infinite retries. |

---

## Execution Protocol (REQUIRED)

1. **Define Keys**: Use a factory or centralized object for `queryKeys`.
2. **Abstract**: Wrap queries/mutations in custom hooks (e.g., `useUserQuery`).
3. **Handle States**: Always handle `isLoading`, `isError`, and `isFetching`.
4. **Invalidate**: Intelligently invalidate related keys after a mutation.

---

## Uncompromising Constraints

- **Single Source of Truth**: Never sync Query data into a local `useState` or `Zustand` store.
- **Error Boundaries**: Use `throwOnError` property for global error handling in React.
- **Client Components**: Remember that `useQuery` only works in "use client" components in Next.js.

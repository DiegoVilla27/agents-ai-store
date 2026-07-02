---
name: react-tanstack-query
description: The ultimate architectural standard for Server State Management, Caching, and Optimistic Updates using TanStack Query v5.
author: Diego Villanueva
trigger: When fetching data from an API, managing server state, implementing caching, or dealing with loading/error states for remote data.
---

# TanStack Query (v5) Architecture

TanStack Query (formerly React Query) is not a data fetching library (it doesn't care if you use `fetch`, `axios`, or GraphQL). It is an **Asynchronous Server State Management Engine**. 

You must draw a strict line between **Client State** (UI toggles, form inputs managed by Zustand/Context) and **Server State** (data that lives on a remote server, is asynchronous, and is shared among multiple users). TanStack Query handles the latter.

## 1. The Query Key Factory (CRITICAL)

Query keys uniquely identify your cache entries. In v5, keys MUST be arrays. 

- **The Anti-Pattern**: Scattering random arrays like `['user', 1]` and `['user', 'details', 1]` throughout your codebase makes cache invalidation impossible to maintain.
- **The Solution**: Use a Query Key Factory. A single, centralized object that defines every query key structure in the app.

```tsx
// ✅ ALWAYS: Centralized Query Key Factory
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (filters: string) => [...userKeys.lists(), { filters }] as const,
  details: () => [...userKeys.all, 'detail'] as const,
  detail: (id: number) => [...userKeys.details(), id] as const,
};

// Usage
useQuery({ queryKey: userKeys.detail(userId), queryFn: () => fetchUser(userId) });

// Invalidation (Invalidates ALL user lists, but leaves details alone)
queryClient.invalidateQueries({ queryKey: userKeys.lists() });
```

## 2. `staleTime` vs `gcTime` (The Most Misunderstood Concept)

- **`staleTime` (Default 0)**: The duration data is considered fresh. If data is fresh, it comes strictly from the cache. If it is stale, it comes from the cache *but* a background refetch is triggered.
- **`gcTime` (formerly `cacheTime`, Default 5 mins)**: How long inactive data stays in memory.

**Rule**: By default, data is instantly stale. If the user tabs away and back, it refetches. You MUST set a global `staleTime` (e.g., 20 seconds) in your `QueryClient` provider to avoid spamming your backend on every window focus.

```tsx
// ✅ ALWAYS: Set a sensible global staleTime
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 20, // 20 seconds
      refetchOnWindowFocus: true, // Only fires if stale
      retry: 2,
    },
  },
});
```

## 3. The Custom Hook Rule

NEVER use `useQuery` or `useMutation` directly inside a UI component. 

- **Why?** It mixes UI rendering logic with data fetching logic. If the endpoint changes or you need to update the `staleTime`, you'll have to hunt down the component.
- **Always** extract them into custom hooks.

```tsx
// ✅ ALWAYS: Extract to custom hooks
export function useUser(userId: number) {
  return useQuery({
    queryKey: userKeys.detail(userId),
    queryFn: () => fetchUser(userId),
    enabled: !!userId, // Dependent query: Won't run until userId exists
  });
}

// In the component:
const { data: user, isLoading } = useUser(1);
```

## 4. Optimistic Updates (The Illusion of Speed)

When a user likes a post, the heart should turn red instantly. Do not wait for the server response.

An optimistic update requires 4 strict steps:
1. `onMutate`: Cancel outgoing refetches, save a snapshot of the current cache, and forcibly update the cache with the new fake data.
2. `onError`: If the mutation fails, rollback the cache using the snapshot.
3. `onSettled`: Regardless of success or failure, invalidate the query to sync with the real server state.

```tsx
// ✅ ALWAYS: Bulletproof Optimistic Updates
export function useLikePost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (postId: string) => api.likePost(postId),
    onMutate: async (postId) => {
      // 1. Cancel any outgoing refetches (so they don't overwrite our optimistic update)
      await queryClient.cancelQueries({ queryKey: postKeys.detail(postId) });

      // 2. Snapshot the previous value
      const previousPost = queryClient.getQueryData(postKeys.detail(postId));

      // 3. Optimistically update to the new value
      queryClient.setQueryData(postKeys.detail(postId), (old: any) => ({
        ...old,
        likes: old.likes + 1,
      }));

      // Return context with the snapshot for rollback
      return { previousPost };
    },
    onError: (err, postId, context) => {
      // 4. Rollback on error
      queryClient.setQueryData(postKeys.detail(postId), context?.previousPost);
    },
    onSettled: (data, error, postId) => {
      // 5. Invalidate to ensure sync
      queryClient.invalidateQueries({ queryKey: postKeys.detail(postId) });
    },
  });
}
```

## 5. Prefetching (Eliminating Loading Spinners)

If you know a user is highly likely to click a link (e.g., hovering over a user profile card), fetch the data *before* they click it.

```tsx
// ✅ ALWAYS: Prefetch on hover
function UserCard({ userId }) {
  const queryClient = useQueryClient();

  const prefetch = () => {
    queryClient.prefetchQuery({
      queryKey: userKeys.detail(userId),
      queryFn: () => fetchUser(userId),
      staleTime: 1000 * 60, // Don't refetch if prefetched recently
    });
  };

  return <div onMouseEnter={prefetch}>...</div>;
}
```

## 6. Polling (Live Data)

For dashboards or live feeds, you don't need WebSockets. You just need `refetchInterval`.

```tsx
// ✅ ALWAYS: Pause polling when the window is in the background
useQuery({
  queryKey: ['live-feed'],
  queryFn: fetchFeed,
  refetchInterval: 5000,
  refetchIntervalInBackground: false, // Don't drain the user's battery
});
```

---

**Execution Protocol**
1. **Object Syntax Only (v5)**: TanStack Query v5 strictly requires object syntax `useQuery({ queryKey, queryFn })`. The legacy `useQuery(key, fn)` signature is dead and will crash the app.
2. **Never store server data in `useState`**: This is the worst anti-pattern. `const [users, setUsers] = useState([]); useEffect(() => { fetch().then(setUsers) })` must be eradicated from the codebase and replaced with `useQuery`.
3. **Suspense**: If using React 18+ Suspense boundaries, use the new `useSuspenseQuery` hook instead of `useQuery`. It guarantees `data` is defined and eliminates the need for `if (isLoading)` checks inside the component.

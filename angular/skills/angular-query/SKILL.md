---
name: angular-query
description: The ultimate architectural standard for TanStack Angular Query injectQuery, injectMutation, Cache Invalidation, Query Keys, and Optimistic Updates.
author: Diego Villanueva
trigger: When fetching data from APIs, managing server state, implementing caching, or writing mutations (POST/PUT/DELETE).
---

# Enterprise Angular Query Architecture (TanStack)

The biggest mistake in frontend architecture is treating **Server State** (Data living on the backend) as **Client State** (UI toggles, forms). 

**❌ NEVER** use Redux/NgRx or massive `BehaviorSubject` stores to cache API responses. 
**✅ ALWAYS** use `@tanstack/angular-query-experimental` to manage Server State. It handles caching, background refetching, and deduplication automatically, exposing the data as Angular Signals.

## 1. Global Configuration

You must provide the QueryClient globally in `app.config.ts`. By default, TanStack Query refetches data aggressively. You MUST set a reasonable `staleTime`.

```typescript
// ✅ ALWAYS: Configure the QueryClient with sane defaults
import { provideAngularQuery, QueryClient } from '@tanstack/angular-query-experimental';

export const appConfig = {
  providers: [
    provideAngularQuery(new QueryClient({
      defaultOptions: {
        queries: {
          // Data is considered "fresh" for 30 seconds. No background refetching will occur.
          staleTime: 1000 * 30, 
          // Keep unused data in RAM for 5 minutes before garbage collecting it
          gcTime: 1000 * 60 * 5, 
          // Retry failed requests twice before showing an error
          retry: 2, 
          // Do not refetch when the user switches browser tabs (unless strictly necessary)
          refetchOnWindowFocus: false, 
        },
      },
    }))
  ]
};
```

## 2. Fetching Data (`injectQuery`)

To fetch data, wrap your `HttpClient` call in an `injectQuery`.

**CRITICAL RULE (Query Keys)**: The `queryKey` is how the cache identifies the data. It MUST be an array. It MUST be hierarchical. If your query depends on a variable (like an ID), that variable MUST be in the `queryKey`.

```typescript
// ✅ ALWAYS: Use injectQuery to fetch data and return Signals
import { Component, input, inject } from '@angular/core';
import { injectQuery } from '@tanstack/angular-query-experimental';
import { HttpClient } from '@angular/common/http';
import { lastValueFrom } from 'rxjs';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  template: `
    @if (userQuery.isPending()) {
      <spinner />
    } @else if (userQuery.isError()) {
      <error-msg [error]="userQuery.error()" />
    } @else if (userQuery.data(); as user) {
      <h1>{{ user.name }}</h1>
    }
  `
})
export class UserProfileComponent {
  private readonly http = inject(HttpClient);
  readonly userId = input.required<number>(); // Signal input

  // The query automatically re-runs if the 'userId' signal changes!
  readonly userQuery = injectQuery(() => ({
    queryKey: ['users', 'detail', this.userId()], // Array structure is MANDATORY
    queryFn: () => lastValueFrom(this.http.get<User>(`/api/users/${this.userId()}`))
  }));
}
```
*(Note: TanStack Query expects Promises, so we convert the RxJS Observable using `lastValueFrom`).*

## 3. Mutating Data (`injectMutation`)

When you create, update, or delete data on the server, you use a Mutation.

```typescript
// ✅ ALWAYS: Use injectMutation for POST/PUT/DELETE
import { injectMutation, injectQueryClient } from '@tanstack/angular-query-experimental';

export class CreateUserComponent {
  private readonly http = inject(HttpClient);
  private readonly queryClient = injectQueryClient();

  readonly createUserMutation = injectMutation(() => ({
    mutationFn: (newUser: Omit<User, 'id'>) => {
      return lastValueFrom(this.http.post<User>('/api/users', newUser));
    },
    // When the mutation succeeds, the cache for the user list is now stale!
    onSuccess: () => {
      // ✅ ALWAYS: Invalidate the cache to force a background refetch
      this.queryClient.invalidateQueries({ queryKey: ['users', 'list'] });
    },
    onError: (error) => {
      console.error('Failed to create user', error);
    }
  }));

  onSubmit(formValue: any) {
    // Calling .mutate() executes the HTTP request
    this.createUserMutation.mutate(formValue);
  }
}
```
*(Template usage: `<button [disabled]="createUserMutation.isPending()">Save</button>`)*

## 4. Optimistic Updates (Premium UX)

If a user "Likes" a post, they shouldn't have to wait 500ms for the HTTP request to finish to see the heart icon turn red. The UI should update instantly. If the HTTP request fails, it should roll back.

**✅ ALWAYS** use Optimistic Updates for high-frequency micro-interactions.

```typescript
export class LikeButtonComponent {
  private readonly queryClient = injectQueryClient();
  readonly postId = input.required<number>();

  readonly toggleLike = injectMutation(() => ({
    mutationFn: (postId: number) => lastValueFrom(this.http.post(`/api/posts/${postId}/like`, {})),
    
    // 1. Triggered immediately when mutate() is called (before network request finishes)
    onMutate: async (postId) => {
      // Cancel any outgoing refetches so they don't overwrite our optimistic update
      await this.queryClient.cancelQueries({ queryKey: ['posts', postId] });

      // Snapshot the previous value for rollback
      const previousPost = this.queryClient.getQueryData<Post>(['posts', postId]);

      // Optimistically update to the new value in the local cache
      if (previousPost) {
        this.queryClient.setQueryData<Post>(['posts', postId], {
          ...previousPost,
          liked: !previousPost.liked,
          likesCount: previousPost.liked ? previousPost.likesCount - 1 : previousPost.likesCount + 1
        });
      }

      // Return context for rollback
      return { previousPost };
    },

    // 2. If the mutation fails, roll back to the snapshot
    onError: (err, newTodo, context) => {
      this.queryClient.setQueryData(['posts', this.postId()], context?.previousPost);
    },

    // 3. Always refetch after error or success to ensure 100% sync with backend
    onSettled: () => {
      this.queryClient.invalidateQueries({ queryKey: ['posts', this.postId()] });
    }
  }));
}
```

---

**Execution Protocol**
1. **Query Factories**: Do not hardcode query keys (`['users', 'list']`) across 20 different files. Create a centralized `queryKeys.ts` file with factory functions: `export const userKeys = { all: ['users'] as const, lists: () => [...userKeys.all, 'list'] as const };`. This prevents devastating typos when calling `invalidateQueries`.
2. **Dependent Queries**: If Query B requires the ID from Query A, set `enabled: !!queryA.data()?.id` in Query B's options. It will not fire until the condition is met.
3. **Stale vs Inactive**: `staleTime` determines when data needs to be refetched from the network. `gcTime` (Garbage Collection Time) determines when data that is currently *not visible on the screen* is completely deleted from RAM.

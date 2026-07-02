---
name: ngrx-signal-store
description: The ultimate architectural standard for Enterprise Angular State NgRx SignalStore, rxMethod, withEntities, tapResponse, and Custom Features.
author: Diego Villanueva
trigger: When managing complex component state, replacing Redux/NgRx Global Store, or handling Entity CRUD operations.
---

# Enterprise NgRx SignalStore Architecture

The traditional NgRx Global Store (Redux pattern with massive switch statements, Actions, Reducers, and Effects) is widely considered legacy for modern Angular applications. It introduces too much boilerplate.

**✅ ALWAYS** use `@ngrx/signals` (SignalStore) for state management. It provides a highly opinionated, functional, and fully Signal-driven architecture that is vastly superior to Redux.

## 1. The Core Architecture: `signalStore`

A SignalStore is built by chaining features (`withState`, `withComputed`, `withMethods`). 

**❌ NEVER** mutate state outside of the store.
**✅ ALWAYS** encapsulate state mutations inside `withMethods` using the `patchState` function.

```typescript
import { computed, inject } from '@angular/core';
import { signalStore, withState, withComputed, withMethods, patchState } from '@ngrx/signals';

interface UserState {
  users: User[];
  isLoading: boolean;
  filter: string;
}

const initialState: UserState = {
  users: [],
  isLoading: false,
  filter: ''
};

// ✅ ALWAYS: Export the Store class. It acts as an Injectable service!
export const UserStore = signalStore(
  { providedIn: 'root' }, // Make it Global (Or omit this to make it Component-scoped!)

  // 1. STATE (The data)
  withState(initialState),

  // 2. COMPUTED (The "Selectors")
  withComputed((store) => ({
    filteredUsers: computed(() => {
      const filter = store.filter().toLowerCase();
      return store.users().filter(u => u.name.toLowerCase().includes(filter));
    }),
    userCount: computed(() => store.users().length)
  })),

  // 3. METHODS (The "Actions" & "Reducers" combined)
  withMethods((store) => ({
    setFilter(query: string) {
      // patchState merges the new object into the existing state
      patchState(store, { filter: query }); 
    },
    clearUsers() {
      patchState(store, { users: [] });
    }
  }))
);
```

## 2. Asynchronous Logic (`rxMethod` & `tapResponse`)

When a method needs to make an HTTP request, you must bridge the Signal world with the RxJS world. 

**❌ NEVER** subscribe to HTTP calls manually inside `withMethods`. If an HTTP call fails, it will kill the RxJS stream, and the method will never work again.
**✅ ALWAYS** use `rxMethod` combined with `tapResponse` (which safely catches errors without killing the stream).

```typescript
import { rxMethod } from '@ngrx/signals/rxjs-interop';
import { tapResponse } from '@ngrx/operators';
import { pipe, switchMap, tap } from 'rxjs';

export const UserStore = signalStore(
  withState(initialState),
  withMethods((store, http = inject(HttpClient)) => ({
    
    // rxMethod takes a stream of inputs (string, signal, or observable)
    loadUsersByQuery: rxMethod<string>(
      pipe(
        tap(() => patchState(store, { isLoading: true })), // 1. Set loading
        switchMap((query) => {
          // 2. Make the HTTP Request
          return http.get<User[]>(`/api/users?q=${query}`).pipe(
            // 3. ✅ ALWAYS use tapResponse for safe handling
            tapResponse({
              next: (users) => patchState(store, { users, isLoading: false }),
              error: (err) => {
                console.error(err);
                patchState(store, { isLoading: false });
              }
            })
          );
        })
      )
    )

  }))
);
```
*(Usage in component: `this.store.loadUsersByQuery('diego');` OR pass a Signal directly `this.store.loadUsersByQuery(this.searchSignal);`)*

## 3. Entity Management (`withEntities`)

If your state manages a list of items (CRUD operations), you MUST use the `@ngrx/signals/entities` plugin. It eliminates the boilerplate of finding items by ID, updating arrays, and managing dictionaries.

```typescript
import { entityConfig, withEntities, setAllEntities, addEntity, updateEntity, removeEntity } from '@ngrx/signals/entities';

// Optional: Custom config if your ID field is not named 'id' (e.g., '_id' in MongoDB)
const userConfig = entityConfig({ entity: type<User>(), collection: 'user' });

export const UserEntityStore = signalStore(
  // Automatically adds { userEntities: User[], userIds: string[], userMap: Record<string, User> } to the state!
  withEntities(userConfig),
  
  withMethods((store) => ({
    load(users: User[]) {
      patchState(store, setAllEntities(users, userConfig));
    },
    add(user: User) {
      patchState(store, addEntity(user, userConfig));
    },
    updateName(id: string, newName: string) {
      patchState(store, updateEntity({ id, changes: { name: newName } }, userConfig));
    },
    delete(id: string) {
      patchState(store, removeEntity(id, userConfig));
    }
  }))
);
```

## 4. Custom Features (Reusable State Logic)

If 20 different stores all need `{ isLoading, error }` state, DO NOT copy-paste it. SignalStore is highly composable.

**✅ ALWAYS** create custom `with...` functions to reuse state patterns.

```typescript
// ✅ ALWAYS: Extract reusable logic into Custom Features
import { signalStoreFeature, withState, withComputed } from '@ngrx/signals';

export function withCallState() {
  return signalStoreFeature(
    withState({ isLoading: false, error: null as string | null }),
    withComputed((state) => ({
      isLoaded: computed(() => !state.isLoading() && state.error() === null)
    }))
  );
}

// Usage:
export const ProductStore = signalStore(
  withState({ products: [] }),
  withCallState(), // Injects isLoading, error, and isLoaded into this store!
  withMethods(...)
);
```

## 5. Global vs Local Providers

1. **Global Store**: If you add `{ providedIn: 'root' }` to the `signalStore()`, it acts exactly like Redux. One single instance shared across the entire app.
2. **Local Component Store**: If you OMIT `{ providedIn: 'root' }`, you can provide it at the component level.
   
```typescript
@Component({
  providers: [FormStore] // ✅ Store is created when component mounts, and DESTROYED when it unmounts!
})
export class FormComponent {
  readonly store = inject(FormStore);
}
```

---

**Execution Protocol**
1. **Deep Signals**: If your state is `withState({ user: { address: { city: 'Madrid' } } })`, you can access the nested property directly as a Signal in the template: `{{ store.user.address.city() }}`. NgRx SignalStore automatically wraps all nested properties in "Deep Signals".
2. **Lifecycle Hooks**: Use `withHooks({ onInit(store) { ... }, onDestroy(store) { ... } })` to automatically trigger a data load when the store is instantiated, or clean up resources when it dies.
3. **Immutability**: `patchState` internally uses immutable updates. Never do `store.users().push(newUser)`. Always use `patchState(store, { users: [...store.users(), newUser] })`.

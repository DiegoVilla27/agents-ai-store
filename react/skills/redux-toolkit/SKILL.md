---
name: redux-toolkit
description: The ultimate enterprise architectural standard for scalable state management, normalization, and data fetching using Redux Toolkit (RTK) and RTK Query.
author: Diego Villanueva
trigger: When working on large-scale enterprise applications, managing normalized state, or maintaining legacy Redux codebases.
---

# Redux Toolkit (RTK) Enterprise Architecture

Redux is no longer the boilerplate-heavy nightmare of 2017. Redux Toolkit (RTK) is the official, opinionated, batteries-included standard. Redux should be reserved for **Enterprise-scale applications** that require complex state derivations, normalized data structures, heavy side-effect management, and time-travel debugging. (For simple global UI state, use Zustand).

## 1. The Death of Legacy Redux

If you are writing `switch` statements, `ACTION_TYPES` constants, or manual action creators, your architecture is obsolete. 

- **`createSlice`**: Generates actions and reducers simultaneously.
- **Immer is Built-in**: You can (and should) mutate state directly inside a slice. RTK translates it into an immutable update under the hood.

```typescript
// ✅ ALWAYS: Use createSlice and mutate state directly
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface UserState { name: string; age: number; }
const initialState: UserState = { name: '', age: 0 };

const userSlice = createSlice({
  name: 'user',
  initialState,
  reducers: {
    updateAge: (state, action: PayloadAction<number>) => {
      // Immer allows this direct mutation!
      state.age = action.payload; 
    },
  },
});

export const { updateAge } = userSlice.actions;
export default userSlice.reducer;
```

## 2. Strict TypeScript Hooks

Never use the raw `useSelector` or `useDispatch` from `react-redux`. You lose all type safety.

- **Create Typed Hooks**: Define them once in a `hooks.ts` file and use them everywhere.

```typescript
// ✅ ALWAYS: Create and use strictly typed hooks (hooks.ts)
import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';
import type { RootState, AppDispatch } from './store';

export const useAppDispatch: () => AppDispatch = useDispatch;
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;

// In a component:
const age = useAppSelector((state) => state.user.age); // Typed!
```

## 3. The `createEntityAdapter` (Normalization)

If you have a list of 10,000 products, storing them as an array `[{ id: 1 }, { id: 2 }]` means updating one product requires an `O(N)` loop, destroying performance.

- **Normalize your state**: Store items in a dictionary lookup `entities: { '1': { id: 1 } }` and track an `ids: [1, 2]` array.
- **`createEntityAdapter`**: Automates all CRUD operations for normalized state.

```typescript
// ✅ ALWAYS: Normalize large collections of data
import { createEntityAdapter, createSlice } from '@reduxjs/toolkit';

const booksAdapter = createEntityAdapter<Book>({
  selectId: (book) => book.isbn,
  sortComparer: (a, b) => a.title.localeCompare(b.title),
});

const booksSlice = createSlice({
  name: 'books',
  initialState: booksAdapter.getInitialState(),
  reducers: {
    bookAdded: booksAdapter.addOne,
    booksReceived: booksAdapter.setAll,
    bookUpdated: booksAdapter.updateOne, // O(1) update!
  },
});
```

## 4. Memoized Selectors (`createSelector`)

If you derive data in `useAppSelector` that returns a new reference (like `filter` or `map`), the component will re-render infinitely.

- **`createSelector`**: From Reselect (included in RTK). It memoizes the output so it only recalculates when the input state actually changes.

```typescript
// ❌ ATROCIOUS: Infinite re-renders (returns a new array every time)
const activeUsers = useAppSelector(state => state.users.list.filter(u => u.active));

// ✅ ALWAYS: Memoize complex derivations
import { createSelector } from '@reduxjs/toolkit';

const selectUsers = (state: RootState) => state.users.list;
export const selectActiveUsers = createSelector(
  [selectUsers],
  (users) => users.filter(user => user.active)
);

// In component:
const activeUsers = useAppSelector(selectActiveUsers);
```

## 5. RTK Query: The End of `createAsyncThunk`

For data fetching, `createAsyncThunk` is a legacy pattern. It forces you to manually manage `isLoading`, `isError`, and `data` states. 

- **RTK Query (`createApi`)**: Use this for all API communication. It manages caching, optimistic updates, and background refetching automatically.

```typescript
// ✅ ALWAYS: Use RTK Query for data fetching
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const pokemonApi = createApi({
  reducerPath: 'pokemonApi',
  baseQuery: fetchBaseQuery({ baseUrl: 'https://pokeapi.co/api/v2/' }),
  endpoints: (builder) => ({
    getPokemonByName: builder.query<Pokemon, string>({
      query: (name) => `pokemon/${name}`,
    }),
  }),
});

// Auto-generates a React hook!
export const { useGetPokemonByNameQuery } = pokemonApi;

// In a component:
const { data, isLoading } = useGetPokemonByNameQuery('pikachu');
```

## 6. The Non-Serializable Rule

Redux strictly forbids non-serializable values (Promises, Symbols, Maps, Sets, class instances, or Functions) in the state or actions.

- **Why?**: It breaks time-travel debugging in the Redux DevTools and makes state persistence (saving state to LocalStorage) impossible. If you need a Map, convert it to a standard JS Object before storing it in Redux.

---

**Execution Protocol**
1. **Side Effects**: If you need to trigger a toast notification when a user logs in (which changes the state), do NOT use a `useEffect` inside a component. Use RTK's `createListenerMiddleware`. It runs outside React and listens to specific actions to trigger side effects.
2. **File Structure**: Always use the **"Feature Folder" (Ducks)** pattern. Group `slice.ts`, `selectors.ts`, and `thunks.ts` together by feature (e.g., `features/auth/`), rather than globally grouping all reducers together in one folder and all actions in another.

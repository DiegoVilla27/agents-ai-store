---
description: 'Enterprise State Management with RTK and RTK Query'
author: 'Diego Villanueva'
trigger: 'When working in large-scale enterprise applications requiring strict state patterns.'
---

# Redux Toolkit (RTK)

Modern Redux patterns for scalable and predictable state management.

## ✅ ALWAYS
- Use `createSlice` for defining state and reducers in one place.
- Use `configureStore` to set up the store with standard middleware (Thunk, DevTools).
- Use **RTK Query** (`createApi`) for data fetching instead of manual `createAsyncThunk`.
- Use Typed Hooks: `useAppSelector` and `useAppDispatch`.
- Keep the state "Flat" and normalized.

## ❌ NEVER
- Use the "Legacy Redux" pattern (Action Types, Creators, giant Switch statements).
- Mutate state manually (RTK uses Immer, but only inside `createSlice`).
- Store non-serializable data (Promises, Functions) in the Redux state.

## 🛠 Patterns
- **Entity Adapter**: Using `createEntityAdapter` for managing normalized collections.
- **Listeners Middleware**: Using `createListenerMiddleware` for side-effect management.

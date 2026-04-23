---
name: react-testing-jest
description: >
  The industry-standard testing stack for React using Jest.
  Trigger: When writing unit or integration tests with Jest and React Testing Library.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Jest Mocking Strategy (REQUIRED)

Mock external dependencies to isolate the component logic.

```typescript
// ✅ ALWAYS: Use jest.mock() for modules and jest.fn() for individual functions
jest.mock("./api", () => ({
  fetchUser: jest.fn(() => Promise.resolve({ name: "Diego" })),
}));

// ❌ NEVER: Testing third-party libraries directly
// Do not test that 'axios' works; test that your component handles the response correctly.
```

---

## Async Testing with RTL (REQUIRED)

```typescript
// ✅ ALWAYS: Use findBy* and waitFor for async updates
const btn = screen.getByRole("button", { name: /load/i });
fireEvent.click(btn);

const user = await screen.findByText(/diego/i); // Explicitly waits
expect(user).toBeInTheDocument();

// ❌ NEVER: Mixing fireEvent and user-event incorrectly
// Prefer '@testing-library/user-event' for realistic interactions.
```

---

## Testing Custom Hooks (REQUIRED)

```typescript
// ✅ ALWAYS: Use renderHook from @testing-library/react
const { result } = renderHook(() => useAuth());
expect(result.current.isLoggedIn).toBe(false);

// ❌ NEVER: Creating a fake component just to test a hook
// Use 'renderHook' directly to isolate the hook logic.
```

---

## Execution Protocol (REQUIRED)

| Step | Action |
|------|--------|
| **Mock** | Isolate the API or deep components with `jest.mock`. |
| **Setup** | Use `render` to mount the component with its providers. |
| **Interact** | Use `userEvent` for real user-like interactions. |
| **Assert** | Ensure the UI reflects the expected state changes. |

---

## Uncompromising Constraints

- **Single Truth**: Tests must pass regardless of the order they are run in.
- **Snapshot Size**: Do not commit snapshots larger than 50 lines; they become unreadable.
- **Isolation**: Every test must have its mocks cleared using `afterEach(jest.clearAllMocks)`.

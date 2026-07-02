---
name: react-testing-jest
description: The ultimate architectural standard for unit and integration testing in React using Jest and React Testing Library (RTL).
author: Diego Villanueva
trigger: When writing tests for React components, mocking external dependencies, testing custom hooks, or debugging async testing errors.
---

# React Testing (Jest & RTL) Architecture

Testing is not about chasing 100% code coverage. It is about confidence. Tests that break when you refactor the internal implementation of a component are badly written tests. You must test your components the same way a user interacts with them.

## 1. The Core Philosophy (Behavior-Driven Testing)

- **A.A.A. Pattern**: Every test must be visually separated into three distinct blocks: Arrange (setup), Act (interaction), and Assert (expectations).
- **No Implementation Details**: NEVER assert on a component's state, internal methods, or class names (unless testing a specific design system utility). Assert on the visible DOM.

```tsx
// ✅ ALWAYS: The A.A.A. Pattern
test('adds item to cart', async () => {
  // 1. Arrange
  const user = userEvent.setup();
  render(<ProductPage />);
  const button = screen.getByRole('button', { name: 'Add to Cart' });

  // 2. Act
  await user.click(button);

  // 3. Assert
  expect(await screen.findByText('Cart (1)')).toBeInTheDocument();
});
```

## 2. The Custom Render Wrapper (Provider Hell)

Modern React applications rely heavily on Context Providers (Redux, TanStack Query, ThemeProvider, Router). Instead of wrapping every component in your tests, create a global custom `render` function.

```tsx
// ✅ ALWAYS: Override RTL's render function (utils/test-utils.tsx)
import { render } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const testQueryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });

const AllTheProviders = ({ children }) => {
  return (
    <QueryClientProvider client={testQueryClient}>
      <ThemeProvider>{children}</ThemeProvider>
    </QueryClientProvider>
  );
};

const customRender = (ui, options) =>
  render(ui, { wrapper: AllTheProviders, ...options });

export * from '@testing-library/react';
export { customRender as render }; // Now use this import in your tests
```

## 3. The Jest Mocking Engine

The boundaries of a Unit Test stop at the network request and external complex modules (like a charting library). You must mock these dependencies to keep tests fast and deterministic.

- **`jest.mock`**: Mocks an entire file/module.
- **`jest.requireActual`**: Keeps the original module but allows overriding specific exports.
- **`jest.spyOn`**: Watches a method (like `console.error` or `window.localStorage.getItem`) to assert it was called, without necessarily replacing its implementation.

```tsx
// ✅ ALWAYS: Mock network boundaries
import * as api from './api';

jest.mock('./api', () => ({
  ...jest.requireActual('./api'), // Keep other utilities intact
  fetchUser: jest.fn(), // Mock the network call
}));

test('displays user data', async () => {
  // Assert specific return values per test
  (api.fetchUser as jest.Mock).mockResolvedValueOnce({ name: 'Diego' });
  
  render(<Profile />);
  expect(await screen.findByText('Diego')).toBeInTheDocument();
});
```

## 4. Test Contamination (The Silent Killer)

If Test A fails only when run after Test B, you have test contamination. State is bleeding between tests.

- **Clear Mocks**: ALWAYS clear mock call counts before every test.
- **Reset Mocks**: Resets the mock implementations back to `jest.fn()`.

```tsx
// ✅ ALWAYS: Isolate tests in the setup file
beforeEach(() => {
  jest.clearAllMocks(); // Clears .toHaveBeenCalled times
  localStorage.clear();
});
```

## 5. Asynchronous Interactions (`act` Warnings)

React throws an `act(...)` warning when state updates occur outside of RTL's expected flow (usually a promise resolving after the test finished).

- Use `findBy*` queries (which automatically wrap the wait in `act()`) instead of `getBy*` when waiting for asynchronous data to render.
- Use `waitFor` for side-effects that do not produce DOM changes (like waiting for a mock function to be called).

```tsx
// ❌ WRONG: Fails if the API is slow, throws 'act' warning
await user.click(submit);
expect(api.save).toHaveBeenCalled();

// ✅ ALWAYS: Wait for the side effect
await user.click(submit);
await waitFor(() => {
  expect(api.save).toHaveBeenCalledWith({ id: 1 });
});
```

## 6. Testing Custom Hooks (`renderHook`)

Do not create dummy "TestComponents" just to test a custom hook. Use RTL's `renderHook`.

```tsx
// ✅ ALWAYS: Use renderHook and act for custom hooks
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

test('increments counter', () => {
  const { result } = renderHook(() => useCounter());
  
  expect(result.current.count).toBe(0);
  
  // State updates inside hook tests MUST be wrapped in act()
  act(() => {
    result.current.increment();
  });
  
  expect(result.current.count).toBe(1);
});
```

## 7. Time Travel (Fake Timers)

If a component uses `setTimeout(fn, 5000)`, do not write a test that waits 5 seconds. That destroys CI pipeline performance.

```tsx
// ✅ ALWAYS: Manipulate time with Jest
beforeEach(() => {
  jest.useFakeTimers();
});

afterEach(() => {
  jest.useRealTimers();
});

test('hides toast after 5 seconds', () => {
  render(<Toast message="Saved!" />);
  expect(screen.getByText('Saved!')).toBeInTheDocument();
  
  // Fast-forward time instantly
  act(() => {
    jest.advanceTimersByTime(5000);
  });
  
  expect(screen.queryByText('Saved!')).not.toBeInTheDocument();
});
```

---

**Execution Protocol**
1. **`queryBy` vs `getBy`**: Only use `queryBy*` when asserting that an element is **NOT** in the document (it returns `null` instead of throwing an error). For everything else, use `getBy*` or `findBy*`.
2. **`userEvent` over `fireEvent`**: ALWAYS prefer `@testing-library/user-event` as it fires the full lifecycle of browser events (e.g., clicking a checkbox fires mouse down, mouse up, click, and change events).
3. **Snapshot Anti-Pattern**: NEVER snapshot entire DOM trees (`expect(container).toMatchSnapshot()`). They are unreadable and devs will blindly update them without checking. Use inline snapshots ONLY for specific, small style/class objects.

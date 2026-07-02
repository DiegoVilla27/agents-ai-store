---
name: react-native-testing-library
description: The ultimate architectural standard for user-centric testing, accessibility-first queries, and mocking native modules in React Native using React Native Testing Library (RNTL).
author: Diego Villanueva
trigger: When writing unit tests, integration tests, mocking native dependencies, or resolving React 'act' warnings in mobile tests.
---

# React Native Testing Library Mastery

Tests that check implementation details break when you refactor your code. Tests that check user behavior break when your app breaks. Your goal is to write tests that give you confidence, not tests that tie you to a specific internal state structure.

## 1. The Core Philosophy (Behavior Over Implementation)

- **Test what it does, not how it works**: Never assert on a component's internal state (e.g., `wrapper.state().count`). Assert on the UI (e.g., `expect(screen.getByText('Count: 1')).toBeTruthy()`).
- **Accessibility First**: If a user cannot find a button without a `testID`, neither should your tests. Use accessibility roles and labels to query elements.

## 2. Query Priority (The Golden Rule)

Always use queries in this exact order of priority.

1. **`getByRole`**: The ultimate query. It ensures your app is accessible to screen readers.
2. **`getByLabelText`**: For form inputs with labels.
3. **`getByText`**: For buttons, links, and paragraphs.
4. **`getByTestId`**: The last resort. Only use this for dynamic layouts or icons where text/roles are impossible to define cleanly.

```tsx
// ✅ ALWAYS: Accessibility-driven queries
const submitButton = screen.getByRole('button', { name: 'Submit Order' });
const emailInput = screen.getByLabelText('Email Address');

// ❌ NEVER: Defaulting to testID when a role exists
const submitButton = screen.getByTestId('submit-button');
```

## 3. Interactions: `userEvent` vs `fireEvent`

- **`userEvent`**: Prefer the `userEvent` API (introduced in newer RNTL versions). It simulates realistic user interactions, including focus, blur, and typing delays.
- **`fireEvent`**: Use it only for simple, instantaneous dispatches or custom native events.

```tsx
// ✅ ALWAYS: Realistic user interactions
import { userEvent } from '@testing-library/react-native';

test('submits form', async () => {
  const user = userEvent.setup();
  
  await user.type(screen.getByLabelText('Email'), 'test@test.com');
  await user.press(screen.getByRole('button', { name: 'Login' }));
  
  expect(await screen.findByText('Welcome!')).toBeOnTheScreen();
});
```

## 4. Asynchronous Testing & The `act` Warning

The dreaded *"An update inside a test was not wrapped in act(...)"* warning occurs when a state update happens *after* your test has finished, or while it isn't waiting for it.

- **`findBy*` Queries**: Always use `await screen.findByRole(...)` to wait for an element to appear asynchronously. `findBy` automatically wraps the wait in `act()`.
- **`waitFor`**: Use this to wait for assertions that don't involve querying elements (e.g., waiting for a mocked function to be called).

```tsx
// ❌ WRONG: Causes 'act' warnings because the API resolves later
fireEvent.press(button);
expect(api.submit).toHaveBeenCalled();

// ✅ ALWAYS: Wait for the asynchronous side-effect
await user.press(button);
await waitFor(() => {
  expect(api.submit).toHaveBeenCalled();
});
```

## 5. The Custom Render Wrapper

Your components rely on Providers (Redux, Theme, Navigation, React Query). You must create a custom `render` function that wraps every tested component in these providers automatically.

```tsx
// ✅ ALWAYS: Custom Render setup (utils/test-utils.tsx)
import { render } from '@testing-library/react-native';
import { ThemeProvider } from './Theme';
import { QueryClientProvider } from '@tanstack/react-query';

const AllTheProviders = ({ children }) => {
  return (
    <ThemeProvider>
      <QueryClientProvider client={testClient}>
        {children}
      </QueryClientProvider>
    </ThemeProvider>
  );
};

const customRender = (ui, options) =>
  render(ui, { wrapper: AllTheProviders, ...options });

export * from '@testing-library/react-native';
export { customRender as render };
```

## 6. Mocking Native Modules

Jest runs in a Node environment. Any React Native module that uses native code (C++/Objective-C/Java) will crash Jest unless mocked.

- **Automated Setup**: Create a `jest.setup.js` file and configure it in `jest.config.js`.
- **Mocking Strategy**: Mock the JS interface of the native module, not the native code itself.

```javascript
// ✅ ALWAYS: Mock native modules in jest.setup.js
jest.mock('react-native-reanimated', () => {
  const Reanimated = require('react-native-reanimated/mock');
  Reanimated.default.call = () => {};
  return Reanimated;
});

jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
);
```

## 7. Mocking Navigation (React Navigation)

Do not wrap tests in a real `NavigationContainer` unless doing full E2E testing. Mock the hooks instead.

```tsx
// ✅ ALWAYS: Mock Navigation Hooks
const mockNavigate = jest.fn();

jest.mock('@react-navigation/native', () => ({
  ...jest.requireActual('@react-navigation/native'),
  useNavigation: () => ({
    navigate: mockNavigate,
  }),
  useRoute: () => ({
    params: { id: '123' },
  }),
}));

test('navigates on press', async () => {
  await user.press(screen.getByRole('button'));
  expect(mockNavigate).toHaveBeenCalledWith('Details', { id: '123' });
});
```

## 8. Snapshot Testing (The Anti-Pattern)

Large UI snapshots are fragile, unreadable, and developers blindly update them (`-u`) when they fail.

- **Prohibition**: NEVER snapshot an entire screen.
- **Allowed Usage**: Use small, inline snapshots ONLY to verify critical styling logic that changes based on props (e.g., ensuring a button turns red when `variant="danger"`).

---

**Execution Protocol**
1. **A.A.A. Pattern**: Every test must strictly follow Arrange, Act, Assert. Separate them with empty lines.
2. **Clear Mocks**: Always run `jest.clearAllMocks()` in `beforeEach` to prevent test contamination.
3. **Timer Mocks**: If testing animations or timeouts (`setTimeout`), use `jest.useFakeTimers()` to instantly advance time instead of adding actual delays to the test suite.

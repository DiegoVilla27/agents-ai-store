---
name: web-modern-testing
description: The definitive architectural standard for building resilient, flaky-free, and accessibility-first test suites for modern web applications.
author: Diego Villanueva
trigger: When writing unit, integration, component, or end-to-end tests, setting up CI pipelines, or debugging flaky tests.
---

# Modern Web Testing Mastery

You are the gatekeeper of application reliability. Tests are not just safety nets; they are live documentation and the foundation of continuous deployment. A flaky test is worse than no test at all. Test the user experience, not the implementation details.

## 1. The Modern Testing Pyramid (The Trophy Shape)

The classic pyramid (heavy on unit tests) has evolved. 
- **Unit Tests (Fast)**: For pure functions, utilities, reducers, and custom hooks.
- **Integration / Component Tests (The Core)**: Render the component, mock the network (MSW), and simulate user interaction. This should form the bulk of your test suite.
- **End-to-End (E2E) Tests (Crucial)**: Use Playwright or Cypress for critical user journeys across the entire stack.

## 2. Accessibility-First Testing (Testing Library)

Test your application the exact same way a user experiences it. Users don't care about the component's state; they care about what they see and can interact with.

- **Priority Selectors**: Always default to `getByRole`. If a screen reader can't find it, neither should your test.
  - *Good*: `screen.getByRole('button', { name: /submit/i })`
  - *Acceptable*: `screen.getByLabelText(/password/i)`, `screen.getByText(/success/i)`
- **The Last Resort**: Only use `data-testid` when semantic HTML is impossible or querying by role is excessively complex.
- **Never Use Implementation Details**: Never select by CSS class names, IDs, or component internal state.

## 3. Simulating Real Behavior (`userEvent`)

- **Use `@testing-library/user-event`**: Always prefer `userEvent` over `fireEvent`. 
- **Why?**: `userEvent.type()` triggers a full sequence of events (`keydown`, `keypress`, `keyup`, `input`, `change`), exactly like a real browser. `fireEvent` only dispatches a synthetic event.

## 4. Mocking the Network, Not the Implementation (MSW)

Never mock `fetch`, `axios`, or your global state management store in integration tests.

- **Mock Service Worker (MSW)**: Intercept requests at the network level. This guarantees that your components, HTTP clients, and data-fetching hooks are fully exercised.
- **Resilient Refactoring**: If you change from `axios` to `fetch`, or from `Redux` to `Zustand`, tests powered by MSW will not break.
  ```typescript
  // ✅ ALWAYS: Use MSW handlers
  export const handlers = [
    http.get("/api/user", () => HttpResponse.json({ name: "Diego" }))
  ];
  ```

## 5. The A.A.A. Pattern

Every test must read like a clear narrative.
1. **Arrange**: Set up the environment, render the component, configure the MSW handlers.
2. **Act**: Execute the user actions (`userEvent.click()`).
3. **Assert**: Verify the expected outcome (`expect(...).toBeInTheDocument()`).

Separate these three phases with an empty line.

## 6. Eradicating Flakiness

Flakiness destroys trust in the test suite.
- **Never Use Explicit Waits**: Never use `setTimeout` or `page.waitForTimeout(5000)` in tests.
- **Wait for States**: Use `findByRole` or `waitFor` to pause execution dynamically until an element appears or a condition is met.
- **Isolated State**: Every test must start with a clean slate. Do not share variables, DOM state, or database state between tests.
- **Mock Timers**: If a component uses `setTimeout` or intervals, use `vi.useFakeTimers()` (Vitest/Jest) to control time deterministically.

## 7. End-to-End (E2E) Testing Strategy

E2E tests (Playwright) are slow and expensive. Use them strategically.
- **Test Critical Paths**: Registration, Checkout, Login.
- **Data Setup**: E2E tests should set up their own data via API calls or DB seeds before running, and clean up afterward. Do not rely on existing staging data.
- **Visual Regression**: Use visual diffing for complex UI components (charts, complex grids) where asserting DOM nodes is insufficient.

## 8. Unit Testing Pure Logic (Vitest / Jest)

- **Test Boundaries**: For pure functions, test the boundaries (empty inputs, nulls, extremely large datasets).
- **Property-Based Testing**: Consider tools like `fast-check` for complex algorithms to run hundreds of randomized edge-case inputs automatically.

## 9. Code Coverage vs. Mutation Testing

- **Coverage is a Metric, Not a Goal**: 100% line coverage means nothing if you aren't asserting the right things.
- **Mutation Testing**: Consider using tools like Stryker to ensure your tests actually fail when the production code logic is altered.

---

**Execution Protocol**
1. **Red, Green, Refactor**: Adopt Test-Driven Development (TDD) where applicable.
2. **CI Gates**: Pull Requests cannot be merged if coverage drops significantly or if a single test fails.
3. **Continuous Speed**: If the integration suite takes longer than a few minutes, aggressively investigate parallelization or sharding.

---
name: web-modern-testing
description: >
  Modern testing pyramid for web applications using Vitest, MSW, and Playwright.
  Trigger: When writing unit, component, or end-to-end tests to ensure code reliability and accessibility.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Accessibility-First Testing (REQUIRED)

Test your application the same way a user experiences it.

```typescript
// ✅ ALWAYS: Use getByRole and userEvent
test("should submit the form with valid data", async () => {
  render(<UserForm />);
  const input = screen.getByRole("textbox", { name: /username/i });
  const submitBtn = screen.getByRole("button", { name: /submit/i });
  
  await userEvent.type(input, "Diego");
  await userEvent.click(submitBtn);
  
  expect(await screen.findByText(/success/i)).toBeInTheDocument();
});

// ❌ NEVER: Test-ID or implementation-detail selectors
// Do not use qyerySelector(".btn-primary") or data-testid="submit-btn" unless necessary.
```

---

## Mocking with MSW (REQUIRED)

Mock the network, not the library.

```typescript
// ✅ ALWAYS: Use Mock Service Worker (MSW)
export const handlers = [
  http.get("/api/user", () => {
    return HttpResponse.json({ name: "Diego" });
  }),
];

// ❌ NEVER: Manual global fetch mocks
// Do not mock 'window.fetch' manually; it leads to brittle tests.
```

---

## E2E with Playwright (REQUIRED)

High-fidelity tests for critical paths.

| Case | Recommendation |
|------|----------------|
| **Cross-browser** | Run tests in Chromium, WebKit, and Firefox. |
| **Trace Viewer** | Use to debug failures in CI environments. |
| **Visual Regression** | Use `expect(page).toHaveScreenshot()` for UI stability. |

---

## Execution Protocol (REQUIRED)

1. **Unit**: Test pure functions and hooks with Vitest.
2. **Component**: Test visual states and interactions with React Testing Library.
3. **Mock**: Use MSW to handle all API responses during tests.
4. **E2E**: Validate critical user journeys (e.g., checkout flow) on real browsers.

---

## Uncompromising Constraints

- **No Over-Mocking**: Never mock things you own (like child components) unless they are 3rd party or performance bottlenecks.
- **Async Safety**: Always use `findBy*` or `waitFor` for elements that appear after an action.
- **Coverage**: Focus on use-case coverage over mere line-of-code coverage.

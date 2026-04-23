---
description: 'User-Centric Testing for React Native Components'
author: 'Diego Villanueva'
trigger: 'When implementing unit and integration tests for mobile components.'
---

# React Native Testing Library

Standardized testing practices for high-quality mobile applications.

## ✅ ALWAYS
- Use `@testing-library/react-native` for user-centric testing.
- Search for elements using `getByText`, `getByLabelText`, and `getByTestId`.
- Use `fireEvent` to simulate user interactions (press, changeText).
- Use `waitFor` for handling asynchronous UI updates.
- Mock native modules and external APIs to isolate component behavior.

## ❌ NEVER
- Test implementation details (internal state, private methods); test the UI behavior.
- Overuse `testID` if accessible labels can be used instead.
- Skip testing error states and edge cases.

## 🛠 Patterns
- **Integration Tests**: Testing the interaction between multiple components and hooks.
- **Snapshot Testing**: Using it sparingly for stable UI structures.

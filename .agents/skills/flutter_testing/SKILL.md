---
name: flutter-testing
description: >
  Defender of stability specialized in the Flutter testing pyramid.
  Trigger: When creating new features or fixing bugs to ensure zero regressions.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Balanced Testing Pyramid (REQUIRED)

Ensure high coverage across all levels of the application.

```dart
// ✅ ALWAYS: Mocks and Success/Error cases
when(mockApi.getData()).thenAnswer((_) async => SuccessResponse());

// ❌ NEVER: Real network/hardware calls
// Forbidden: executing actual network requests in Unit/Widget tests.
```

---

## Widget & Visual Testing (REQUIRED)

Protect the integrity of the Design System.

| Test Type | Focus |
|-----------|-------|
| **Golden Tests** | Visual rendering and layout consistency. |
| **Interaction** | User input, taps, and scrolls. |
| **Pump & Settle** | Animation stabilization and tree refresh. |

---

## Integration & E2E (REQUIRED)

Validate critical paths in near-real environments.

```dart
// ✅ ALWAYS: Test Login -> Action -> Logout flows
testWidgets('Full transaction flow test', (tester) async {
  // ... simulated user journey
});

// ❌ NEVER: Unreliable tests
// Every reported bug must have a reproducing test before being fixed.
```

---

## Execution Protocol (REQUIRED)

1. **Identify**: Define test cases before development (TDD preferred).
2. **Mock**: Isolate external dependencies using `mockito` or `mocktail`.
3. **Execute**: Run `flutter test` frequently.
4. **Audit**: Review `lcov` reports to identify coverage gaps.

---

## Uncompromising Constraints

- **Doc as Code**: Tests must be readable and serve as living documentation.
- **Isolation**: Unit tests must have zero external dependencies.
- **Regression Proof**: No fixes without a corresponding test to prevent regressions.

---
name: flutter-riverpod
description: >
  Riverpod expert focused on reactive data flow and code generation (@riverpod).
  Trigger: When managing application state or injecting dependencies using Riverpod.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Code Generation Strategy (REQUIRED)

Prefer the modern functional style with the `@riverpod` annotation.

```dart
// ✅ ALWAYS: Functional providers and part files
@riverpod
String myValue(MyValueRef ref) => 'Hello';

part 'my_file.g.dart';

// ❌ NEVER: Manual provider syntax
// Forbidden: using the old manual syntax if code generation can be used.
```

---

## State Management (REQUIRED)

Use Class-Based Notifiers for mutable state.

```dart
// ✅ ALWAYS: AsyncValue for async data
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  FutureOr<Data> build() => fetchData();
}

// ❌ NEVER: Heavy logic in build()
// Do not perform side effects inside the 'build' method.
```

---

## Performance & Optimization (REQUIRED)

| Need | Use |
|------|-----|
| Reactivity | `ref.watch(provider)` |
| Actions | `ref.read(provider.notifier).action()` |
| Optimization | `ref.watch(provider.select((v) => v.prop))` |

---

## Execution Protocol (REQUIRED)

1. **Annotate**: Define the function or class with `@riverpod`.
2. **Import**: Include the `part` directive for the generator.
3. **Generate**: Run `dart run build_runner watch --delete-conflicting-outputs`.
4. **Mock**: Use `ProviderScope` overrides in tests.

---

## Uncompromising Constraints

- **Auto-Dispose**: Do not use `keepAlive: true` unless strictly necessary for global persistence.
- **UI Consumption**: Use `ConsumerWidget` or `HookConsumerWidget` consistently in the UI.
- **Sync**: Never stop the generator while defining new providers.
 Broadway.

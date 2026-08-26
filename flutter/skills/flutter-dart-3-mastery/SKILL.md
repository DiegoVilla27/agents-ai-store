---
name: flutter-dart-3-mastery
description: The ultimate architectural standard for Modern Dart 3 Mastery Sealed Classes, Exhaustive Pattern Matching, Records, Destructuring, and Class Modifiers.
author: Diego Villanueva
trigger: When writing Dart 3 code, modeling domain states with sealed classes, using switch expressions with pattern matching, or returning multiple values with Records.
---

# Enterprise Dart 3 Language Mastery

Dart 3 revolutionized Flutter development by introducing **Sealed Classes**, **Exhaustive Pattern Matching**, **Records**, **Destructuring**, and **Class Modifiers** (`base`, `final`, `interface`, `sealed`).

---

## 1. Algebraic Data Types & Exhaustive Pattern Matching (`sealed class`)

**❌ NEVER** use enum + class casting or loosely typed dynamic maps for UI state.
**✅ ALWAYS** use `sealed class` hierarchies. The Dart compiler will guarantee compile-time exhaustiveness, throwing an error if a state case is missed.

```dart
// domain/auth/auth_state.dart
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final String userId;
  final String token;
  const Authenticated({required this.userId, required this.token});
}

class AuthFailure extends AuthState {
  final String errorMessage;
  final int? errorCode;
  const AuthFailure(this.errorMessage, {this.errorCode});
}
```

### Pattern Matching Switch Expressions:

```dart
// Presentation Layer UI rendering with exhaustive switch expression
Widget buildAuthView(AuthState state) {
  return switch (state) {
    AuthInitial() => const InitialLoginPrompt(),
    AuthLoading() => const Center(child: CircularProgressIndicator()),
    Authenticated(:final userId) => UserDashboard(userId: userId),
    AuthFailure(:final errorMessage, errorCode: 401) => SessionExpiredAlert(),
    AuthFailure(:final errorMessage) => ErrorBanner(message: errorMessage),
  };
}
```

---

## 2. Records and Multiple Return Values

Records allow functions to return multiple typed values without defining boilerplate DTO classes:

```dart
// Returning named and positional records
(double latitude, double longitude, {String? city}) getLocationCoordinates() {
  return (40.4168, -3.7038, city: 'Madrid');
}

void useLocation() {
  // Destructuring record values
  final (lat, lng, :city) = getLocationCoordinates();
  print('Lat: $lat, Lng: $lng, City: $city');
}
```

---

## 3. Class Modifiers for Enterprise Architecture

Dart 3 introduces strict encapsulation modifiers to protect library and package APIs:

| Modifier | Inside Same Library | Outside Library | Purpose |
|---|---|---|---|
| `sealed` | Can extend/implement | **Cannot** extend/implement | Closed hierarchies for pattern matching. |
| `final` | Can extend/implement | **Cannot** extend/implement/mixin | Immutable closed class. |
| `base` | Can extend | Can **only extend** (cannot implement) | Guarantees base method contracts. |
| `interface` | Can extend/implement | Can **only implement** (cannot extend) | Pure interfaces without implementation inheritance. |

```dart
// core/network/api_client.dart
// External modules can ONLY implement this contract, never inherit private internals
interface class ApiClient {
  Future<Map<String, dynamic>> get(String path) async => throw UnimplementedError();
}
```

---

## 4. Functional Result Types (Replacing Exceptions)

```dart
// core/types/result.dart
sealed class Result<T, E> {
  const Result();

  R fold<R>(R Function(T value) onSuccess, R Function(E error) onFailure) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}
```

---

**Execution Protocol**
1. **Always use switch expressions for state rendering**: Guarantees compile-time safety when new states are added.
2. **Use Records for local tuples**: Avoid creating throwaway helper classes for multiple function returns.
3. **Enforce `sealed class` on all Domain Entities and Events**: Guarantees exhaustive handling across Riverpod controllers.
4. **Use object destructuring `:final property`**: Improves readability and reduces verbose local variable assignments.

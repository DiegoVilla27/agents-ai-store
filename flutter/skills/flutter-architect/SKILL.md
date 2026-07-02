---
name: flutter-architect
description: The ultimate architectural standard for Enterprise Flutter Feature-First Structure, Clean Architecture Layers (Domain, Data, Presentation), and Dependency Injection.
author: Diego Villanueva
trigger: When structuring a new Flutter project, defining folder hierarchies, implementing Clean Architecture, or organizing layers.
---

# Enterprise Flutter Architecture

Flutter is a UI toolkit, not a framework like Angular or NestJS. It provides absolutely no architectural opinions. If you do not enforce strict boundaries, your app will devolve into a "Big Ball of Mud" where API calls happen inside `onTap` callbacks using `setState`.

This document defines the strictly enforced **Feature-First Clean Architecture** standard.

## 1. Feature-First Project Structure (Domain-Driven)

Layer-First architecture (grouping all controllers together, all models together) fails at scale. You MUST group files by **Feature** (Business Domain).

```text
lib/
├── core/                  # Global utilities, network clients, DI setup, theme
├── shared/                # Widgets/UI components used across multiple features
├── features/
│   ├── auth/              # Bounded Context: Authentication
│   │   ├── data/          # Data Layer (Data Sources, Models, Repositories Impl)
│   │   ├── domain/        # Domain Layer (Entities, Repository Interfaces, UseCases)
│   │   └── presentation/  # Presentation Layer (Widgets, State/Bloc/Riverpod)
│   └── checkout/          # Bounded Context: Checkout
└── main.dart
```

## 2. The Three Layers (Clean Architecture Boundaries)

Every Feature must strictly separate UI, Business Logic, and Data. Dependencies can only point INWARD toward the Domain layer.

### A. The Domain Layer (The Core)
This layer is **Pure Dart**. It knows absolutely nothing about Flutter (no `import 'package:flutter/material.dart'`), HTTP, Firebase, or State Management.

```dart
// ✅ ALWAYS: Define pure Entities (No JSON serialization here)
class User {
  final String id;
  final String email;
  User({required this.id, required this.email});
}

// ✅ ALWAYS: Define Repository Interfaces (Ports)
abstract class AuthRepository {
  Future<User> login(String email, String password);
}

// ✅ ALWAYS: Define UseCases (Business Logic Actions)
class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<User> execute(String email, String password) {
    if (!email.contains('@')) throw ValidationException('Invalid email');
    return repository.login(email, password);
  }
}
```

### B. The Data Layer (The Infrastructure)
This layer implements the Domain's interfaces and talks to the outside world (APIs, SQL, Firebase).

```dart
// ✅ ALWAYS: Data Models (DTOs) handle JSON serialization
class UserModel extends User {
  UserModel({required super.id, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    email: json['email'],
  );
}

// ✅ ALWAYS: Implement the Repository Interface (Adapter)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> login(String email, String password) async {
    // Converts the DTO (UserModel) back to the pure Entity (User)
    return await remoteDataSource.login(email, password);
  }
}
```

### C. The Presentation Layer (UI & State)
This layer connects Flutter to the Domain. It manages state and draws pixels. It MUST NOT do business logic or API calls.

```dart
// ✅ ALWAYS: State Management calls UseCases, NEVER Repositories directly
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  
  AuthNotifier(this.loginUseCase) : super(const AuthInitial());

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await loginUseCase.execute(email, password);
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}
```

## 3. The Proximity Rule (Atomic Scoping)

When creating a new widget, developers instinctively place it in `lib/shared/widgets/`. This creates a massive global garbage dump of widgets.

**CRITICAL RULE**: If a widget is only used on ONE screen, it must live in the folder of that screen.

```dart
// ✅ ALWAYS: Local widgets stay local
lib/features/auth/presentation/screens/login_screen.dart
lib/features/auth/presentation/widgets/login_submit_button.dart // ONLY used in LoginScreen

// ❌ NEVER: Global widgets for single-use elements
lib/shared/widgets/login_submit_button.dart // Why is this global?!
```

## 4. Dependency Injection (DI)

You MUST NOT instantiate UseCases, Repositories, or DataSources inside your Widgets using the `new` keyword. You must use a DI container (like `get_it`) or Riverpod's Provider system to inject them.

```dart
// ❌ ATROCIOUS: Hardcoded dependencies in the UI
final authController = AuthNotifier(LoginUseCase(AuthRepositoryImpl(AuthRemoteDataSource())));

// ✅ ALWAYS: Inject dependencies from a central locator or provider
final authController = sl<AuthNotifier>(); // Using get_it
// OR
final authController = ref.read(authNotifierProvider.notifier); // Using Riverpod
```

## 5. Semantic Routing (GoRouter)

Do not use Flutter's basic `Navigator.push()`. It does not support deep-linking (Web) and makes route guarding a nightmare. You MUST use `go_router` for semantic, state-driven routing.

```dart
// ✅ ALWAYS: Use GoRouter with redirection guards
final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    final isGoingToLogin = state.uri.path == '/login';

    if (!isAuthenticated && !isGoingToLogin) return '/login'; // Guard private routes
    if (isAuthenticated && isGoingToLogin) return '/dashboard'; // Skip login if auth'd
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
  ],
);
```

---

**Execution Protocol**
1. **Never use `setState` for async data**: `setState` is strictly for ephemeral UI state (e.g., toggling a checkbox or expanding a card). Fetching data from an API MUST go through your state management tool (Bloc/Riverpod).
2. **The `const` Keyword**: Every widget that does not have dynamic properties in its constructor MUST be instantiated with `const`. This tells Flutter to cache the widget and never rebuild it. Configure your `analysis_options.yaml` to enforce `prefer_const_constructors`.
3. **Immutability**: All State objects, Entities, and Models MUST be strictly immutable. Use `Freezed` or `Equatable` to enforce value equality and prevent accidental state mutation.

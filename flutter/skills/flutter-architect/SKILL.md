---
name: flutter-architect
description: The ultimate architectural standard for Enterprise Flutter Modular Feature-First Structure, self-contained modules, and Dependency Injection.
author: Diego Villanueva
trigger: When structuring a new Flutter project, defining folder hierarchies, implementing Modular Architecture, or organizing feature modules.
---

# Enterprise Flutter Architecture

Flutter is a UI toolkit, not a framework like Angular or NestJS. It provides absolutely no architectural opinions. If you do not enforce strict boundaries, your app will devolve into a "Big Ball of Mud" where API calls happen inside `onTap` callbacks using `setState`.

This document defines the strictly enforced **Modular Feature-First Architecture** standard.

## 1. Modular Feature-First Project Structure

Layer-First architecture (grouping all controllers together, all models together) fails at scale. You MUST group files by **Feature Module**.

```text
lib/
├── core/                  # Global utilities, network clients, DI setup, theme
├── shared/                # Widgets/UI components used across multiple features
├── features/
│   ├── auth/              # Feature Module: Authentication
│   │   ├── models/        # Data models and DTOs
│   │   ├── services/      # Business logic and API communication
│   │   ├── controllers/   # State management (Riverpod/Notifier)
│   │   ├── widgets/       # Feature-specific UI components
│   │   └── views/         # Screen pages
│   └── checkout/          # Feature Module: Checkout
└── main.dart
```

## 2. Module Boundary Rules

Every Feature Module must be self-contained and loosely coupled:

1. **Self-Contained**: Each feature owns its models, services, controllers, widgets, and views.
2. **No Cross-Feature Internal Imports**: Features communicate via Riverpod providers, shared services, or route parameters.
3. **Services Handle Business & Data**: Services communicate with APIs/DBs and contain business logic.
4. **UI Connects via Controllers**: Widgets and Views consume state via Riverpod controllers, never calling raw network endpoints.

```dart
// ✅ ALWAYS: State Management calls Services injected via Riverpod
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  
  AuthNotifier(this.authService) : super(const AuthInitial());

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await authService.login(email, password);
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

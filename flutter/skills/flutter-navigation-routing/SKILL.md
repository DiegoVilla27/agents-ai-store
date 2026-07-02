---
name: flutter-navigation-routing
description: The ultimate architectural standard for Flutter Navigation GoRouter, Semantic Routing, StatefulShellRoute (BottomNavBar), Auth Guards, and Deep Linking.
author: Diego Villanueva
trigger: When configuring app routing, implementing deep links, adding Bottom Navigation Bars, or protecting routes with Authentication guards.
---

# Flutter Navigation & Routing Architecture

Navigation 1.0 (`Navigator.push()`) is **deprecated** for Enterprise use. It fails fundamentally on the Web (no URL updates), breaks deep linking, and makes authentication guarding a nightmare.

You MUST use **GoRouter** (Navigation 2.0). It provides declarative, URL-based routing.

## 1. The `push` vs `go` Paradigm

Understanding the difference between `push` and `go` is critical to preventing broken Back buttons and memory leaks.

- **`context.go('/settings')`**: Replaces the current navigation stack based on the route tree. If `/settings` is a top-level route, the Back button will disappear.
- **`context.push('/settings')`**: Pushes the route ON TOP of the current stack. The Back button appears, and pressing it returns the user to the exact previous state.

```dart
// ❌ ATROCIOUS: Using Navigation 1.0
Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen()));

// ✅ ALWAYS: Use GoRouter
context.go('/settings'); // Absolute jump
context.push('/settings/profile'); // Stack jump (adds back button)
```

## 2. Authentication Guards (`redirect`)

You must NEVER check if a user is logged in inside a Widget's `build` method to decide what screen to show. You MUST do it at the Router level.

GoRouter provides a `redirect` method that acts as a global middleware.

```dart
// ✅ ALWAYS: Secure your routes at the Router level
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    // CRITICAL: Tells GoRouter to re-evaluate the redirect logic if authState changes
    refreshListenable: ref.read(authNotifierProvider.notifier),
    
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isGoingToLogin = state.uri.path == '/login';

      // If user is not logged in and NOT going to login -> force them to login
      if (!isAuth && !isGoingToLogin) return '/login';
      
      // If user IS logged in but trying to go to login -> force them to dashboard
      if (isAuth && isGoingToLogin) return '/dashboard';
      
      return null; // Do nothing, let them pass
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
    ],
  );
});
```

## 3. Persistent Bottom Navigation (`StatefulShellRoute`)

A standard BottomNavigationBar destroys the state of the tabs when you switch between them. If the user scrolls down on "Home", switches to "Profile", and switches back to "Home", the scroll position resets to the top. This is an awful user experience.

You MUST use `StatefulShellRoute` in GoRouter to preserve tab state.

```dart
// ✅ ALWAYS: Use StatefulShellRoute for Bottom Navigation
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    // The navigationShell manages the state of the tabs automatically!
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  },
  branches: [
    // Branch 1: Home
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            // Nested route: /home/details
            GoRoute(path: 'details', builder: (context, state) => const DetailsScreen()),
          ]
        ),
      ],
    ),
    // Branch 2: Profile
    StatefulShellBranch(
      routes: [
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
  ],
)
```

## 4. Type-Safe Routing (No Magic Strings)

Using strings like `context.go('/users/${user.id}')` is prone to typos. You should use the `go_router_builder` package to generate type-safe routes.

```dart
// ✅ ALWAYS: Use Typed Routes for complex apps
import 'package:go_router/go_router.dart';

part 'routes.g.dart'; // Generated file

@TypedGoRoute<UserRoute>(path: '/users/:id')
class UserRoute extends GoRouteData {
  final int id;
  const UserRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return UserProfileScreen(id: id);
  }
}

// Navigating later:
UserRoute(id: 42).go(context); // 100% Type-safe! No string manipulation.
```

## 5. Deep Linking Configuration

For URLs like `https://acme.com/users/42` to open the app directly on the user's profile, you must configure the native operating systems.

- **Android (`android/app/src/main/AndroidManifest.xml`)**: Add `<intent-filter>` with `android:autoVerify="true"` and host `acme.com`. You MUST host an `assetlinks.json` file at `https://acme.com/.well-known/assetlinks.json`.
- **iOS (`ios/Runner/Runner.entitlements`)**: Add `applinks:acme.com` to `com.apple.developer.associated-domains`. You MUST host an `apple-app-site-association` file at `https://acme.com/.well-known/apple-app-site-association`.

---

**Execution Protocol**
1. **Error Handling**: Always provide an `errorBuilder` in your GoRouter configuration to display a branded "404 Not Found" page instead of a blank red screen if a deep link fails.
2. **Parameters vs Queries**: Use Path Parameters (`/users/:id`) for required identifiers (e.g. looking up a database record). Use Query Parameters (`/search?q=flutter`) for optional filters or search terms. Access them via `state.pathParameters['id']` and `state.uri.queryParameters['q']`.
3. **App Startup**: Do not do heavy API calls (like fetching user profile data) inside the Router configuration. Keep router logic strictly synchronized with your State Management.

---
name: flutter-riverpod
description: The ultimate architectural standard for Riverpod 2.0+ Code Generation (@riverpod), AsyncValue, Reactive Caching, and Dependency Injection.
author: Diego Villanueva
trigger: When managing application state, implementing Dependency Injection, or handling asynchronous data loading in Flutter.
---

# Riverpod Architecture & Reactive Caching

Riverpod is fundamentally misunderstood by most developers. It is **not** just a state management library like Provider or Bloc. It is a **Reactive Caching Framework**. It is designed to cache asynchronous operations and reactively update the UI when the underlying data changes.

**CRITICAL RULE**: The legacy syntax (`StateNotifierProvider`, `FutureProvider`) is officially discouraged. You MUST use Riverpod Generator (`@riverpod`).

## 1. Code Generation (The Modern Standard)

Manual providers are brittle, prone to typo errors, and require explicit type declarations. Code generation solves this.

```dart
// ❌ ATROCIOUS: Legacy Riverpod 1.0 Syntax (BANNED)
final userProvider = FutureProvider.family<User, String>((ref, id) async {
  return fetchUser(id);
});

// ✅ ALWAYS: Riverpod 2.0 Generator Syntax
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart'; // REQUIRED: Run `dart run build_runner watch`

@riverpod
Future<User> fetchUser(FetchUserRef ref, String id) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(id);
}
```

## 2. Managing Mutations (`AsyncNotifier`)

When you just need to fetch data, a simple `@riverpod` function is enough. But when you need to **mutate** data (e.g., submit a form, update a database) and reflect that in the UI, you MUST use an `AsyncNotifier`.

```dart
// ✅ ALWAYS: Use AsyncNotifier for mutable state
@riverpod
class AuthNotifier extends _$AuthNotifier {
  // 1. The build method initializes the state
  @override
  FutureOr<User?> build() async {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  // 2. Mutations modify the state reactively
  Future<void> login(String email, String password) async {
    // Set UI to loading state while preserving previous data (if any)
    state = const AsyncValue.loading();
    
    // Perform the mutation and catch errors using AsyncValue.guard
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).login(email, password);
    });
  }
}
```

## 3. Mastering `AsyncValue` in the UI

Never check for `isLoading` or `error` manually. The `AsyncValue` object has a `.when()` method that forces you to handle all three states: Data, Loading, and Error.

```dart
// ✅ ALWAYS: Exhaustive UI handling with .when()
class UserScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to rebuild when state changes
    final userState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: userState.when(
        data: (user) => Text('Welcome ${user.name}'),
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }
}
```
*(Pro-tip: If you are doing a Pull-to-Refresh, use `.when(skipLoadingOnRefresh: true)` so the screen doesn't turn into a giant loading spinner while fetching new data in the background).*

## 4. The Lifecycle (`autoDispose` vs `keepAlive`)

By default, the `@riverpod` annotation generates an `autoDispose` provider. 
This means the moment the user navigates away from the screen, the state is **destroyed**. If they navigate back, the API call happens again. This prevents memory leaks natively.

However, sometimes you want data to stay in memory (e.g., the User Profile or a Shopping Cart).

```dart
// ✅ ALWAYS: Use KeepAlive ONLY for persistent global state
@Riverpod(keepAlive: true)
class ShoppingCart extends _$ShoppingCart {
  @override
  List<Product> build() => [];
}
```

## 5. Dependency Injection Architecture

Riverpod completely eliminates the need for packages like `get_it`. Providers should depend on other Providers.

```dart
// 1. Inject the pure API Client (Dio)
@riverpod
Dio dio(DioRef ref) => Dio(BaseOptions(baseUrl: 'https://api.com'));

// 2. Inject the Repository, passing the Dio client
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  // We use watch() so if the Dio client changes, this repository is rebuilt
  return UserRepositoryImpl(ref.watch(dioProvider));
}

// 3. Inject the UseCase, passing the Repository
@riverpod
LoginUseCase loginUseCase(LoginUseCaseRef ref) {
  return LoginUseCase(ref.watch(userRepositoryProvider));
}
```

## 6. Listening to State Events (Toasts & Navigation)

State is meant to draw the UI. But what if you want to show a `SnackBar` or navigate when an error occurs? You cannot do this in the `build` method. You MUST use `ref.listen()`.

```dart
// ✅ ALWAYS: Use ref.listen() for one-time side effects
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Listen runs outside the build cycle
  ref.listen<AsyncValue<User?>>(authNotifierProvider, (previous, next) {
    if (next.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${next.error}')),
      );
    } else if (next.hasValue && next.value != null) {
      context.go('/dashboard');
    }
  });

  return LoginUI();
}
```

---

**Execution Protocol**
1. **Testing Notifiers**: Riverpod is built for testing. To test a Notifier without a UI, create a `ProviderContainer()`, override any mock dependencies using `overrideWithValue`, and call `container.read(myProvider)`. Don't forget to call `container.dispose()` in tearDown.
2. **Never call `.read()` inside a `build()` method**: Calling `ref.read` inside a `build` method destroys reactivity. If the provider updates, the UI will not rebuild. Always use `ref.watch()`. Use `ref.read()` ONLY inside callbacks (like `onPressed`).
3. **Invalidation**: If a user updates their profile picture, you don't need to manually update the state array. Just call `ref.invalidate(userProfileProvider)`. Riverpod will destroy the cache and automatically trigger a new API call to refresh the data for any UI listening to it.

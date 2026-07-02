---
name: flutter-http-json
description: The ultimate architectural standard for Flutter HTTP & JSON Dio Interceptors, Token Refresh Queues, Freezed DTOs, and Domain Mapping.
author: Diego Villanueva
trigger: When configuring API clients, writing Dio interceptors, parsing JSON, or handling network exceptions.
---

# Flutter HTTP & JSON Architecture

The network layer is the most volatile and dangerous part of any mobile application. APIs change, connections drop, and JSON payloads contain unexpected `null` values.

If your UI knows what an HTTP 404 is, or if it manually parses `json['user']`, your architecture has failed. 

## 1. The HTTP Client (Dio is Mandatory)

The default Dart `http` package is completely insufficient for Enterprise applications. It lacks built-in interceptors, global configurations, and automatic retries. You MUST use **Dio**.

### Centralized Dio Configuration
You must configure a singleton/provider of Dio with strict BaseOptions.

```dart
// ✅ ALWAYS: Configure strict BaseOptions
import 'package:dio/dio.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: Environment.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10), // NEVER wait infinitely
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
);
```

## 2. Enterprise Interceptors

Interceptors run on every request/response. This is where you inject tokens and handle global errors.

### The Auth Interceptor
Never manually add the `Authorization` header in your Repositories. Do it globally.

```dart
// ✅ ALWAYS: Inject tokens via Interceptor
class AuthInterceptor extends Interceptor {
  final SecureStorage storage;
  AuthInterceptor(this.storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}
```

### The Refresh Token Queue (CRITICAL)
If a token expires, the server returns 401. You must catch this, pause ALL incoming requests, refresh the token silently, and replay the failed requests.

```dart
// ✅ ALWAYS: Implement Token Refresh Queues for seamless sessions
class RefreshTokenInterceptor extends QueuedInterceptor {
  final Dio dio;
  final AuthService authService;

  RefreshTokenInterceptor(this.dio, this.authService);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        // 1. Attempt to refresh the token
        final newToken = await authService.refreshToken();
        
        // 2. Update the header of the failed request
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        
        // 3. Replay the failed request
        final cloneReq = await dio.fetch(err.requestOptions);
        return handler.resolve(cloneReq);
      } catch (e) {
        // Refresh failed (e.g. refresh token expired). Force logout.
        authService.logout();
        return handler.next(err);
      }
    }
    return super.onError(err, handler);
  }
}
```
*(Note: Use `QueuedInterceptor` so that if 5 simultaneous requests fail with 401, only the FIRST one triggers the refresh, while the others wait in the queue).*

## 3. JSON Serialization (Freezed)

**❌ NEVER** do manual JSON parsing: `final name = json['name'] ?? 'Unknown';`. It is brittle, verbose, and a leading cause of production crashes.

**✅ ALWAYS** use `freezed` and `json_serializable`. It provides Immutability, `copyWith`, Union Types, and Type-Safe JSON parsing.

```dart
// ✅ ALWAYS: Use Freezed for API DTOs
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    required int id,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    // Safely handle missing/null data from bad APIs
    @Default('Unknown') String role, 
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
}
```

## 4. The DTO Mapper Pattern

The UI must **NEVER** see `UserDto`. The DTO maps exactly to the API structure. If the API changes `first_name` to `firstName`, your entire app shouldn't break. 

The Data Layer must map the `DTO` into a pure Domain `Entity`.

```dart
// 1. The Pure Entity (Domain Layer - No Freezed/JSON annotations here!)
class User {
  final int id;
  final String fullName;
  User({required this.id, required this.fullName});
}

// 2. The Mapper (Data Layer)
extension UserDtoMapper on UserDto {
  User toDomain() {
    return User(
      id: id,
      fullName: '$firstName $lastName', // Business logic formatting
    );
  }
}

// 3. The Repository Implementation
class UserRepositoryImpl implements UserRepository {
  Future<User> getUser() async {
    final response = await dio.get('/user/1');
    final dto = UserDto.fromJson(response.data);
    return dto.toDomain(); // UI only receives the pure User entity!
  }
}
```

## 5. Network Error Translation

Do not throw `DioException` to the UI layer. The UI doesn't know what a SocketException is. You must translate network errors into Domain `Failure` classes using `dartz` or `fpdart`.

```dart
// ✅ ALWAYS: Translate network errors to Business Failures
Future<Either<Failure, User>> getUser() async {
  try {
    if (!await networkInfo.isConnected) return Left(NetworkFailure('No internet connection'));
    
    final response = await dio.get('/user/1');
    return Right(UserDto.fromJson(response.data).toDomain());
    
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return Left(TimeoutFailure('Server took too long to respond'));
    }
    if (e.response?.statusCode == 404) {
      return Left(NotFoundFailure('User not found'));
    }
    return Left(ServerFailure(e.message ?? 'Unknown error'));
  } catch (e) {
    return Left(UnexpectedFailure('A parsing error occurred'));
  }
}
```

---

**Execution Protocol**
1. **Isolate Parsing**: If the JSON payload is massive (e.g., a list of 10,000 products), you MUST parse it in a background thread using `Isolate.run(() => jsonDecode(response))` to prevent dropping 16ms UI frames (Jank).
2. **Pretty Logger**: Always add `PrettyDioLogger` (or similar) to your interceptors in `Debug` mode ONLY. It prints headers, bodies, and cURL commands directly in the terminal for rapid debugging.
3. **Retrofit (Optional but Recommended)**: For massive APIs with hundreds of endpoints, use `retrofit` on top of Dio to auto-generate the HTTP client boilerplate.

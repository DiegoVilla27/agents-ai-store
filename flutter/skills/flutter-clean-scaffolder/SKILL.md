---
name: flutter-clean-scaffolder
description: The ultimate architectural protocol for the AI to generate professional Modular Architecture and Feature-First scaffolding in Flutter projects.
author: Diego Villanueva
trigger: When the user asks to initialize a new Flutter project, scaffold a new feature, or generate standard Modular Architecture boilerplate.
---

# Flutter Modular Scaffolder Protocol

This skill dictates EXACTLY how you, the AI agent, must structure files and directories when asked to scaffold a Flutter project or add a new feature. You must not deviate from this standard. It enforces a **Modular Feature-First Architecture**.

## 1. The Global Structure (`lib/`)

If initializing a new project, you MUST create this exact structure first:

```text
lib/
├── core/
│   ├── config/       # Environment variables, constants
│   ├── error/        # Global exceptions and failures
│   ├── network/      # Dio clients, interceptors
│   ├── router/       # GoRouter configuration
│   ├── theme/        # AppTheme, text styles, colors
│   └── utils/        # Global helpers (extensions, validators)
├── shared/
│   ├── atoms/        # Basic UI (MyButton, MyTextField)
│   ├── molecules/    # Grouped UI (LoginForm)
│   └── organisms/    # Complex UI (Header, NavigationBar)
└── features/         # All business feature modules live here
```

## 2. Feature Generation Protocol

When asked to "Create the Auth feature", you MUST generate the following self-contained module hierarchy inside `lib/features/auth/`:

```text
lib/features/{feature}/
├── models/         # Data models and DTOs with fromJson/toJson
├── services/       # Business logic and API data sources
├── controllers/    # State Management (Riverpod providers / Notifiers)
├── screens/        # Full page widgets
└── widgets/        # Widgets specific to this feature ONLY (Proximity Rule)
```

## 3. Boilerplate Generation Templates

When scaffolding, you MUST populate the core files with these exact templates to save the developer time.

### A. The Core UseCase Interface (`lib/core/usecases/usecase.dart`)
Every UseCase in the Domain layer must implement this interface. It ensures predictable return types (Either a Failure or a Success).

```dart
// ✅ ALWAYS: Generate the Base UseCase
import 'package:dartz/dartz.dart'; // Or fpdart
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
```

### B. The Core Failure Class (`lib/core/error/failures.dart`)
```dart
// ✅ ALWAYS: Generate the Base Failure
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
```

### C. Example Scaffolded UseCase (`lib/features/auth/domain/usecases/login_usecase.dart`)
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(params.email, params.password);
  }
}
```

## 4. Test Mirroring Protocol

You MUST NOT forget the `test/` directory. When scaffolding a feature, you must create a test directory structure that exactly mirrors the `lib/` directory.

```text
test/
└── features/
    └── {feature}/
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        ├── domain/
        │   └── usecases/
        └── presentation/
            ├── providers/
            └── screens/
```

---

**Execution Protocol**
1. **Directory Creation**: Use bash commands (like `mkdir -p`) to create the entire tree instantly before writing files.
2. **Barrel Files**: In large features, generate `index.dart` or `{feature}_exports.dart` files at the root of `domain`, `data`, and `presentation` to clean up imports.
3. **No Improvised Imports**: When scaffolding, ensure imports correctly target the generated `core` files. Do not invent packages unless the user specifies them (assume `dartz` or `fpdart` for functional error handling, and `equatable` for value equality).

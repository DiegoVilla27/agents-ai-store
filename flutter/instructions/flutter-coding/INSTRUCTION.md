---
description: 'Senior Flutter Architect - Clean Architecture & Feature-Driven Design'
applyTo: '**/*.dart'
---

# Flutter Architecture & Coding Standards

You are a **Senior Flutter Architect**. You build production-grade, high-performance mobile applications using **Clean Architecture** and **Feature-Driven Design**.

## 🏛️ Scaffolding & Architecture (The Law)

Every feature MUST be self-contained within `lib/features/[feature_name]/`. You MUST follow this structure to ensure absolute separation of concerns:

```text
lib/features/[feature_name]/
├── domain/               # Rules of the Game (Pure Logic)
│   ├── entities/         # Domain objects (No annotations if possible)
│   └── repositories/     # Abstract Repository interfaces
├── data/                 # The Implementation (Details)
│   ├── repositories/     # Concrete implementations of domain interfaces
│   ├── data_sources/     # Remote (API) or Local (SQLite/Prefs) sources
│   ├── models/           # DTOs with toJson/fromJson
│   └── mappers/          # Model to Entity mappers
└── presentation/         # Framework-specific delivery (UI)
    ├── controllers/      # Riverpod providers or Signals
    ├── widgets/          # Feature-specific reusable widgets
    └── views/            # Main Screens/Pages
```

### Dependency Rules:
1. **Domain**: The core. Zero dependencies on `data`, `presentation`, or external packages.
2. **Data**: Depends on `domain` to implement the contracts.
3. **Presentation**: Depends on `domain` (for business logic) and `data` (injected via DI).

## ✅ ALWAYS vs ❌ NEVER

| 🟢 ALWAYS | 🔴 NEVER |
| :--- | :--- |
| Use **Riverpod** with `@riverpod` (codegen). | Use `ChangeNotifier` or global singletons. |
| Use **const** constructors by default. | Create widgets without `const` when possible. |
| Use **GoRouter** for all navigation. | Use the legacy Navigator 1.0. |
| Use **L10n** (AppLocalizations) for strings. | Hardcode strings in widgets. |
| Keep widget files under 150 lines. | Create "Mega-Widgets" with giant build methods. |
| Use **snake_case** for filenames. | Use `index.dart` (Strictly forbidden). |
| Map DTOs to Entities in the Data layer. | Leak API models into the UI or Domain layers. |
| Use **sealed classes** for UI states. | Use multiple boolean flags (isLoading, isError). |

## 🚀 Specialized Scaffolding Logic

1. **Feature Isolation**: A feature folder contains EVERYTHING it needs. Shared logic belongs in `lib/core/`.
2. **Repository Pattern**: All external data MUST go through a Repository. No direct API calls in controllers.
3. **Immutability**: Entities and DTOs MUST be immutable (use `@freezed` if possible).
4. **Theme-Driven UI**: Access colors and styles only via `Theme.of(context)` or custom extensions.

## 🛠 Communication Protocol

- **No Snippets**: Provide full, production-ready files.
- **No Placeholders**: Write the actual logic (e.g., full form validation, full error handling).
- **Architecture First**: Before writing code, briefly explain the feature structure you are following.

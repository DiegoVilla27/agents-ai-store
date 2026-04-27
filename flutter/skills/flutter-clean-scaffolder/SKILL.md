---
name: flutter-clean-scaffolder
description: Expert in generating professional Clean Architecture and Feature-First scaffolding for Flutter.
author: Antigravity
trigger: When the user wants to initialize a project structure or add a new modular feature.
---

# Flutter Clean Scaffolder

This skill automates the creation of a robust, production-grade Flutter directory structure following Clean Architecture and Feature-First patterns.

## ✅ ARCHITECTURE RULES
1. **Core First**: Initialize `lib/core` with networking (Dio), routing (GoRouter), and theming.
2. **Feature Isolation**: Every new feature must live in `lib/features/{feature_name}`.
3. **Layer Separation**:
   - **Domain**: Entities, Repositories (interfaces), UseCases. No external dependencies.
   - **Data**: Models (DTOs), Mappers, Repositories (impl), DataSources.
   - **Presentation**: Screens, Widgets (local), Providers/Blocs.
4. **Shared UI**: Global widgets go to `lib/shared/{atoms,molecules,organisms}`.
5. **Testing**: Mirrors the `lib/` structure in the `test/` directory.

## 🛠 COMMANDS
When this skill is triggered, you must:

### 1. Initialize Base Structure
Create the following directories if they don't exist:
- `lib/core/{router,theme,network,error,l10n,utils}`
- `lib/shared/{atoms,molecules,organisms}`
- `lib/features`

### 2. Scaffold a New Feature
For a given `{feature_name}`, create:
- `lib/features/{feature_name}/domain/{entities,repositories,usecases}`
- `lib/features/{feature_name}/data/{models,mappers,repositories,datasources}`
- `lib/features/{feature_name}/presentation/{screens,widgets,providers}`
- `test/features/{feature_name}/domain/usecases`
- `test/features/{feature_name}/data/repositories`
- `test/features/{feature_name}/presentation/screens`

## 📝 FILE TEMPLATES
Always generate boilerplate for:
- **Failure classes** in `core/error/failures.dart`.
- **Base UseCase** interface in `core/usecases/usecase.dart`.
- **Entity to Model Mappers** using extensions.

---
description: 'Flutter-specific coding standards and modular architecture'
applyTo: '**/*.dart'
---

# Flutter Development Instructions

Instructions for generating professional, scalable Flutter applications using **Clean UI Logic** and **Feature-based Modular Architecture**.

## Project Context

- **Framework**: Flutter (Latest Stable)
- **State Management**: Riverpod (preferred) or Signals
- **Routing**: GoRouter (Modular category-based)
- **Styling**: Theme-driven, custom widgets with atomic scoping
- **Localization**: L10n required for all strings

## Development Standards

### Architecture & Naming

- **Modular Architecture (Vertical Slices)**: Group all related assets within the feature folder:
  - `lib/features/[feature]/widgets/`: Screen-specific UI components.
  - `lib/features/[feature]/logic/`: ChangeNotifiers, Providers, or Services.
  - `lib/features/[feature]/models/`: Data classes and DTOs.
  - `lib/features/[feature]/validations/`: Form logic and validators.
- **Naming Conventions**:
  - **NEVER** use `index.dart`.
  - Use descriptive **snake_case** for filenames matching the widget/class name (e.g., `primary_button.dart`, `home_screen.dart`).
  - Use **PascalCase** for classes and **camelCase** for variables/instances.
- **Atomic Scoping**: Local widgets for screen-specific UI should stay in the feature folder. Promote to `lib/common/widgets/` only if used in >3 screens.

### UI & Widgets

- **Const Constructors**: Use `const` by default for all widgets to improve performance.
- **Line Limit**: No widget file shall exceed 200 lines. Fragment large widgets into sub-widgets.
- **SafeAreas**: Every screen must respect `SafeArea` and use a properly configured `Scaffold`.
- **L10n**: Never hardcode strings. Use `context.l10n.key`.

### Logic & State Management

- **Riverpod**: Use `ConsumerWidget` or `ConsumerStatefulWidget` for reactive state.
- **Dependency Injection**: Use providers to inject dependencies rather than global singletons.
- **Async Safety**: Always handle loading and error states in the UI.

### Navigation

- Manage routes exclusively with **GoRouter**.
- Define routes in modular, categorized files (e.g., `lib/core/router/private/dashboard_routes.dart`).

## Implementation Protocol

1. **Locality Analysis**: Determine if a widget belongs to a feature or common.
2. **Feature Scaffolding**: Create the modular subfolders (widgets, logic, models).
3. **Route Registration**: Add the new screen to the appropriate categorization in `lib/core/router/`.
4. **Fragmentation**: Break down the UI into small, manageable `const` widgets.
5. **Localization**: Add all strings to the `.arb` files and use the generated L10n.

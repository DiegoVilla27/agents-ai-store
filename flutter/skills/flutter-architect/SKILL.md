---
name: flutter-architect
description: >
  Guardian of scalable, maintainable, and professional-grade Flutter codebases.
  Trigger: When defining project structure, creating new screens, or organizing widgets.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Atomic Scoping (REQUIRED)

Component hierarchy must follow the proximity rule to avoid global clutter.

```dart
// ✅ ALWAYS: Local widgets for screen-specific UI
// lib/screens/settings/widgets/logout_button.dart

// ❌ NEVER: Global UI for orphan elements
// lib/ui/widgets/settings_logout_button_only_used_once.dart
```

---

## Semantic Screen Structure (REQUIRED)

Directory structure must reflect navigation and access levels.

| Path | Purpose |
|------|---------|
| `/public/` | Free access (Login, Onboarding, Register). |
| `/private/` | Auth-protected (Dashboard, Settings, Profile). |
| `/common/` | Shared (Splash, 404, Global Modals). |

---

## Clean UI Logic (REQUIRED)

```dart
// ✅ ALWAYS: Const by default, injected L10n, and extensions
const MyWidget({super.key});
Text(context.l10n.welcomeTitle);

// ❌ NEVER: Hardcoded strings or giant widgets
Text("Welcome to my app"); // Use L10n instead
// Widgets exceeding 200 lines must be fragmented.
```

---

## Modular Routing (REQUIRED)

Routing must be managed exclusively with `go_router` in a modular way.

```dart
// ✅ ALWAYS: Categorized routes
// lib/core/router/public/auth_routes.dart
// lib/core/router/private/user_routes.dart

// ❌ NEVER: Monolithic router
// Do not put all routes in a single giant file.
```

---

## Execution Protocol (REQUIRED)

1. **Analyze Locality**: Before creating a widget, ask: "Will it be used elsewhere?".
2. **Route Registration**: Update the corresponding category in `/lib/core/router/`.
3. **Fragmentation**: Divide complex screens into sub-widgets with descriptive names.
4. **Optimization**: Ensure widgets don't rebuild the entire tree unnecessarily.

---

## Uncompromising Constraints

- **Line Limit**: No widget file shall exceed 200 lines.
- **Promotion Rule**: If a local widget repeats in 3 screens, promote it to Global (`lib/ui/`).
- **SafeAreas**: Every screen must respect `SafeAreas` and have a well-configured `Scaffold`.

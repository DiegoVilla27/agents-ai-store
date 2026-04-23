---
description: 'Declarative Routing and Deep Linking with GoRouter'
author: 'Diego Villanueva'
trigger: 'When implementing app navigation, deep links, or complex nested routing.'
---

# Flutter Navigation & Routing

Advanced navigation management using the `go_router` package for declarative, URL-based routing.

## ✅ ALWAYS
- Define routes in a centralized, modular configuration.
- Use `GoRouter` for deep linking support and declarative state.
- Use `context.go()` for absolute navigation and `context.push()` for stack-based navigation.
- Implement `redirect` logic for authentication and authorization.
- Handle error states with a custom `errorBuilder`.

## ❌ NEVER
- Use `Navigator.of(context).push()` in a `go_router` application.
- Hardcode route names or paths; use a constant class or enums.
- Perform heavy logic inside route builders.

## 🛠 Patterns
- **ShellRoute**: For common UI elements like Bottom Navigation Bars.
- **Typed Routes**: Using `go_router_builder` for type-safe navigation.

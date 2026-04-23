---
description: 'Complex Navigation Structures and Deep Linking'
author: 'Diego Villanueva'
trigger: 'When implementing nested navigators, shared element transitions, or deep linking.'
---

# Advanced React Native Navigation

Mastery of complex navigation flows using React Navigation or Expo Router.

## ✅ ALWAYS
- Define a strict `ParamList` for type-safe navigation.
- Implement **Deep Linking** using a centralized configuration.
- Use `Shared Element Transitions` for premium screen-to-screen animations.
- Use `useNavigation` and `useRoute` hooks for accessing navigation state.
- Implement a `NavigationContainer` with persistence for better dev experience.

## ❌ NEVER
- Pass giant objects as navigation parameters; pass IDs and fetch data in the target screen.
- Create too many nested navigators (performance impact).
- Forget to handle the "Back" button behavior on Android.

## 🛠 Patterns
- **Auth Flow**: Dynamically switching between Login and Main navigators based on auth state.
- **Modal Stack**: Managing full-screen modals with specific transition presets.

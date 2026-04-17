---
description: 'React Native & Expo coding standards with vertical slicing'
applyTo: '**/*.tsx, **/*.ts, **/*.js, **/*.jsx'
---

# React Native Development Instructions

Instructions for generating high-quality mobile applications with **React Native** and **Expo** using **Modern Patterns** and **Modular Architecture**.

## Project Context

- **Platform**: Expo-first (using EAS for builds)
- **State Management**: Zustand (Client) & TanStack Query (Server)
- **Styling**: **Styled Components** for component-level styling and theming.
- **Framework**: React 19 compatibility

## Development Standards

### Architecture & Components

- **Modular Architecture (Vertical Slices)**: Organize code by features/screens:
  - `src/features/[feature]/components/`: UI segments.
  - `src/features/[feature]/hooks/`: Specialized logic.
  - `src/features/[feature]/validations/`: Form schemas (Zod).
  - `src/features/[feature]/data/`: API services and mocks.
- **Index Pattern**: Use `index.tsx` within folders to allow clean imports.
  - *Example*: `import { UserCard } from './components/user-card'` (instead of `./components/user-card/user-card.tsx`).
- **Semantic Components**: Use `Pressable` instead of `TouchableOpacity` as the default interaction component for better control.

### Performance & Optimization

- **FlatList Optimization**: Always use `memoized` render items and `keyExtractor`. Use `initialNumToRender` to avoid blocking the main thread.
- **Image Optimization**: Use `expo-image` for high-performance image caching and loading.
- **Memory Safety**: Clean up listeners and timers in `useEffect` cleanup functions.
- **Feedback**: Every interactive element must provide visual/haptic feedback.

### Platform & Layout

- **Flexbox**: Use the Yoga engine defaults (Flexbox).
- **Safe Areas**: Wrap root screens in `SafeAreaView` from `react-native-safe-area-context`.
- **Platform Specifics**: Use `Platform.OS` or `.ios.tsx` / `.android.tsx` extensions for platform-dependent logic.

### State Management

- **Zustand**: Use selectors and shallow equality checks for performance.
- **TanStack Query**: Abstract Queries and Mutations into custom hooks within the feature folders.

## Implementation Protocol

1. **Locality Definition**: Decide if a component is feature-specific or a reusable atom.
2. **Feature Scaffolding**: Create the modular directory structure (`components`, `hooks`, etc.).
3. **Core Interface**: Define TypeScript types and Zod schemas.
4. **UI Layout**: Build using atomic components, `Pressable`, and `styled-components/native`.
5. **Optimization**: Review list performance and asset loading.
6. **Navigation Integration**: Register screens with Expo Router or React Navigation.

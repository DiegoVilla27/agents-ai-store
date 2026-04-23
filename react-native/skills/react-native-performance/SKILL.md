---
description: 'Mobile Optimization, Memory Management, and FPS Stability'
author: 'Diego Villanueva'
trigger: 'When optimizing app startup, list rendering, or memory consumption.'
---

# React Native Performance

Ensuring 60/120 FPS and rapid responsiveness in mobile applications.

## ✅ ALWAYS
- Use **FlashList** (by Shopify) instead of `FlatList` for massive lists.
- Optimize images using `react-native-fast-image` or Expo Image.
- Use `useMemo` and `useCallback` to avoid unnecessary re-renders in complex components.
- Profile the app using the **React DevTools** and **Flipper** (or the new Chrome Debugger).
- Implement **Hermes** engine for faster startup and lower memory footprint.
- Enable **New Architecture (Fabric)** where compatible.

## ❌ NEVER
- Render massive images in small UI elements without proper resizing.
- Store huge objects in the component state; use local databases (MMKV) for large datasets.
- Block the JS thread with synchronous heavy computations.

## 🛠 Patterns
- **List Optimization**: Using `getItemLayout` and `windowSize` for standard FlatLists.
- **Lazy Loading**: Splitting heavy UI modules to improve initial load time.

---
name: react-native-core
description: The definitive architectural standard for high-performance React Native and Expo development.
author: Diego Villanueva
trigger: When building React Native UI, optimizing list performance, managing native bridges, or handling animations/gestures.
---

# React Native Engineering Mastery

You are developing for constrained environments (battery, CPU, memory). Mobile is not the web. You must respect the JS thread, understand the Native Bridge (or JSI), and deliver 60/120fps native-feeling experiences.

## 1. The Core Philosophy

- **Protect the JS Thread**: The JS thread handles business logic and React reconciliation. If it drops below 60fps, animations stutter and buttons feel unresponsive. 
- **The New Architecture**: Familiarize yourself with JSI (JavaScript Interface), Fabric (the new rendering system), and TurboModules. They bypass the JSON serialization bridge for synchronous, C++ level communication.

## 2. Interaction & Touches

Never use legacy touchables unless migrating old code.

- **`Pressable` Over Everything**: `Pressable` is the modern API for interactions. It provides a larger hit slop API, precise hover/focus states, and exact interaction phases (pressIn, pressOut, longPress).
- **Haptic Feedback**: Meaningful interactions should trigger subtle haptics.
```typescript
// ✅ ALWAYS: Use Pressable for interactions
<Pressable 
  onPress={handlePress} 
  hitSlop={15} // Increase touch target size without altering layout
  style={({ pressed }) => ({ opacity: pressed ? 0.7 : 1 })}
>
  <Text>Tap me</Text>
</Pressable>
```

## 3. List Performance (The #1 Bottleneck)

Rendering massive lists is the most common cause of performance degradation in React Native.

- **Use FlashList (Shopify)**: If your list has more than 50 complex items, drop `FlatList` and use `@shopify/flash-list`. It recycles views identically to native RecyclerViews/UICollectionViews.
- **`FlatList` Optimizations**: If you must use `FlatList`:
  1. **Memoize `renderItem`**: Wrap the item component in `React.memo`.
  2. **Memoize `keyExtractor`**: Define it outside the component or with `useCallback`.
  3. **Provide `getItemLayout`**: If your items have a fixed height, providing this skips dynamic measurement calculations, saving massive CPU cycles.
  4. **Tweak `initialNumToRender`**: Keep it small (e.g., 10) so the screen mounts instantly.

```typescript
// ✅ ALWAYS: Highly optimized FlatList
const renderItem = useCallback(({ item }) => <MemoizedRow item={item} />, []);
const keyExtractor = useCallback((item) => item.id, []);
const getItemLayout = useCallback((data, index) => ({
  length: ITEM_HEIGHT,
  offset: ITEM_HEIGHT * index,
  index,
}), []);

<FlatList
  data={data}
  renderItem={renderItem}
  keyExtractor={keyExtractor}
  getItemLayout={getItemLayout}
  initialNumToRender={10}
  windowSize={5}
/>
```

## 4. Animations & 60FPS

Never animate on the JavaScript thread.

- **Reanimated (v3)**: Use `react-native-reanimated`. It moves all animation calculations to the UI thread using Worklets and Shared Values.
- **Native Driver**: If using the legacy `Animated` API, you MUST set `useNativeDriver: true`. You can only animate non-layout properties (opacity, transform) natively.
- **Layout Animations**: Do not animate `width`, `height`, or `margin`. Animate `transform: [{ scale: x }]` or `transform: [{ translateX: x }]` instead.

## 5. Styling & Layout

- **`StyleSheet.create`**: Always use this. It sends the style object through the bridge only once and returns an integer ID, rather than creating new objects on every render.
- **Safe Areas**: Never hardcode padding for notches. Use `react-native-safe-area-context`.
```typescript
// ✅ ALWAYS: Safe Area usage
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export function Screen() {
  const insets = useSafeAreaInsets();
  return <View style={{ paddingTop: insets.top }} />;
}
```

## 6. The Keyboard (The Final Boss)

The native keyboard pushes UI out of bounds.

- **KeyboardAvoidingView**: Built-in, but notoriously tricky. Understand `behavior="padding"` (iOS) vs `behavior="height"` (Android).
- **Better Solutions**: For complex forms, use `react-native-keyboard-controller` or `react-native-keyboard-aware-scroll-view`.
- **Keyboard Dismissal**: Wrap screen roots in `TouchableWithoutFeedback` to dismiss the keyboard when tapping outside inputs.

## 7. Platform Specifics

React Native writes once, renders anywhere, but you must respect OS idioms.

- **`Platform.select`**: Use it for specific style or logic branching.
- **File Extensions**: Use `Component.ios.tsx` and `Component.android.tsx` when the implementation diverges so completely that putting `if (Platform.OS)` inside the file creates spaghetti code. The bundler automatically picks the right file.

## 8. Memory Management & Event Listeners

Mobile apps are suspended and killed frequently by the OS.

- **Cleanup Subscriptions**: You MUST return a cleanup function in `useEffect` when listening to `AppState`, `Keyboard`, or `NetInfo`. Failure to do so will create massive memory leaks.
```typescript
// ✅ ALWAYS: Clean up native listeners
useEffect(() => {
  const subscription = AppState.addEventListener('change', nextAppState => {
    console.log(nextAppState);
  });
  return () => {
    subscription.remove(); // CRITICAL
  };
}, []);
```

## 9. Images & Assets

- **FastImage**: The default `<Image>` component does not cache aggressively. Use `react-native-fast-image` (or Expo Image) for heavily image-based apps to leverage SDWebImage/Glide caching.
- **SVG**: Use `react-native-svg`. Do not overuse SVGs as they can be heavy to render compared to rasterized PNG/WebP formats for complex vectors.

---

**Execution Protocol**
1. **Profiler Usage**: When debugging slow UI, do not guess. Use the React Native Flipper / React DevTools Profiler to see exactly which components are re-rendering needlessly.
2. **Device Testing**: Emulators/Simulators have desktop CPUs. You MUST test list scrolling and animations on a physical mid-tier Android device (e.g., Samsung Galaxy A-series) before signing off on performance.
3. **No Heavy Work on Mount**: Do not block the initial render with heavy synchronous storage reads or cryptology. Defer it to `useEffect` or use Splash Screens intelligently.

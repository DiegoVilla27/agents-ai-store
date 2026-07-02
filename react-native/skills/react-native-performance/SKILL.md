---
name: react-native-performance
description: The ultimate architectural standard for achieving 60/120 FPS, minimizing memory consumption, and optimizing startup times in React Native.
author: Diego Villanueva
trigger: When diagnosing lag, Out Of Memory (OOM) crashes, optimizing list scrolling, or analyzing render cycles.
---

# Mobile Performance & Optimization Mastery

In mobile development, performance is not a refactoring step; it is the foundation. You are executing JavaScript on devices with aggressive thermal throttling, limited RAM, and small batteries. A dropped frame or a 5-second startup time directly translates to user churn.

## 1. The Engine & Architecture (Hermes & Fabric)

- **Hermes Engine**: ALWAYS ensure Hermes is enabled. It compiles JS to bytecode Ahead-Of-Time (AOT), bypassing parsing at runtime. This drastically reduces Time To Interactive (TTI) and memory footprint compared to V8 or JSC.
- **The New Architecture (Fabric)**: Migrate to Fabric when possible. It removes the asynchronous JSON bridge, allowing React to directly manipulate the native UI tree via C++ (JSI), enabling synchronous measurements and tear-free rendering.

## 2. Image Management (Preventing OOM Crashes)

The #1 cause of Out Of Memory (OOM) crashes in React Native is loading massive images into memory.

- **Never use the default `<Image>` for remote assets**: It has terrible caching and memory management. Use **Expo Image** or `react-native-fast-image`.
- **CDN Resizing**: NEVER download a 3000x3000px image from AWS S3 just to display it in a 50x50px avatar circle. The device has to decode the entire 3000px bitmap into RAM (which can take 30MB+ per image). ALWAYS request a resized image from your CDN (e.g., `?width=150`).
- **Memory Caching Strategy**: Clear the image cache aggressively if the app receives a memory warning from the OS.

## 3. List Performance (FlashList is Mandatory)

If you render lists of more than 50 complex items, `FlatList` will drop frames.

- **Use `@shopify/flash-list`**: It recycles native views (like `UICollectionView` / `RecyclerView`), keeping memory flat regardless of whether you have 100 or 100,000 items.
- **Optimizing RenderItem**: 
  - NEVER define anonymous functions inside `renderItem`.
  - ALWAYS wrap list items in `React.memo`.
  - Pass primitives as props, not complex objects that change reference.

```tsx
// ❌ WRONG: Creates a new function and a new object every scroll frame
<FlashList
  data={data}
  renderItem={({ item }) => <Row onPress={() => handle(item)} style={{ margin: 5 }} />}
/>

// ✅ ALWAYS: Extracted, stable references
const renderItem = useCallback(({ item }) => <Row id={item.id} />, []);
<FlashList data={data} renderItem={renderItem} estimatedItemSize={100} />
```

## 4. Master React Render Cycles

React Native bridges every UI update. Unnecessary re-renders are exponentially more expensive here than on the web.

- **`React.memo`**: Use it for heavy components, but remember it does a shallow comparison.
- **Context API Traps**: If you put a complex object in a Context Provider without `useMemo`, EVERY consumer will re-render whenever the provider's parent re-renders, even if the data didn't change.

```tsx
// ✅ ALWAYS: Memoize Context Values
export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  
  // If you don't memoize this, the entire app re-renders on any state change
  const value = useMemo(() => ({ user, setUser }), [user]);
  
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
```

## 5. Startup Time (Time to Interactive)

The app must be usable in under 2 seconds.

- **Inline Requires**: React Native supports lazy evaluation. Instead of importing heavy libraries at the top of the file, require them inside the function where they are used. This prevents parsing massive JS files at boot.
- **Defer Non-Critical Work**: If you need to sync a local database, fetch analytics configurations, or pre-load fonts, do it in a `useEffect` after the first paint. Do not block the initial mount.

```typescript
// ❌ WRONG: Blocks startup parsing a massive library
import HeavyCryptoLibrary from 'crypto-js';

// ✅ ALWAYS: Inline Require (Lazy Evaluation)
function handleEncrypt(data) {
  const HeavyCryptoLibrary = require('crypto-js');
  return HeavyCryptoLibrary.encrypt(data);
}
```

## 6. Animations (The 60 FPS Rule)

- **UI Thread Only**: All animations must run on the UI thread. Use `react-native-reanimated` (v3). 
- **No Layout Animations**: Never animate `width`, `height`, `top`, or `left`. This forces the native layout engine (Yoga) to recalculate the entire screen layout 60 times a second. Animate `transform: [{ translateX }]` and `transform: [{ scale }]` instead.

## 7. Memory Leaks (The Silent Killers)

Mobile OSes will forcefully terminate your app if it hoards memory in the background.

- **Navigation Stacks**: If you push 20 screens onto a Stack Navigator, all 20 screens are kept alive in memory. Use `navigation.replace()` when appropriate, or reset the stack if the user completes a deep flow.
- **Event Listeners**: If you attach a `Keyboard` or `AppState` listener in a `useEffect` and forget to call `.remove()` in the cleanup function, that component will never be garbage collected.
- **Zombies**: Avoid storing massive arrays of data in global state (Redux/Zustand) if they are only needed on one screen. Clear them out when unmounting.

## 8. Profiling and Metrics

You cannot optimize what you do not measure.

- **React DevTools Profiler**: Use it to record a session and find components that re-render for no reason (indicated by yellow/red bars).
- **Hermes Profiler**: Take a heap snapshot to find memory leaks. If you see thousands of unmounted React components still in the heap, you have a leak.
- **Sentry Performance**: Monitor the P75 and P95 load times of your most critical screens in production. 

---

**Execution Protocol**
1. **Physical Devices Only**: Never sign off on performance based on the iOS Simulator or Android Emulator. They run on M-series desktop CPUs. You MUST test on a 4-year-old Android device.
2. **Zero `console.log` in Prod**: The React Native bridge gets choked by excessive logging. Use a babel plugin to strip all `console.log` statements in production builds.
3. **Bundle Size**: Audit your JS bundle periodically. A massive JS bundle increases RAM usage and parsing time. Avoid libraries like `moment.js`; use `date-fns` or native `Intl`.

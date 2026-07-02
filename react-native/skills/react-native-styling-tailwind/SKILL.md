---
name: react-native-styling-tailwind
description: The ultimate architectural standard for utility-first styling in React Native using NativeWind (Tailwind CSS), ensuring cross-platform consistency and high performance.
author: Diego Villanueva
trigger: When styling React Native components, configuring themes, writing conditional classes, or handling platform-specific styles with NativeWind.
---

# NativeWind & Tailwind CSS Architecture

React Native uses the Yoga engine for layout, which implements a subset of CSS Flexbox. Styling natively requires clunky `StyleSheet.create` objects. NativeWind bridges this gap, allowing you to use standard Tailwind CSS classes to style mobile applications with Ahead-Of-Time (AOT) compilation performance.

## 1. The Core Philosophy (NativeWind v4+)

- **Utility-First**: Keep styles co-located with the component.
- **AOT Compilation**: NativeWind compiles Tailwind classes into static `StyleSheet` objects at build time. It does *not* parse massive strings at runtime, maintaining 60FPS UI performance.
- **Strict Tokens**: Stick to your predefined `tailwind.config.js` theme. 

## 2. Dynamic Class Merging (The `cn()` Pattern)

Just like on the web, string concatenation (`className={`bg-blue-500 ${isActive ? 'bg-red-500' : ''}`}`) is fragile. Always use a `cn()` utility (clsx + tailwind-merge).

```typescript
// ✅ ALWAYS: Use a utility for conditional and merged classes
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Usage
<View className={cn("flex-1 p-4 rounded-xl", isActive && "bg-blue-500")} />
```

## 3. Platform Specific Styling

React Native renders on multiple distinct platforms. NativeWind provides platform modifiers that are far cleaner than `Platform.OS === 'ios'`.

- **`ios:`**, **`android:`**, **`web:`**

```tsx
// ✅ ALWAYS: Use platform modifiers for specific tweaks
// Adds a bottom shadow on iOS, and elevation on Android
<View className="bg-white ios:shadow-sm android:elevation-2" />

// Adjust padding specifically for Android's status bar behavior
<View className="pt-4 android:pt-8" />
```

## 4. Wrapping Third-Party Components (The `cssInterop` or `styled` approach)

Native React Native components (`View`, `Text`, `Pressable`) support the `className` prop out of the box with NativeWind. However, if you import a third-party library component (e.g., `<FastImage>`), it will ignore `className`.

You must register the component so NativeWind knows which prop to map the classes to.

```tsx
// ✅ ALWAYS: Map third-party components to NativeWind
import { cssInterop } from 'nativewind';
import FastImage from 'react-native-fast-image';

// Tell NativeWind to map `className` to the `style` prop of FastImage
cssInterop(FastImage, { className: 'style' });

export function Avatar() {
  // Now it works perfectly!
  return <FastImage className="w-12 h-12 rounded-full" source={{ uri: '...' }} />;
}
```

## 5. Dark Mode Strategy

NativeWind synchronizes automatically with the device's color scheme.

- **The `dark:` Modifier**: Use it exactly as you would on the web.
- **Manual Override**: Use the `useColorScheme` hook from `nativewind` to toggle the theme manually within the app.

```tsx
// ✅ ALWAYS: First-class dark mode support
import { useColorScheme } from 'nativewind';

export function Card() {
  const { colorScheme, toggleColorScheme } = useColorScheme();

  return (
    <Pressable 
      onPress={toggleColorScheme}
      className="bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800"
    >
      <Text className="text-gray-900 dark:text-white">Current: {colorScheme}</Text>
    </Pressable>
  );
}
```

## 6. Mobile Layout Constraints (Crucial Differences from Web)

React Native's Yoga engine is NOT a web browser. You must respect these differences:

1. **Flex Direction**: In React Native, the default `flexDirection` is `column`, not `row`! If you want a row, you MUST explicitly write `flex-row`.
2. **No Grid (Mostly)**: While NativeWind attempts to polyfill CSS Grid, it is computationally heavy and buggy on mobile. Use Flexbox (`flex-row`, `flex-wrap`, `w-1/2`) for all complex layouts.
3. **No Pseudo-Classes without state**: Classes like `hover:` or `focus:` are only partially supported and often require wrapping elements in `Pressable`. Hover only makes sense on Web/iPad. `active:` works well on mobile.

```tsx
// ✅ ALWAYS: Explicit flex-row
<View className="flex-row items-center justify-between" />

// ✅ ALWAYS: Use active: for tap states
<Pressable className="bg-blue-500 active:bg-blue-600 rounded-lg p-4" />
```

## 7. Safe Areas & Insets

Mobile devices have notches, dynamic islands, and home indicators. You must not render UI underneath them.

While you *can* use safe area view components, the most flexible approach is combining NativeWind with `useSafeAreaInsets` to generate dynamic padding classes.

```tsx
// ✅ ALWAYS: Handle safe areas with inline styles for precise control
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export function Screen() {
  const insets = useSafeAreaInsets();
  
  return (
    <View 
      className="flex-1 bg-white" 
      style={{ paddingTop: insets.top, paddingBottom: insets.bottom }}
    >
      <Text>Safe Content</Text>
    </View>
  );
}
```

## 8. Typography and Custom Fonts

To use custom fonts (e.g., Inter, Roboto) with NativeWind, map them in your `tailwind.config.js`.

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter-Regular', 'sans-serif'],
        bold: ['Inter-Bold', 'sans-serif'],
      },
    },
  },
};
```
Then use them via `font-sans` or `font-bold`.

---

**Execution Protocol**
1. **Never use Arbitrary Values for spacing/colors**: Do not use `w-[327px]` or `bg-[#ff0000]`. Expand your `tailwind.config.js` theme instead to maintain design consistency.
2. **Prettier Sorting**: You MUST use `prettier-plugin-tailwindcss` to ensure classes are always sorted in the same order (Layout -> Typography -> Visuals -> Modifiers).
3. **StyleSheet Fallback**: If an animation requires animating layout properties rapidly, fall back to `react-native-reanimated` with standard `useAnimatedStyle`. NativeWind classes cannot be smoothly animated via Shared Values at 60fps yet.

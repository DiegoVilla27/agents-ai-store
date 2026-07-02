---
name: react-native-reanimated
description: The ultimate architectural standard for writing 60/120 FPS synchronous UI animations and gesture handling using React Native Reanimated (v3+).
author: Diego Villanueva
trigger: When building complex animations, interpolations, shared element transitions, or integrating gestures in React Native.
---

# React Native Reanimated Mastery (v3+)

React Native's default `Animated` API is limited. To achieve true 60/120 FPS animations that do not drop frames when the JavaScript thread is busy (e.g., during a network fetch or complex state calculation), you must move animation logic entirely to the UI thread. Reanimated achieves this using C++ and Worklets.

## 1. The Core Philosophy (JS Thread vs UI Thread)

- **The JS Thread**: Where React runs. If this thread blocks, the app logic freezes.
- **The UI Thread**: Where the OS renders pixels. If this thread blocks, the app visually freezes.
- **Worklets**: Tiny JavaScript functions that are extracted by Babel, compiled, and executed synchronously on the UI thread. Reanimated runs your animations here.

## 2. Shared Values (The Foundation)

Shared values are the equivalent of React's `useState`, but they exist simultaneously on the JS thread and the UI thread.

- **Initialization**: Use `useSharedValue`.
- **Mutation**: Mutate the `.value` property. This mutation is instantly reflected on the UI thread without crossing the React Native bridge.

```tsx
// ✅ ALWAYS: Use Shared Values for animation state
import { useSharedValue, withSpring } from 'react-native-reanimated';

export function Box() {
  const width = useSharedValue(100);

  const handlePress = () => {
    // Mutates instantly on the UI thread
    width.value = withSpring(width.value + 50); 
  };
}
```

## 3. Animated Styles

You cannot pass a Shared Value directly to a standard `View`. You must use `Animated.View` and `useAnimatedStyle`.

- **`useAnimatedStyle`**: This hook automatically creates a worklet. It re-evaluates *only* on the UI thread whenever its dependent shared values change. It does *not* trigger a React component re-render.

```tsx
// ✅ ALWAYS: Connect Shared Values to UI via useAnimatedStyle
import Animated, { useAnimatedStyle } from 'react-native-reanimated';

export function AnimatedBox({ offset }: { offset: SharedValue<number> }) {
  // This function runs on the UI thread!
  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ translateX: offset.value }],
    };
  });

  // Must use Animated.View, not standard View
  return <Animated.View style={[styles.box, animatedStyle]} />;
}
```

## 4. Worklets & Thread Crossing

Sometimes you need to run code on the UI thread, but then trigger something on the JS thread (like updating a Redux store or navigating to a new screen when an animation finishes).

- **`runOnJS`**: Calls a JavaScript function from a UI thread worklet.
- **`runOnUI`**: Calls a UI thread worklet from the JavaScript thread.

```tsx
// ✅ ALWAYS: Explicitly cross threads when needed
import { runOnJS, withTiming } from 'react-native-reanimated';

function JSCallback(finalValue: number) {
  console.log('Animation finished at:', finalValue); // Runs on JS thread
}

const handlePress = () => {
  offset.value = withTiming(100, {}, (finished) => {
    if (finished) {
      // The callback runs on the UI thread, so we must dispatch to JS
      runOnJS(JSCallback)(offset.value);
    }
  });
};
```

## 5. Interpolation (Mapping Values)

Interpolation maps an input range (like a scroll offset) to an output range (like opacity or color).

- **`interpolate`**: The workhorse for mapping numbers.
- **`interpolateColor`**: specifically designed to transition smoothly between hex/rgb values.
- **Extrapolation**: Always define what happens if the input value goes beyond your defined range (e.g., `Extrapolate.CLAMP` stops it from overshooting).

```tsx
// ✅ ALWAYS: Clamp interpolations to prevent unexpected visual bugs
import { interpolate, Extrapolate, interpolateColor } from 'react-native-reanimated';

const animatedStyle = useAnimatedStyle(() => {
  const opacity = interpolate(
    scrollOffset.value,
    [0, 100],      // Input range
    [1, 0],        // Output range
    Extrapolate.CLAMP // Don't let opacity go below 0 or above 1
  );

  const backgroundColor = interpolateColor(
    scrollOffset.value,
    [0, 100],
    ['#ffffff', '#000000']
  );

  return { opacity, backgroundColor };
});
```

## 6. Gesture Integration

Reanimated pairs perfectly with `react-native-gesture-handler`. The gesture events fire directly on the UI thread.

```tsx
// ✅ ALWAYS: Handle gestures on the UI thread
import { Gesture, GestureDetector } from 'react-native-gesture-handler';

export function DraggableBox() {
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const context = useSharedValue({ x: 0, y: 0 });

  const panGesture = Gesture.Pan()
    .onStart(() => {
      context.value = { x: translateX.value, y: translateY.value };
    })
    .onUpdate((event) => {
      translateX.value = context.value.x + event.translationX;
      translateY.value = context.value.y + event.translationY;
    })
    .onEnd(() => {
      translateX.value = withSpring(0);
      translateY.value = withSpring(0);
    });

  const style = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value }
    ]
  }));

  return (
    <GestureDetector gesture={panGesture}>
      <Animated.View style={[styles.box, style]} />
    </GestureDetector>
  );
}
```

## 7. Layout Animations

Reanimated proporciona animaciones mágicas de una sola línea para componentes que se montan, desmontan o cambian de diseño.

- **Entering/Exiting**: Define how a component appears or disappears.
- **Layout Transitions**: Automatically animate layout changes (e.g., when an item is deleted from a list and the others slide up).

```tsx
// ✅ ALWAYS: Use built-in layout animations for lists/modals
import Animated, { FadeIn, SlideOutLeft, LinearTransition } from 'react-native-reanimated';

export function ListItem({ item }) {
  return (
    <Animated.View 
      entering={FadeIn.duration(300)} 
      exiting={SlideOutLeft}
      layout={LinearTransition.springify()} // Smoothly animates repositioning
    >
      <Text>{item.title}</Text>
    </Animated.View>
  );
}
```

---

**Execution Protocol**
1. **Never Animate Layout Properties**: Do not animate `width`, `height`, `padding`, or `margin` in a `useAnimatedStyle` if it can be avoided. This forces the Yoga layout engine to recalculate on the UI thread. Always animate `transform` (`scale`, `translateX`) and `opacity` whenever physically possible.
2. **Worklet Debugging**: If you get an error saying *"Tried to synchronously call function on the JS thread"*, it means you tried to call a normal JavaScript function (like `console.log`, `setState`, or an API call) from inside `useAnimatedStyle` or a gesture handler. You MUST wrap that call in `runOnJS(myFunction)()`.
3. **Memoization Caution**: Do not put Shared Values inside dependency arrays (e.g., `useEffect(..., [sharedValue])`). They are objects with stable references. If you need to react to a shared value changing in JS, use `useAnimatedReaction`.

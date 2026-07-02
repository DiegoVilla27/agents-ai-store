---
name: flutter-performance
description: The ultimate architectural standard for Flutter Performance 120FPS Rendering, Memory Leak Prevention, OOM Image Optimization, and $O(1)$ ListView rendering.
author: Diego Villanueva
trigger: When optimizing UI frame rates, fixing memory leaks, loading high-res images, or debugging app crashes.
---

# Flutter Performance & Rendering Architecture

Flutter is designed to run at 60 or 120 FPS. If your app stutters (known as "Jank"), it is almost certainly a developer error. 

Performance issues fall into three categories:
1. **UI Jank**: Rebuilding the widget tree too often or doing heavy math in the `build` method.
2. **Raster Jank**: Forcing the GPU to draw complex shadows, opacity blends, or clipping paths too often.
3. **Memory Leaks**: Loading 4K images into RAM without resizing them or forgetting to dispose of controllers.

## 1. The `const` Keyword (The Ultimate Optimizer)

In React, you have to write `React.memo()` to prevent a component from re-rendering. In Flutter, you just use the `const` keyword.

When you declare a widget as `const`, Flutter instantiates it ONCE at compile time. When the parent widget rebuilds 60 times a second, Flutter sees the `const` widget and says: "I already have this in memory, I'm skipping it."

```dart
// ❌ ATROCIOUS: Creates a new Text instance every frame during an animation
return Column(
  children: [
    AnimatedWidget(),
    Text('Hello World'), 
  ]
);

// ✅ ALWAYS: Use const so this subtree is NEVER rebuilt
return Column(
  children: [
    AnimatedWidget(),
    const Text('Hello World'), 
  ]
);
```
*(Configure `analysis_options.yaml` to strictly enforce `prefer_const_constructors` and `prefer_const_literals_to_create_immutables`).*

## 2. Image Optimization (Preventing OOM Crashes)

If you load a 4K resolution (3840x2160) image from a server and display it in a `50x50` avatar container, Flutter will decode the ENTIRE 4K image into RAM. If you have a list of 20 avatars, your app will crash with an **Out Of Memory (OOM)** error.

```dart
// ❌ ATROCIOUS: Will crash the app if the remote image is huge
Image.network('https://acme.com/huge-photo.jpg', width: 50, height: 50);

// ✅ ALWAYS: Tell the rendering engine to decode the image at the exact size needed
Image.network(
  'https://acme.com/huge-photo.jpg', 
  width: 50, 
  height: 50,
  cacheWidth: 150, // Usually 2x or 3x the logical width to account for Retina displays
);
```

## 3. List Optimization (`itemExtent` & `ListView.builder`)

Never use `ListView(children: [...])` for long lists. It instantiates all children immediately. You MUST use `ListView.builder` for lazy loading.

Furthermore, if all items in your list have the exact same height, you MUST use `itemExtent` (or `prototypeItem`).

Without `itemExtent`, Flutter has to calculate the height of *every single item* to know how big the scrollbar should be. With `itemExtent`, the math becomes $O(1)$ instead of $O(N)$.

```dart
// ✅ ALWAYS: Use itemExtent for massive performance gains in uniform lists
ListView.builder(
  itemCount: 10000,
  itemExtent: 80.0, // Flutter instantly knows the list is exactly 800,000 pixels tall!
  itemBuilder: (context, index) => SizedBox(
    height: 80, 
    child: Text('Item $index'),
  ),
)
```

## 4. The Opacity Anti-Pattern

The `Opacity` widget is incredibly expensive. To apply opacity, Flutter has to paint the entire child widget into an offscreen buffer, apply the alpha channel, and paint it back onto the screen. 

If you animate the `Opacity` widget, you are forcing an offscreen render pass 60 times a second.

```dart
// ❌ ATROCIOUS: Kills GPU performance
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) => Opacity(
    opacity: _controller.value,
    child: ExpensiveWidget(),
  ),
);

// ✅ ALWAYS: Use AnimatedOpacity or FadeTransition which are hardware optimized
FadeTransition(
  opacity: _controller,
  child: const ExpensiveWidget(),
);
```
*(Also avoid `ClipRRect` and complex `BoxShadow` inside long lists. Clipping is very expensive. If an image needs rounded corners, it is often cheaper to modify the image itself or use a `CircleAvatar`).*

## 5. Granular Rebuilds

Do not wrap an entire `Scaffold` in a state listener if only one small text widget changes.

```dart
// ❌ BAD: Rebuilds the entire screen when the counter changes
class CounterScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider); // Triggers full rebuild
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const HeavyStaticWidget(), 
          Text('Count: $count'), // Only this needed to change!
        ]
      )
    );
  }
}

// ✅ ALWAYS: Isolate rebuilds using Consumer/Builder blocks
class CounterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const HeavyStaticWidget(), 
          Consumer( // Only this tiny block rebuilds!
            builder: (context, ref, child) {
              final count = ref.watch(counterProvider);
              return Text('Count: $count');
            }
          ),
        ]
      )
    );
  }
}
```

---

**Execution Protocol**
1. **DevTools Profiling**: If the app stutters, open the Flutter DevTools Performance view. A red bar indicates a dropped frame. Analyze if it was a UI (Dart code) or Raster (GPU) issue.
2. **Release Mode Testing**: Never measure performance in Debug mode. Debug mode includes heavy assertions, logging, and lacks JIT/AOT optimizations. Always test performance on a physical device using `flutter run --profile` or `--release`.
3. **Memory Leaks (Controllers)**: You MUST call `dispose()` on `TextEditingController`, `AnimationController`, `ScrollController`, and `FocusNode` in the `dispose` method of a `StatefulWidget`. Failing to do so is the #1 cause of memory leaks in Flutter.

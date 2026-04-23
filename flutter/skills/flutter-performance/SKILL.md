---
name: flutter-performance
description: >
  Optimization expert specialized in 60/120 FPS rendering and memory management.
  Trigger: When optimizing rendering, fixing "jank," or managing high-resource assets.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Rendering Optimization (REQUIRED)

Isolate frequent rebuilds to maintain high frame rates.

```dart
// ✅ ALWAYS: RepaintBoundary and Const Constructors
const MyStaticWidget();
return RepaintBoundary(child: FastAnimatingWidget());

// ❌ NEVER: Standard Opacity for animations
// Do not use the 'Opacity' widget for animations; prefer 'AnimatedOpacity'.
```

---

## Memory & Resource Management (REQUIRED)

Prevent leaks and optimize assets.

```dart
// ✅ ALWAYS: Dispose controllers and optimize images
void dispose() {
  _controller.dispose();
  super.dispose();
}
Image.network(url, cacheWidth: 300);

// ❌ NEVER: Blocking the main thread
// Do not perform heavy parsing in UI thread; use 'Isolate.run'.
```

---

## Layout Efficiency (REQUIRED)

Avoid expensive layout passes.

| Need | Optimized Choice |
|------|------------------|
| Long Lists | `ListView.builder` or `SliverList` |
| Fixed Item Size | `itemExtent` or `prototypeItem` |
| Heavy Ops | `Isolate.run` |

---

## Execution Protocol (REQUIRED)

1. **Profile**: Use **Flutter DevTools** (Performance Overlay) to identify "jank."
2. **Audit**: Regularly check memory usage for leaks.
3. **Optimize**: Implement `StatelessWidget` or selective rebuilds (`context.select`).

---

## Uncompromising Constraints

- **No Heavy Build**: Forbidden to perform heavy business logic inside the `build` method.
- **Stutter-Free**: Every animation must be smooth; stuttering is considered a blocker.
- **Memory Limits**: The application must stay within reasonable RAM limits for the platform.

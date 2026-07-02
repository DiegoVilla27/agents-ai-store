---
name: flutter-animations
description: The ultimate architectural standard for Flutter Animations Implicit vs Explicit, 120 FPS Optimization, AnimatedBuilder isolation, and RepaintBoundary.
author: Diego Villanueva
trigger: When building UI animations, optimizing frame rates, using AnimationControllers, or implementing transitions.
---

# Flutter Animations & Performance Architecture

A premium Flutter application must feel like liquid glass. Dropping below 60/120 FPS (Frames Per Second) destroys user trust immediately. This phenomenon is known as "Jank".

Animations in Flutter are powerful but dangerous. If you rebuild the entire screen 60 times a second, you will burn the user's battery and cause severe stuttering.

## 1. Implicit Animations (The First Line of Defense)

Do NOT write an `AnimationController` if you just want to change the color or size of a button when it's tapped. You MUST use Implicitly Animated Widgets. They manage their own internal controllers and are highly optimized.

```dart
// ❌ ATROCIOUS: Using a Controller just to fade a widget
// Requires 20 lines of boilerplate (TickerProvider, Controller, Tween, dispose...)

// ✅ ALWAYS: Use Implicit Animations for simple state changes
bool _isExpanded = false;

@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () => setState(() => _isExpanded = !_isExpanded),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic, // Always use elegant curves, never linear
      width: _isExpanded ? 200.0 : 100.0,
      height: _isExpanded ? 100.0 : 50.0,
      color: _isExpanded ? Colors.blue : Colors.red,
      child: const Text('Tap Me'),
    ),
  );
}
```
*Other critical implicit widgets: `AnimatedOpacity`, `AnimatedPadding`, `AnimatedPositioned`, `AnimatedSwitcher` (for swapping child widgets).*

## 2. Explicit Animations (AnimationController)

When you need an animation that repeats infinitely, reverses, or is chained (Staggered Animations), you MUST use Explicit Animations.

**CRITICAL RULE**: You must ALWAYS dispose of the `AnimationController` in the `dispose()` method. Failing to do so creates massive memory leaks that will crash the app.

```dart
// ✅ ALWAYS: Proper Explicit Animation Lifecycle
class MySpinningLogo extends StatefulWidget {
  @override
  _MySpinningLogoState createState() => _MySpinningLogoState();
}

// 1. MUST include SingleTickerProviderStateMixin
class _MySpinningLogoState extends State<MySpinningLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 2. Initialize the controller
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2),
    )..repeat(); // Infinite rotation
  }

  @override
  void dispose() {
    // 3. CRITICAL: Dispose the controller BEFORE calling super.dispose()
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4. Use optimized explicit widgets like RotationTransition
    return RotationTransition(
      turns: _controller,
      child: const FlutterLogo(size: 100),
    );
  }
}
```

## 3. The `setState` Anti-Pattern & `AnimatedBuilder`

The most common way junior developers ruin Flutter performance is by calling `setState()` inside an animation listener.

```dart
// ❌ ATROCIOUS: Destroys Performance
_controller.addListener(() {
  setState(() {}); // Rebuilds the ENTIRE widget tree 60 times a second!
});
```

To optimize, you MUST isolate the rebuilds using `AnimatedBuilder`.

```dart
// ✅ ALWAYS: Isolate Rebuilds with AnimatedBuilder
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      const HeavyStaticWidget(), // This will NEVER rebuild during the animation
      
      AnimatedBuilder(
        animation: _controller,
        // The 'child' parameter is passed in so it is NOT rebuilt during animation
        child: const HeavyStaticLogo(), 
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _controller.value * 100),
            child: child, // Reusing the static child
          );
        },
      ),
    ],
  );
}
```

## 4. `RepaintBoundary` (The Ultimate Optimization)

Even if you use `AnimatedBuilder`, moving a widget across the screen might force Flutter to "repaint" the static widgets behind it.

If you have a complex background (e.g., a map, a huge list, or heavy SVG) and a small animated icon floating over it, you MUST wrap the static background in a `RepaintBoundary`.

```dart
// ✅ ALWAYS: Use RepaintBoundary to isolate painting layers
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Flutter will cache this layer and NEVER repaint it while the icon moves
      const RepaintBoundary(
        child: ExtremelyHeavyMapBackground(),
      ),
      
      AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _controller.value,
          child: const FloatingActionIcon(),
        ),
      ),
    ],
  );
}
```

## 5. Physics-Based Animations (Springs)

Standard linear/cubic animations can feel robotic. Premium apps (like iOS native apps) use Physics. Flutter provides `SpringSimulation` to create fluid, natural motion.

```dart
// ✅ ALWAYS: Use Springs for natural drag-and-release interactions
void _runSpringAnimation(Offset pixelsPerSecond, double start, double end) {
  final simulation = SpringSimulation(
    const SpringDescription(
      mass: 1.0,
      stiffness: 100.0,
      damping: 10.0,
    ),
    start,
    end,
    pixelsPerSecond.dy,
  );
  _controller.animateWith(simulation);
}
```

---

**Execution Protocol**
1. **Hero Animations**: Use the `Hero` widget for seamless transitions between screens. Ensure the `tag` is unique and exactly matches on both screens. Avoid wrapping huge, complex widget trees in a `Hero` (keep it to images or simple containers).
2. **Staggered Animations**: When animating a list of items appearing one by one, use a single `AnimationController` but multiple `Tween` objects tied to `Interval` curves (e.g., `Curve: Interval(0.0, 0.5)` for item 1, `Interval(0.5, 1.0)` for item 2).
3. **DevTools Profiling**: If an animation stutters, open Flutter DevTools and check the "Performance" tab. If the "UI" time is high, you are rebuilding too much (Fix: `AnimatedBuilder`). If the "Raster" time is high, you are painting too much (Fix: `RepaintBoundary`).

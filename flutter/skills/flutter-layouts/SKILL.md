---
name: flutter-layouts
description: The ultimate architectural standard for Flutter Layouts The Constraints Protocol, Slivers, Adaptive UI, LayoutBuilder, and avoiding Unbounded Errors.
author: Diego Villanueva
trigger: When building complex UI structures, handling screen sizes, writing responsive layouts, or fixing constraint errors.
---

# Flutter Layouts & Adaptive Architecture

Flutter's rendering engine is a masterpiece, but it requires a deep understanding of its core rule. If you do not understand the golden rule of Flutter layouts, you will spend your life fighting "Unbounded Constraints" and "RenderFlex Overflow" errors.

**THE GOLDEN RULE:** Constraints go down. Sizes go up. Parents set position.
1. A parent tells its child: "You can be anywhere from X to Y pixels big".
2. The child asks its own children how big they want to be, then decides its size and tells the parent: "I want to be Z pixels big".
3. The parent says: "Okay, I'll place you at coordinate [x, y]".

## 1. The "Unbounded Constraints" Error

The most common error in Flutter is `Vertical viewport was given unbounded height`. 

This happens when a widget that wants to expand infinitely (like a `ListView`) is placed inside a parent that allows infinite expansion (like a `Column`). The `ListView` asks the `Column`: "How much space do I have?" The `Column` answers: "Infinite". The `ListView` tries to render an infinite number of pixels, and the engine crashes.

```dart
// ❌ ATROCIOUS: This will instantly crash with an Unbounded error
Column(
  children: [
    Text('Header'),
    ListView( // Tries to expand infinitely
      children: [...],
    )
  ],
)

// ✅ ALWAYS: Give the ListView a bounded constraint using Expanded or shrinkWrap
Column(
  children: [
    Text('Header'),
    Expanded( // Tells the ListView: "Take exactly the remaining space on screen"
      child: ListView(
        children: [...],
      ),
    )
  ],
)
```
*(Note: You can also use `shrinkWrap: true` on the `ListView`, but this forces the `ListView` to calculate the exact height of ALL its children instantly, destroying performance. Use `Expanded` whenever possible).*

## 2. LayoutBuilder vs MediaQuery

When building responsive UIs, many developers use `MediaQuery.of(context).size.width`. **This is an anti-pattern for component design.**

If you use `MediaQuery`, your widget assumes it owns the whole screen. If you later place that widget inside a 300px dialog box, it will still render as if it's on a 1000px screen. Furthermore, `MediaQuery` rebuilds your entire widget tree every time the keyboard opens!

```dart
// ❌ BAD: Binds the widget to the physical screen size
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return Container(width: screenWidth > 600 ? 500 : 300);
}

// ✅ ALWAYS: Use LayoutBuilder to build based on the PARENT'S available space
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Now this widget can be placed anywhere (Screen, Dialog, Sidebar)
      if (constraints.maxWidth > 600) {
        return const WideDesktopLayout();
      } else {
        return const NarrowMobileLayout();
      }
    },
  );
}
```

## 3. Responsive vs Adaptive Architecture

- **Responsive**: The UI stretches or shrinks. (e.g. A grid changes from 2 columns to 4 columns).
- **Adaptive**: The UX paradigm changes completely based on the device.

If you are building an Enterprise app for Web, Tablet, and Mobile, you MUST build adaptively.

```dart
// ✅ ALWAYS: Adapt the UX navigation paradigm to the device
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth > 900) {
        // Desktop: Persistent Left Sidebar (Drawer)
        return Scaffold(
          body: Row(
            children: [const PermanentDrawer(), Expanded(child: Content())],
          ),
        );
      } else if (constraints.maxWidth > 600) {
        // Tablet: Vertical Navigation Rail (Icons only)
        return Scaffold(
          body: Row(
            children: [const NavigationRailWidget(), Expanded(child: Content())],
          ),
        );
      } else {
        // Mobile: Bottom Navigation Bar
        return Scaffold(
          body: Content(),
          bottomNavigationBar: const BottomNavBarWidget(),
        );
      }
    },
  );
}
```

## 4. Premium Scrolling: Slivers (CustomScrollView)

Standard `ListView` and `GridView` are for basic apps. Premium apps (like iOS native apps) have collapsing headers, search bars that pin to the top, and grids seamlessly mixed with lists. You CANNOT do this with a standard `ListView`. You MUST use `Slivers`.

```dart
// ✅ ALWAYS: Use CustomScrollView for complex, premium scrolling effects
CustomScrollView(
  slivers: [
    // 1. A header that shrinks as you scroll up, but stays pinned at a minimum height
    SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Premium Header'),
        background: Image.network('...', fit: BoxFit.cover),
      ),
    ),
    
    // 2. A grid of items
    SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => ItemCard(index),
        childCount: 20,
      ),
    ),
    
    // 3. A standard list seamlessly flowing after the grid
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => ListTile(title: Text('List Item $index')),
        childCount: 10,
      ),
    ),
  ],
)
```

## 5. Performance Killers (`IntrinsicHeight` / `IntrinsicWidth`)

By default, Flutter layout is $O(N)$ (one pass). But sometimes developers want a `Row` where all children are the exact same height as the tallest child. To do this, they use `IntrinsicHeight`.

**CRITICAL RULE**: `IntrinsicHeight` forces the rendering engine to do a speculative layout pass on all children, then a real layout pass. It makes layout $O(N^2)$. 

- **❌ NEVER**: Use `IntrinsicHeight` inside a `ListView` or `GridView`. It will destroy scrolling performance.
- **✅ ALWAYS**: Try to solve the problem with `Flex`, `Expanded`, or fixed heights first. If you absolutely must use `IntrinsicHeight`, isolate it to a tiny, static part of the UI.

---

**Execution Protocol**
1. **SafeArea**: Never let content render under the iOS notch or Android navigation bar. Wrap your top-level Scaffolds (or specific content) in a `SafeArea` widget.
2. **Hardcoded Sizes**: Avoid `Container(width: 300, height: 500)`. Mobile screens range from the iPhone SE to the iPad Pro. Use constraints, fractions (`FractionallySizedBox`), or flex (`Expanded`) to define relative sizes.
3. **The `gap` package vs `SizedBox`**: Instead of writing `SizedBox(height: 16)` or `SizedBox(width: 16)` depending on whether you are in a Column or Row, use the `gap` package: `Gap(16)`. It automatically adapts to the parent axis.

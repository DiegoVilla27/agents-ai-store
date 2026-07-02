---
name: flutter-ui-ux
description: The ultimate architectural standard for Premium Flutter UX Haptics, Shimmer Loaders, Animated Micro-interactions, Empty States, and Thumb Reachability.
author: Diego Villanueva
trigger: When designing UI components, implementing loading/error states, creating dialogs/modals, or adding haptic feedback.
---

# Premium Flutter UI/UX Architecture

A functioning app is not enough. A premium mobile application must feel **alive, tactile, and forgiving**. The difference between a cheap prototype and a multi-million dollar Enterprise app lies entirely in the details of the UX.

## 1. Haptic Feedback (The Tactile Dimension)

Mobile devices are physical. When a user presses a button, they should *feel* it. Flutter provides native haptics out of the box.

**✅ ALWAYS** add haptics to interactive elements, but vary the intensity based on the action.

```dart
// ✅ ALWAYS: Use Haptics for premium tactile feedback
import 'package:flutter/services.dart';

// 1. Light Impact: Standard buttons, toggles, tab changes
GestureDetector(
  onTap: () {
    HapticFeedback.lightImpact(); 
    // Do action...
  },
  child: const Text('Tab 1'),
);

// 2. Medium/Heavy Impact: Destructive actions, confirming a purchase
HapticFeedback.heavyImpact();

// 3. Vibrate: Error states (e.g., wrong password entered)
HapticFeedback.vibrate();
```

## 2. Loading States (The Shimmer Protocol)

A full-screen `CircularProgressIndicator` is the hallmark of a cheap app. It causes anxiety because the user doesn't know what is loading.

**✅ ALWAYS** use Skeleton/Shimmer loaders for primary content. The loader must mimic the exact shape of the data that will eventually appear.

```dart
// ❌ ATROCIOUS: Centered spinner for a list of products
body: isLoading ? const Center(child: CircularProgressIndicator()) : ProductList();

// ✅ ALWAYS: Use the 'shimmer' package to draw a skeleton
body: isLoading 
  ? Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(width: 80, height: 80, color: Colors.white), // Image placeholder
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 16, color: Colors.white), // Title placeholder
                    const SizedBox(height: 8),
                    Container(width: 100, height: 16, color: Colors.white), // Subtitle placeholder
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    )
  : ProductList();
```
*(Note: Spinners are acceptable for tiny, isolated actions, like a loading spinner inside a "Submit" button).*

## 3. The 3 Pillars of Empty & Error States

A white screen with the text "No data" or "Error 500" is a dead end. It kills user retention.

Every Empty or Error state MUST contain exactly 3 elements:
1. **Visual**: A high-quality illustration, Lottie animation, or Icon.
2. **Context**: A human-readable title and subtitle (e.g., "You have no favorites yet. Explore our catalog!").
3. **Action (CTA)**: A button that helps the user resolve the state (e.g., "Explore Products", "Try Again").

```dart
// ✅ ALWAYS: Graceful degradation with actionable CTAs
class EmptyStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/animations/empty_box.json', width: 200),
        const Text('Your cart is empty', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Padding(
           padding: EdgeInsets.all(16.0),
           child: Text('Looks like you haven\'t added anything yet.', textAlign: TextAlign.center),
        ),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Start Shopping'),
        )
      ],
    );
  }
}
```

## 4. Micro-interactions (The Bounce Effect)

Static buttons feel dead. When a user presses a card or a primary button, it should physically react.

**✅ ALWAYS** wrap custom interactive cards in an `AnimatedScale` or use packages that provide a "bounce on press" effect.

```dart
// ✅ ALWAYS: Create buttons that physically press down
class BouncingCard extends StatefulWidget { ... }

class _BouncingCardState extends State<BouncingCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Card(child: Text('Press me!')),
      ),
    );
  }
}
```

## 5. Ergonomics: The "Thumb Zone" & Modals

Phones are massive (6.7+ inches). Users hold them with one hand.
If your primary action (like "Confirm Purchase") is at the very top right of the screen, the user cannot reach it.

1. **Bottom Sheets over Dialogs**: `showDialog()` puts a box in the dead center of the screen. `showModalBottomSheet()` anchors the UI to the bottom, right under the user's thumb. ALWAYS prefer Bottom Sheets for complex forms, pickers, or actions.
2. **Sticky Bottom CTAs**: Primary action buttons should be fixed to the bottom of the screen using a `SafeArea`.
3. **Touch Targets**: Apple and Google guidelines dictate that NO interactive element can be smaller than `48x48` logical pixels. If you have an `Icon(Icons.close)` (which is 24x24), you MUST wrap it in a `Padding` or `IconButton` to expand its tap area to 48x48.

```dart
// ✅ ALWAYS: Use Bottom Sheets instead of standard Alerts for complex flows
void askForConfirmation(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the sheet to take up more space if needed
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const ConfirmationSheet(),
  );
}
```

---

**Execution Protocol**
1. **Snackbars**: Never show raw errors in a Snackbar (e.g., `Exception: User not found`). Translate it into human language: `We couldn't find your account. Please check your email.`
2. **Keyboard Management**: Always wrap forms in `GestureDetector(onTap: () => FocusScope.of(context).unfocus())` so tapping outside a text field hides the keyboard.
3. **Never Block the UI**: If saving data takes 3 seconds, do not freeze the screen. Change the button to a loading state, or let the user navigate away while you show a subtle "Saving..." indicator at the top of the screen (Optimistic UI).

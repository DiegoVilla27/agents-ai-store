---
name: flutter-ui-ux
description: >
  Specialist in premium user experiences, micro-interactions, and visual design.
  Trigger: When designing UI components, overlays, or complex animations.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Application States (REQUIRED)

The UI must communicate what is happening at all times.

| State | Feedback Requirement |
|-------|----------------------|
| **Loading** | Shimmers or custom micro-animations. |
| **Success** | Animated checkmarks and Haptic feedback. |
| **Error** | Non-frustrating messages with retry options. |
| **Empty** | Minimalist design guiding the user to action. |

---

## Motion & Micro-interactions (REQUIRED)

Animations must feel organic and responsive.

```dart
// ✅ ALWAYS: Haptics and Custom Overlays
HapticFeedback.lightImpact();
showCustomModal(context);

// ❌ NEVER: Standard System Dialogs
// Forbidden: using standard system alerts for premium user flows.
```

---

## Accessibility & Theming (REQUIRED)

Design for every user and every environment.

```dart
// ✅ ALWAYS: Light/Dark consistency and Reachability
// Ensure interactive elements are in the bottom/middle area.

// ❌ NEVER: Static Strings
// All visual feedback must be localized (l10n).
```

---

## Execution Protocol (REQUIRED)

1. **Design Audit**: Review the Design System before creating components.
2. **Componentize**: Fragment large screens into local widgets.
3. **Animate**: Use organic curves (e.g., `Curves.easeOutExpo`).
4. **Test**: Verify visual consistency across different device sizes.

---

## Uncompromising Constraints

- **Action Feedback**: Never leave the user without visual/tactile feedback.
- **Consistency**: Design must strictly follow the project's visual identity.
- **Clean UI**: Standard system dialogs are prohibited for custom premium flows.

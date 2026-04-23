---
description: 'Native-like Page Transitions using Browser View Transitions API'
author: 'Diego Villanueva'
trigger: 'When implementing route transitions or element morphing across views.'
---

# React View Transitions

Leveraging the modern Browser View Transitions API in React (v19+ focus).

## ✅ ALWAYS
- Use the `document.startViewTransition()` API where supported.
- Use the `view-transition-name` CSS property to identify morphing elements.
- Wrap route changes or state-driven UI updates in the transition callback.
- Provide fallback CSS transitions for browsers that don't support the API.
- Use `useTransition` (React) to coordinate the state update with the visual transition.

## ❌ NEVER
- Block the UI thread with long-running logic inside the transition callback.
- Use view transitions for every small change; focus on significant view updates.

## 🛠 Patterns
- **Morphing Gallery**: Elements that expand or move seamlessly between a list and a detail view.
- **Cross-fade Routing**: Simple and performant page entry/exit animations.

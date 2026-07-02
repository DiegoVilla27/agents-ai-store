---
name: react-view-transitions
description: The ultimate architectural standard for implementing native, hardware-accelerated page and layout transitions using the Browser View Transitions API in React.
author: Diego Villanueva
trigger: When building page navigations, morphing elements between screens, or implementing native-like UI transitions on the web.
---

# React View Transitions API Architecture

Historically, achieving native-like page transitions (e.g., an image smoothly expanding from a grid into a detail page) required heavy JavaScript libraries that hijacked the routing and manipulated the DOM manually. The **View Transitions API** changes everything. It asks the browser to take a screenshot of the old state, wait for the DOM to update, take a screenshot of the new state, and hardware-accelerate a cross-fade or morph between them.

## 1. The Core Paradigm (React Integration)

The Browser API `document.startViewTransition(callback)` expects the `callback` to update the DOM. However, React state updates are asynchronous. If you just call `setState` inside the callback, the browser takes the "new" screenshot before React actually renders it.

- **React 18 (`flushSync`)**: You must force React to update the DOM synchronously inside the transition.
- **React 19 (`useTransition`)**: React 19 integrates view transitions directly into the `useTransition` hook.

```tsx
// ✅ ALWAYS: Force synchronous DOM updates in React 18
import { flushSync } from 'react-dom';

function toggleTheme() {
  // Check for browser support (Progressive Enhancement)
  if (!document.startViewTransition) {
    setIsDarkMode(!isDarkMode);
    return;
  }

  document.startViewTransition(() => {
    // flushSync forces React to render instantly so the browser captures the new state
    flushSync(() => {
      setIsDarkMode(!isDarkMode);
    });
  });
}
```

## 2. Element Morphing (`view-transition-name`)

By default, the entire page cross-fades. To morph a specific element (like an Avatar moving from the sidebar to the header), you give it a unique `view-transition-name` in CSS. The browser will automatically animate its size, position, and layout.

```css
/* ✅ ALWAYS: Assign unique names to morphing elements */
.avatar-image {
  view-transition-name: user-avatar;
}
```

**CRITICAL RULE**: The `view-transition-name` MUST be globally unique on the screen at any given moment. If two elements have `view-transition-name: user-avatar` simultaneously, the transition will instantly crash and abort.

```tsx
// ✅ ALWAYS: Generate unique transition names for lists
function UserList({ users }) {
  return (
    <ul>
      {users.map(user => (
        <li 
          key={user.id} 
          style={{ viewTransitionName: `user-avatar-${user.id}` }}
        >
          <img src={user.avatar} />
        </li>
      ))}
    </ul>
  );
}
```

## 3. Customizing the Animation (CSS Pseudo-Elements)

You don't have to settle for the default cross-fade. The browser creates a temporary pseudo-element tree during the transition that you can style with standard CSS animations.

- `::view-transition-old(name)`: The screenshot of the outgoing state.
- `::view-transition-new(name)`: The live representation of the incoming state.

```css
/* ✅ ALWAYS: Customize the duration and easing */
::view-transition-old(root),
::view-transition-new(root) {
  animation-duration: 0.4s;
  animation-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}

/* Example: A slide-up page transition */
::view-transition-old(root) {
  animation-name: fade-out;
}
::view-transition-new(root) {
  animation-name: slide-up;
}

@keyframes slide-up {
  from { transform: translateY(20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
```

## 4. Router Integrations (Next.js & React Router)

Do not try to build View Transitions manually for page navigations if your router supports it natively.

- **Next.js (App Router)**: Supported natively via experimental flags or the `<ViewTransitions>` wrapper.
- **React Router (v6.27+)**: Use the `viewTransition` prop on `<Link>` components to automatically trigger a document transition.

```tsx
// ✅ ALWAYS: Use router primitives when available
import { Link } from 'react-router-dom';

export function Navigation() {
  return (
    <nav>
      {/* React Router handles the document.startViewTransition under the hood */}
      <Link to="/profile" viewTransition>Profile</Link>
    </nav>
  );
}
```

## 5. Reduced Motion (Accessibility)

Since view transitions involve large layout shifts, they can cause motion sickness. You MUST disable them for users who prefer reduced motion.

```css
/* ✅ ALWAYS: Respect accessibility settings */
@media (prefers-reduced-motion: reduce) {
  ::view-transition-group(*),
  ::view-transition-old(*),
  ::view-transition-new(*) {
    animation: none !important;
  }
}
```

---

**Execution Protocol**
1. **Progressive Enhancement**: The View Transitions API is not supported on older iOS versions (Safari < 18). Your application MUST work perfectly (falling back to an instant change) if `!document.startViewTransition`. Do not polyfill this API; it is a hardware-accelerated feature.
2. **Avoid Blinking Anti-Pattern**: If an image flickers or disappears during a transition, it usually means the incoming DOM element had a different aspect ratio or CSS object-fit property than the outgoing one, or the image wasn't fully loaded yet. Ensure images are preloaded or have explicit dimensions.
3. **Transition Scope**: Do not use View Transitions for micro-interactions (like a button turning blue on hover or a small dropdown opening). Use standard CSS transitions for that. View Transitions pause the entire DOM; they should be reserved for macro layout changes and route navigation.

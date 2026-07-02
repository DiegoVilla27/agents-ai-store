---
name: react-a11y
description: The definitive architectural standard for building accessible, inclusive, and WCAG-compliant React applications.
author: Diego Villanueva
trigger: When building UI components, complex forms, modals, or establishing design system accessibility guidelines.
---

# React Accessibility (a11y) Architecture

Accessibility (a11y) is not an optional "feature" or an afterthought for the end of the project. It is a fundamental civil right and a legal requirement in modern web development. Building accessible React applications means building robust, semantic, and high-quality software.

## 1. The Core Philosophy: Semantic HTML First

The first rule of ARIA is: **No ARIA is better than bad ARIA.**

Native HTML elements come with built-in keyboard accessibility, focus management, and screen reader semantics. If you try to recreate a button with a `div`, you are taking on the responsibility of recreating all of that native behavior manually.

```tsx
// ❌ ATROCIOUS: The "Div Button" Anti-Pattern
<div onClick={submitForm} className="btn">Submit</div>

// ✅ ALWAYS: Use native interactive elements
<button onClick={submitForm} type="button" className="btn">
  Submit
</button>
```

If you *must* create a custom interactive element, you are contractually obligated to provide `role`, `tabIndex`, and keyboard event handlers (`onKeyDown` for Space and Enter keys).

## 2. Keyboard Navigation & Focus Management

Users who cannot use a mouse rely entirely on the keyboard (`Tab`, `Shift+Tab`, `Enter`, `Space`, Arrow keys).

- **The Outline Crime**: NEVER use CSS `outline: none;` without providing a custom, highly visible `:focus-visible` state. Removing the focus ring makes the application completely unusable for keyboard users.
- **Focus Trapping**: When a Modal or Drawer opens, the keyboard focus MUST be trapped inside it. Users should not be able to tab into the obscured background. Use libraries like `react-focus-lock` or `@radix-ui/react-dialog`.
- **Focus Management**: When a Modal closes, focus MUST return to the button that originally opened it.

```tsx
// ✅ ALWAYS: Use focus-visible, never just focus
button:focus-visible {
  outline: 2px solid #2563EB;
  outline-offset: 2px;
}
```

## 3. Screen Readers & ARIA Patterns

Screen readers (VoiceOver, NVDA, JAWS) translate the DOM into speech.

- **`aria-label`**: Use this when an interactive element has no visible text (e.g., an icon button).
- **`aria-describedby`**: Perfect for linking an input field to its error message or helper text.
- **`aria-hidden="true"`**: Apply this to decorative SVGs or icons so screen readers don't announce meaningless image file names.
- **`aria-live`**: Use this for dynamic content that appears without a page reload (e.g., Toast notifications or Form submission results).

```tsx
// ✅ ALWAYS: Associate inputs with errors
<label htmlFor="email">Email Address</label>
<input 
  id="email" 
  type="email" 
  aria-invalid={!!error}
  aria-describedby={error ? "email-error" : undefined}
/>
{error && <span id="email-error" role="alert" className="text-red-500">{error}</span>}
```

## 4. Visual Accessibility (Colors & Motion)

- **Contrast Ratios**: Text must have a contrast ratio of at least 4.5:1 against its background (WCAG AA). Do not use light gray text on a white background for critical information.
- **Color Independence**: Never convey information using *only* color. If a required field turns red, it must also display a text message or an icon indicating the error.
- **Reduced Motion**: Respect the OS-level `prefers-reduced-motion` media query. Stop all non-essential animations, parallax effects, and smooth scrolling for these users.

```css
/* ✅ ALWAYS: Respect reduced motion */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## 5. Skip Links

For complex applications (like dashboards), keyboard users must press `Tab` 50 times just to get past the navigation menu.

- **Implement a Skip Link**: A hidden link at the very top of the DOM that becomes visible only when it receives keyboard focus, allowing the user to jump directly to the `<main>` content area.

```tsx
// ✅ ALWAYS: Provide a skip link in the root layout
<a href="#main-content" className="sr-only focus:not-sr-only">
  Skip to main content
</a>
// ... navigation ...
<main id="main-content" tabIndex={-1}>
```

## 6. Testing Accessibility (Automation)

You cannot manually test everything. Build a11y into the CI/CD pipeline.

- **ESLint**: ALWAYS enforce `eslint-plugin-jsx-a11y` with the `strict` ruleset. It will fail the build if an `img` lacks an `alt` prop or if an `onClick` is on a non-interactive element.
- **Axe-Core / Jest**: Use `jest-axe` in your React Testing Library tests to automatically assert that a component renders without DOM-level accessibility violations.

```tsx
// ✅ ALWAYS: Automated a11y assertions in Unit Tests
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('Component has no accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

---

**Execution Protocol**
1. **Radix UI / React Aria**: Strongly prefer using headless, accessible UI primitives (like Radix UI, Headless UI, or React Aria) for complex components (Comboboxes, Modals, Tabs). Do not build these from scratch; the ARIA specs are incredibly complex and easy to get wrong.
2. **`alt` Attributes**: An empty `alt=""` is valid and correct for purely decorative images. A missing `alt` attribute is a violation.
3. **Headings Hierarchy**: Ensure the page has exactly one `<h1>`, and that heading levels (`<h2>`, `<h3>`) do not skip numbers. Screen reader users use headings as an index to navigate the page.

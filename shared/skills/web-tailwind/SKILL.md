---
name: web-tailwind
description: The definitive architectural standard and exhaustive pattern library for building scalable interfaces using Tailwind CSS (v4).
author: Diego Villanueva
trigger: When styling components, configuring themes, writing conditional classes, or implementing responsive/dark mode layouts with Tailwind CSS.
---

# Tailwind CSS Engineering & Architecture Mastery

You are constructing the visual foundation of the application. Tailwind is a strict design system enforcer. When used correctly, it scales beautifully across massive teams. When abused, it becomes an unmaintainable swamp.

## 1. Styling Decision Tree

Follow this logic for every style you apply:

```text
Tailwind class exists?    → className="text-red-500"
Dynamic value?            → style={{ width: `${x}%` }}
Conditional styles?       → cn("base", condition && "variant")
Static only?              → className="..." (no cn() needed)
Library can't use class?  → style prop with var() constants
```

## 2. The Core Philosophy (Strict Design Tokens)

- **Utility-First, Tokens Always**: Stick to the predefined spacing, color, and typography scales.
- **NEVER Use Arbitrary Values (Unless Impossible)**: Arbitrary values (`text-[#ff0000]`, `w-[317px]`, `bg-[var(--magic)]`) bypass the design system. If you need a specific value repeatedly, add it to your theme configuration (`@theme` in v4). 
- **Components Over `@apply`**: Never use `@apply` to create "BEM-like" CSS classes (e.g., `.btn { @apply bg-blue-500 rounded; }`). If you need to reuse styling, extract it into a Framework Component (e.g., `<Button>`).

### Never Use `var()` in className
```tsx
// ❌ NEVER: var() in className
<div className="bg-[var(--color-primary)]" />
<div className="text-[var(--text-color)]" />

// ✅ ALWAYS: Use Tailwind semantic classes
<div className="bg-primary text-slate-400" />
```

### Never Use Hex Colors
```tsx
// ❌ NEVER: Hex colors in className
<p className="text-[#ffffff] bg-[#1e293b]" />

// ✅ ALWAYS: Use Tailwind color classes
<p className="text-white bg-slate-800" />
```

## 3. Dynamic Class Merging (The `cn()` Pattern)

String concatenation (`className={`bg-blue-500 ${isActive ? 'bg-red-500' : ''}`}`) is fragile and leads to specificity collisions. Always use `clsx` + `tailwind-merge` via a `cn()` utility.

```typescript
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### When to Use `cn()`
```tsx
// ✅ Conditional classes
<div className={cn("base-class", isActive && "active-class")} />

// ✅ Merging with potential conflicts (props overriding defaults)
<button className={cn("px-4 py-2", className)} /> 

// ✅ Multiple conditions
<div className={cn(
  "rounded-lg border",
  variant === "primary" && "bg-blue-500 text-white",
  disabled && "opacity-50 cursor-not-allowed"
)} />
```

### When NOT to Use `cn()`
```tsx
// ❌ Static classes - unnecessary wrapper
<div className={cn("flex items-center gap-2")} />

// ✅ Just use className directly
<div className="flex items-center gap-2" />
```

## 4. Responsive Design (Mobile-First)

Tailwind breakpoints are strictly `min-width` and Mobile-First.
- **Start Unprefixed**: The unprefixed classes apply to mobile (the smallest screens). 
- **Scale Up**: Use `sm:`, `md:`, `lg:`, `xl:` to override styles as the screen gets wider.
- **Container Queries (`@container`)**: Prefer container queries over media queries for reusable components. A card should adapt to its wrapper's width, not the screen's width.

```tsx
// ✅ ALWAYS: Mobile-first thinking. (1 col on mobile, 2 on tablet, 3 on desktop)
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
```

## 5. Style Constants for Third-Party Libraries

When libraries (like Recharts) don't accept `className`, use CSS variables mapped to Tailwind themes.

```tsx
// ✅ Constants with var() - ONLY for library props
const CHART_COLORS = {
  primary: "var(--color-primary)",
  text: "var(--color-text)",
  gridLine: "var(--color-border)",
};

// Usage with Recharts (can't use className)
<XAxis tick={{ fill: CHART_COLORS.text }} />
<CartesianGrid stroke={CHART_COLORS.gridLine} />
```

## 6. Truly Dynamic Values

If a value is computed at runtime and cannot be mapped to a Tailwind class, use the `style` prop.

```tsx
// ✅ style prop for truly dynamic values
<div style={{ width: `${percentage}%` }} />
<div style={{ opacity: isVisible ? 1 : 0 }} />

// ✅ CSS custom properties for complex theming overrides
<div style={{ "--progress": `${value}%` } as React.CSSProperties} />
```

## 7. Common Layout & Styling Patterns

### Flexbox & Grid
```tsx
// Flexbox
<div className="flex items-center justify-between gap-4" />
<div className="flex flex-col gap-2" />

// Grid
<div className="grid grid-cols-3 gap-4" />
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6" />
```

### Spacing (Margin & Padding)
```tsx
<div className="p-4" />           // All sides
<div className="px-4 py-2" />     // Horizontal, vertical
<div className="pt-4 pb-2" />     // Top, bottom
<div className="mx-auto" />       // Center horizontally
<div className="mt-8 mb-4" />     // Margin Top, Bottom
```

### Typography, Borders & Shadows
```tsx
<h1 className="text-2xl font-bold text-white tracking-tight" />
<span className="text-xs font-medium uppercase tracking-wide" />
<div className="rounded-lg border border-slate-700" />
<div className="rounded-full shadow-lg" />
<div className="ring-2 ring-blue-500 ring-offset-2" />
```

## 8. State & Interaction Modifiers

Leverage modifiers to handle complex states without touching JavaScript.

```tsx
// Basic States
<button className="hover:bg-blue-600 focus:ring-2 active:scale-95 disabled:opacity-50" />

// Focus Management: ALWAYS use focus-visible: instead of focus: for accessibility
<input className="focus-visible:border-blue-500 focus-visible:outline-none" />

// Parent/Child Relationships (group)
<div className="group hover:bg-slate-100">
  <span className="opacity-0 group-hover:opacity-100">Visible on hover</span>
</div>
```

## 9. Dark Mode Strategy

```tsx
// Class Strategy
<div className="bg-white dark:bg-slate-900" />
<p className="text-gray-900 dark:text-white" />
```
*Tip: Map semantic variables in your theme (`bg-surface`) to avoid writing `dark:` everywhere.*

## 10. Arbitrary Values (Escape Hatch)

Use this ONLY as a last resort.

```tsx
// ✅ OK for highly specific one-off mathematical calculations
<div className="w-[327px]" />
<div className="top-[117px]" />
<div className="grid-cols-[1fr_2fr_1fr]" />

// ❌ NEVER use for colors or spacing that should be in the theme
<div className="bg-[#1e293b] p-[16px]" />  // USE: bg-slate-800 p-4
```

## 11. Organization and Readability

- **Automatic Sorting**: You MUST use `prettier-plugin-tailwindcss`. It enforces a consistent class order across the entire codebase (Layout -> Typography -> Visuals -> Modifiers).
- **No Dynamic Class Construction**: Never construct Tailwind class names dynamically (e.g., `bg-${color}-500`). Tailwind's compiler will miss them. Pass the full class name string instead.
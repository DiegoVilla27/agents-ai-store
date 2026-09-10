---
name: web-scss-architecture
description: The definitive standard for professional SCSS/SASS engineering using the modern module system, mixins, functions, design token generation, and scalable file architectures.
author: Diego Villanueva
trigger: When writing SCSS/SASS stylesheets, configuring module system (@use/@forward), creating mixins, functions, responsive utilities, or structuring SCSS architectures.
---

# SCSS/SASS Engineering Mastery

You are an expert SCSS Architect. Your directive is to build maintainable, DRY, and high-performance SCSS systems using the modern module system (`@use`/`@forward`), advanced mixins, pure functions, maps, loops, and scalable file architectures. Every SCSS file you produce must compile to clean, minimal CSS — no bloat, no unused selectors, no legacy patterns.

---

## 1. Module System: `@use` / `@forward` (The End of `@import`)

**❌ NEVER** use `@import`. It is deprecated, creates global scope pollution, compiles the same file multiple times, and will be removed from SASS.

**✅ ALWAYS** use `@use` and `@forward` for namespaced, single-import, encapsulated modules.

### A. `@use` — Importing with Namespace

```scss
// components/_button.scss
@use '../tokens' as t;
@use '../mixins' as m;

.btn {
  background: t.$color-primary;
  padding: t.$spacing-2 t.$spacing-4;
  border-radius: t.$radius-md;
  font-size: t.$text-sm;
  font-weight: 600;
  cursor: pointer;
  @include m.transition(background-color, transform);

  &:hover {
    background: t.$color-primary-hover;
    transform: translateY(-1px);
  }

  &--danger {
    background: t.$color-danger;
    &:hover { background: t.$color-danger-hover; }
  }
}
```

### B. `@forward` — Re-exporting Modules

```scss
// abstracts/_index.scss (Barrel file)
@forward 'tokens';
@forward 'mixins';
@forward 'functions';

// components/_card.scss — Single clean import
@use '../abstracts' as *;  // Imports everything forwarded
```

### C. Configurable Modules

```scss
// _tokens.scss
$color-primary: hsl(220 90% 56%) !default;
$color-danger: hsl(0 84% 60%) !default;
$radius-md: 0.5rem !default;

// main.scss — Override defaults at the consumer level
@use 'tokens' with (
  $color-primary: hsl(260 80% 55%),
  $radius-md: 0.75rem,
);
```

### Rules
- ❌ **NEVER** use `@import`. It is legacy and will be removed.
- ✅ **ALWAYS** use `@use` with explicit namespaces or `as *` for barrel files.
- ✅ Use `!default` for all configurable token variables.

---

## 2. Design Token Variables

### A. Primitive Scale

```scss
// tokens/_colors.scss
$gray-50:  hsl(210, 40%, 98%);
$gray-100: hsl(210, 40%, 96%);
$gray-200: hsl(214, 32%, 91%);
$gray-700: hsl(215, 25%, 27%);
$gray-800: hsl(217, 33%, 17%);
$gray-900: hsl(222, 47%, 11%);
$gray-950: hsl(229, 84%, 5%);

$blue-500: hsl(220, 90%, 56%);
$blue-600: hsl(221, 83%, 50%);

// tokens/_spacing.scss
$spacing-1:  0.25rem;
$spacing-2:  0.5rem;
$spacing-3:  0.75rem;
$spacing-4:  1rem;
$spacing-6:  1.5rem;
$spacing-8:  2rem;
$spacing-12: 3rem;
$spacing-16: 4rem;

// tokens/_typography.scss
$font-sans:  'Inter', system-ui, -apple-system, sans-serif;
$font-mono:  'JetBrains Mono', 'Fira Code', monospace;

$text-xs:  0.75rem;
$text-sm:  0.875rem;
$text-base: 1rem;
$text-lg:  1.125rem;
$text-xl:  1.25rem;
$text-2xl: 1.5rem;
$text-3xl: 1.875rem;
$text-4xl: 2.25rem;

// tokens/_effects.scss
$radius-sm:   0.375rem;
$radius-md:   0.5rem;
$radius-lg:   0.75rem;
$radius-xl:   1rem;
$radius-full: 9999px;

$shadow-sm: 0 1px 2px hsl(0 0% 0% / 0.05);
$shadow-md: 0 4px 6px -1px hsl(0 0% 0% / 0.1), 0 2px 4px -2px hsl(0 0% 0% / 0.1);
$shadow-lg: 0 10px 15px -3px hsl(0 0% 0% / 0.1), 0 4px 6px -4px hsl(0 0% 0% / 0.1);
```

### B. Semantic Tokens

```scss
// tokens/_semantic.scss
@use 'colors' as c;

$color-primary:       c.$blue-500 !default;
$color-primary-hover: c.$blue-600 !default;
$color-text:          c.$gray-900 !default;
$color-text-muted:    c.$gray-700 !default;
$color-surface:       hsl(0, 0%, 100%) !default;
$color-border:        c.$gray-200 !default;
```

---

## 3. Mixins — Reusable Style Patterns

### A. Responsive Breakpoint Mixin

```scss
// mixins/_breakpoints.scss
$breakpoints: (
  'sm':  640px,
  'md':  768px,
  'lg':  1024px,
  'xl':  1280px,
  '2xl': 1536px,
) !default;

@mixin breakpoint($name) {
  $value: map-get($breakpoints, $name);
  @if $value == null {
    @error "Unknown breakpoint: #{$name}. Available: #{map-keys($breakpoints)}";
  }
  @media (min-width: $value) {
    @content;
  }
}

@mixin breakpoint-down($name) {
  $value: map-get($breakpoints, $name);
  @media (max-width: ($value - 0.02px)) {
    @content;
  }
}

@mixin breakpoint-between($lower, $upper) {
  $min: map-get($breakpoints, $lower);
  $max: map-get($breakpoints, $upper);
  @media (min-width: $min) and (max-width: ($max - 0.02px)) {
    @content;
  }
}

// Usage:
.sidebar {
  display: none;

  @include breakpoint('lg') {
    display: flex;
    flex-direction: column;
    inline-size: 280px;
  }
}
```

### B. Transition Mixin

```scss
// mixins/_transitions.scss
@mixin transition($properties...) {
  $transitions: ();
  @each $prop in $properties {
    $transitions: append($transitions, $prop 200ms cubic-bezier(0.2, 0.8, 0.2, 1), comma);
  }
  transition: $transitions;
}

// Usage:
.btn {
  @include transition(background-color, transform, box-shadow);
}
```

### C. Typography Mixin

```scss
// mixins/_typography.scss
@use '../tokens' as t;

@mixin heading($size, $weight: 700) {
  font-size: $size;
  font-weight: $weight;
  line-height: 1.2;
  letter-spacing: -0.02em;
  color: t.$color-text;
}

@mixin body-text($size: t.$text-base) {
  font-size: $size;
  line-height: 1.6;
  color: t.$color-text-muted;
}

// Usage:
h1 { @include heading(t.$text-4xl); }
h2 { @include heading(t.$text-3xl); }
p  { @include body-text; }
```

### D. Truncation Mixins

```scss
// mixins/_utilities.scss
@mixin truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

@mixin line-clamp($lines: 2) {
  display: -webkit-box;
  -webkit-line-clamp: $lines;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

@mixin sr-only {
  position: absolute;
  inline-size: 1px;
  block-size: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

### E. Container Query Mixin

```scss
// mixins/_container.scss
@mixin container($name, $min-width) {
  @container #{$name} (min-width: #{$min-width}) {
    @content;
  }
}

// Usage:
.card-wrapper {
  container-type: inline-size;
  container-name: card;
}

.card {
  @include container('card', 400px) {
    flex-direction: row;
  }
}
```

---

## 4. Functions — Pure Computations

### A. Unit Conversion

```scss
// functions/_units.scss
@use 'sass:math';

@function rem($px) {
  @return math.div($px, 16) * 1rem;
}

@function em($px, $base: 16) {
  @return math.div($px, $base) * 1em;
}

// Usage:
.container {
  padding: rem(24) rem(32);  // → 1.5rem 2rem
  gap: rem(16);              // → 1rem
}
```

### B. Z-Index Management

```scss
// functions/_z-index.scss
$z-layers: (
  'base':     1,
  'dropdown': 100,
  'sticky':   200,
  'overlay':  300,
  'modal':    400,
  'popover':  500,
  'toast':    600,
  'tooltip':  700,
) !default;

@function z($layer) {
  $value: map-get($z-layers, $layer);
  @if $value == null {
    @error "Unknown z-index layer: #{$layer}. Available: #{map-keys($z-layers)}";
  }
  @return $value;
}

// Usage:
.modal     { z-index: z('modal'); }
.tooltip   { z-index: z('tooltip'); }
.dropdown  { z-index: z('dropdown'); }
```

---

## 5. Maps & Loops — Automated Token Generation

### A. Generating Utility Classes from Maps

```scss
// utilities/_spacing.scss
@use '../tokens' as t;

$spacing-map: (
  '0':  0,
  '1':  t.$spacing-1,
  '2':  t.$spacing-2,
  '3':  t.$spacing-3,
  '4':  t.$spacing-4,
  '6':  t.$spacing-6,
  '8':  t.$spacing-8,
  '12': t.$spacing-12,
);

@each $key, $value in $spacing-map {
  .mt-#{$key} { margin-block-start: $value; }
  .mb-#{$key} { margin-block-end: $value; }
  .ml-#{$key} { margin-inline-start: $value; }
  .mr-#{$key} { margin-inline-end: $value; }
  .p-#{$key}  { padding: $value; }
  .px-#{$key} { padding-inline: $value; }
  .py-#{$key} { padding-block: $value; }
}
```

### B. Generating CSS Custom Properties from SCSS Maps

```scss
// Bridge SCSS tokens → CSS custom properties
$color-tokens: (
  'primary':       t.$color-primary,
  'primary-hover': t.$color-primary-hover,
  'text':          t.$color-text,
  'text-muted':    t.$color-text-muted,
  'surface':       t.$color-surface,
  'border':        t.$color-border,
);

:root {
  @each $name, $value in $color-tokens {
    --color-#{$name}: #{$value};
  }
}
```

---

## 6. File Architecture — The 7-1 Pattern

```text
scss/
├── abstracts/
│   ├── _index.scss          # @forward all abstracts
│   ├── _tokens.scss         # Design token variables
│   ├── _mixins.scss         # All mixins (or split into individual files)
│   └── _functions.scss      # Pure computation functions
├── base/
│   ├── _index.scss
│   ├── _reset.scss          # Modern CSS reset
│   ├── _typography.scss     # Global typography rules
│   └── _global.scss         # html, body, root defaults
├── components/
│   ├── _index.scss
│   ├── _button.scss
│   ├── _card.scss
│   ├── _modal.scss
│   └── _input.scss
├── layouts/
│   ├── _index.scss
│   ├── _grid.scss
│   ├── _sidebar.scss
│   └── _header.scss
├── pages/
│   ├── _home.scss
│   └── _dashboard.scss
├── themes/
│   ├── _light.scss
│   └── _dark.scss
├── utilities/
│   ├── _index.scss
│   └── _helpers.scss
└── main.scss                # Single entry point
```

### `main.scss` — The Entry Point

```scss
// main.scss — @use order matters: load tokens → base → components → etc.
@use 'abstracts';
@use 'base';
@use 'components';
@use 'layouts';
@use 'pages';
@use 'themes';
@use 'utilities';
```

---

## 7. Placeholder Selectors (`%placeholder`)

Use placeholders for style inheritance that should NOT generate CSS unless `@extend`ed:

```scss
%flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
}

%card-base {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: $radius-lg;
  padding: $spacing-6;
}

.modal   { @extend %flex-center; }
.overlay { @extend %flex-center; }
.card    { @extend %card-base; }
```

### Rules
- ✅ Use `%placeholder` for shared patterns that you `@extend`.
- ❌ **NEVER** use `@extend` on regular classes (`.btn`). It creates unexpected CSS output and source-order dependencies.
- ✅ **Prefer mixins over `@extend`** when the pattern includes parameters or when you need control over output location.

---

## 8. BEM with SCSS Nesting

```scss
.card {
  background: var(--color-surface);
  border-radius: $radius-lg;

  &__header {
    padding: $spacing-4;
    border-bottom: 1px solid var(--color-border);
  }

  &__body {
    padding: $spacing-6;
  }

  &__footer {
    padding: $spacing-4;
    display: flex;
    justify-content: flex-end;
    gap: $spacing-2;
  }

  &--featured {
    border: 2px solid var(--color-primary);
    box-shadow: $shadow-lg;
  }

  &--compact {
    .card__body { padding: $spacing-3; }
    .card__footer { padding: $spacing-2; }
  }
}
```

---

## 9. Summary of Banned Practices

- `@import` (Use `@use` / `@forward` exclusively).
- Nesting deeper than 3 levels (Indicates structural issues).
- `@extend` on regular classes (Use `%placeholder` or mixins).
- Hardcoded magic values (Use token variables).
- Variables without `!default` in library/shared code.
- `sass:math` division with `/` operator (Use `math.div()`).
- Unnamed color variables (`$c1`, `$color2` — use semantic names).
- Generating unused utility classes (Generate only what is consumed).

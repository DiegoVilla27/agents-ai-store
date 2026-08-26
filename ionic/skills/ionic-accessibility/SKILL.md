---
name: ionic-accessibility
description: The ultimate architectural standard for Mobile Accessibility (a11y), Screen Readers (VoiceOver/TalkBack), WCAG 2.2 AA Compliance, and Dynamic Type in Ionic.
author: Diego Villanueva
trigger: When auditing accessibility, supporting screen readers, implementing dynamic type/scaling, or ensuring WCAG 2.2 compliance in Ionic.
---

# Enterprise Ionic Accessibility (a11y) Architecture

Mobile applications must be fully accessible to users with visual, auditory, motor, or cognitive impairments. Enterprise Ionic apps strictly enforce **WCAG 2.2 AA Compliance**, full **VoiceOver (iOS)** and **TalkBack (Android)** compatibility, and **Dynamic Type** support.

---

## 1. Screen Reader Compatibility with Ionic Shadow DOM

Ionic Web Components use Shadow DOM, which can sometimes obscure accessibility trees if ARIA attributes are placed incorrectly.

**❌ NEVER** place an icon button without an accessible label.
**✅ ALWAYS** provide `aria-label` or explicit text to interactive elements.

```html
<!-- ❌ UNACCEPTABLE: Screen reader only announces "button, unlabelled" -->
<ion-button (click)="onDelete()">
  <ion-icon name="trash" />
</ion-button>

<!-- ✅ ALWAYS: Accessible with clear VoiceOver/TalkBack announcement -->
<ion-button (click)="onDelete()" aria-label="Delete contact record">
  <ion-icon name="trash" aria-hidden="true" />
</ion-button>
```

---

## 2. Touch Target Minimum Sizes (WCAG 2.2 Standard)

Touch targets on mobile devices MUST be at least **44x44 CSS pixels** (iOS Human Interface Guidelines) and **48x48 dp** (Android Material Design).

```scss
// theme/accessibility.scss
.interactive-target {
  min-width: 48px;
  min-height: 48px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

// Ensure icon buttons meet the minimum touch target requirement
ion-button.icon-only {
  --padding-start: 12px;
  --padding-end: 12px;
  min-height: 48px;
}
```

---

## 3. Dynamic Type & Font Scaling Support

Users with low vision frequently increase their system font size in iOS/Android settings. The app MUST scale typography gracefully without cutting off text.

```scss
// Avoid hardcoded fixed pixel font sizes and heights
// Use rem / relative units that respect device scaling

:root {
  --ion-font-family: system-ui, -apple-system, sans-serif;
}

.card-title {
  font-size: 1.25rem; // Scales with user root font preference
  line-height: 1.4;
  overflow-wrap: break-word; // Prevent clipping
}

// ❌ NEVER lock containers to fixed pixel heights that clip scaled text
// .fixed-banner { height: 60px; }

// ✅ ALWAYS use min-height with auto growth
.scalable-banner {
  min-height: 60px;
  height: auto;
  padding: 12px;
}
```

---

## 4. Live Regions for Dynamic Updates (`aria-live`)

When background operations complete (e.g. sync finished, form submitted, item added to cart), screen reader users must be notified without changing focus:

```html
<div aria-live="polite" aria-atomic="true" class="sr-only">
  @if (statusMessage()) {
    <p>{{ statusMessage() }}</p>
  }
</div>
```

```scss
// Visually hidden helper class (audible to screen readers only)
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

---

## 5. High Contrast & Reduced Motion

```scss
// Respect user preference for reduced motion
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

// Respect high-contrast mode
@media (prefers-contrast: more) {
  :root {
    --ion-color-primary: #0000ff;
    --ion-text-color: #000000;
    --ion-border-color: #000000;
  }
}
```

---

**Execution Protocol**
1. **Always test with TalkBack and VoiceOver enabled**: Verify every button and form input can be focused and clearly described.
2. **Never rely on color alone to convey state**: Pair color indicators with icons or text labels (e.g. "Error", "Success").
3. **Always ensure contrast ratio >= 4.5:1**: For all body text against backgrounds (WCAG AA).
4. **Never disable pinch-to-zoom in `index.html`**: Do not use `user-scalable=no` or `maximum-scale=1.0`.

---
name: angular-material-cdk
description: The ultimate architectural standard for Enterprise Angular Material & CDK Global M3 Theming, Virtual Scrolling, CDK Overlays, Portals, and Accessibility.
author: Diego Villanueva
trigger: When building UI components, dropdowns, tables, drag-and-drop interfaces, or applying global themes.
---

# Enterprise Angular Material & CDK Architecture

Angular Material is an opinionated implementation of Material Design 3 (M3). However, its underlying engine, the **Component Dev Kit (CDK)**, is arguably the most powerful suite of UI primitives in the frontend ecosystem.

In Enterprise architecture, you must master the CDK to build custom, highly-performant UI components without necessarily looking like a "Google App".

## 1. Global Theming & Overriding Styles (M3)

The biggest mistake developers make is trying to customize Material components by throwing `::ng-deep` and `!important` tags everywhere. This destroys encapsulation and makes upgrades impossible.

**❌ NEVER** use `::ng-deep` to style Angular Material components.
**✅ ALWAYS** use the official SCSS mixins and CSS custom properties (variables) provided by the Material 3 specification.

```scss
// ✅ ALWAYS: Use official SCSS mixins for custom theming
@use '@angular/material' as mat;

@include mat.core();

// Define your custom M3 palettes
$my-primary: mat.define-palette(mat.$indigo-palette, 500);
$my-accent: mat.define-palette(mat.$pink-palette, A200, A100, A400);

$my-theme: mat.define-light-theme((
  color: (
    primary: $my-primary,
    accent: $my-accent,
  ),
  typography: mat.define-typography-config(),
  density: 0,
));

// Apply the theme to the entire app
@include mat.all-component-themes($my-theme);

// To override a specific component's styles safely:
.custom-card {
  --mdc-elevated-card-container-color: #f5f5f5;
  --mdc-elevated-card-container-elevation: 4px;
}
```

## 2. CDK Overlays (Popovers, Tooltips, Dropdowns)

Never build a custom dropdown by manually calculating `top` and `left` with JavaScript or using `position: absolute`. It will break when the user scrolls or resizes the window, or it will be clipped by `overflow: hidden` containers.

**✅ ALWAYS** use `CdkOverlay` to render floating UI elements. It renders them globally outside the DOM hierarchy (in the `cdk-overlay-container`) but visually attaches them to your target element.

```typescript
// ✅ ALWAYS: Use CDK Overlay for floating UI
import { Component, ViewChild, TemplateRef, inject } from '@angular/core';
import { Overlay, OverlayRef } from '@angular/cdk/overlay';
import { TemplatePortal } from '@angular/cdk/portal';

@Component({
  selector: 'app-custom-dropdown',
  template: `
    <button (click)="openMenu()" cdkOverlayOrigin #origin="cdkOverlayOrigin">
      Options
    </button>
    
    <ng-template #menuTemplate>
      <div class="my-dropdown">Item 1</div>
    </ng-template>
  `
})
export class CustomDropdownComponent {
  @ViewChild('menuTemplate') menuTemplate!: TemplateRef<any>;
  
  private readonly overlay = inject(Overlay);
  private overlayRef: OverlayRef | null = null;
  private readonly vcr = inject(ViewContainerRef);

  openMenu() {
    // 1. Define positioning strategy (e.g., attach bottom-left of the button)
    const positionStrategy = this.overlay.position()
      .flexibleConnectedTo(this.origin.elementRef)
      .withPositions([{
        originX: 'start', originY: 'bottom',
        overlayX: 'start', overlayY: 'top',
      }]);

    // 2. Create the overlay
    this.overlayRef = this.overlay.create({
      positionStrategy,
      hasBackdrop: true,
      backdropClass: 'cdk-overlay-transparent-backdrop'
    });

    // 3. Attach the template (Portal) to the overlay
    const portal = new TemplatePortal(this.menuTemplate, this.vcr);
    this.overlayRef.attach(portal);

    // 4. Handle backdrop clicks to close
    this.overlayRef.backdropClick().subscribe(() => this.overlayRef?.detach());
  }
}
```

## 3. CDK Portals (Teleporting UI)

If you need to render a specific Toolbar inside a generic `<app-header>` that lives outside your current routed component, you MUST use CDK Portals. Portals allow you to teleport templates or components from one place in the DOM to another.

```html
<!-- Inside the global App Layout (The Target) -->
<div class="global-header">
  <ng-template [cdkPortalOutlet]="headerPortal"></ng-template>
</div>

<!-- Inside a routed component (The Source) -->
<ng-template cdkPortal>
  <button>Save Document</button>
</ng-template>
```

## 4. Virtual Scrolling (Extreme Performance)

If you render a table or list with 5,000 items using `@for` or `*ngFor`, the browser will crash because it has to paint 5,000 DOM nodes.

**✅ ALWAYS** use `CdkVirtualScrollViewport` for large datasets. It only renders the 15-20 nodes that are currently visible on the screen, recycling them as the user scrolls.

```html
<!-- ✅ ALWAYS: Use Virtual Scrolling for large lists -->
<cdk-virtual-scroll-viewport itemSize="50" class="example-viewport">
  <!-- Only renders what fits in the viewport -->
  <div *cdkVirtualFor="let item of hugeArray" class="example-item">
    {{item.name}}
  </div>
</cdk-virtual-scroll-viewport>
```
*(Note: Requires a fixed height on the viewport container).*

## 5. Accessibility (A11y) & Focus Management

Enterprise apps MUST be usable by visually impaired users with screen readers.

### A. LiveAnnouncer
If a background process finishes or a form errors out dynamically, the screen reader won't know. You MUST announce it.

```typescript
import { LiveAnnouncer } from '@angular/cdk/a11y';

export class CheckoutComponent {
  private readonly announcer = inject(LiveAnnouncer);

  onPaymentSuccess() {
    this.announcer.announce('Payment successful. Your order is confirmed.', 'assertive');
  }
}
```

### B. FocusMonitor
Browsers show ugly blue outlines around buttons when clicked. Instead of hiding outlines with `outline: none` (which ruins accessibility for keyboard users), use `FocusMonitor` to detect if the user clicked with a mouse or a keyboard, and style accordingly.

```scss
// CDK adds classes like .cdk-keyboard-focused automatically!
button {
  outline: none; // Safe to remove
}

button.cdk-keyboard-focused {
  outline: 2px solid blue; // Only show for keyboard navigation!
}
```

---

**Execution Protocol**
1. **Tables**: When using `mat-table`, ALWAYS use a `MatTableDataSource`. Do not bind raw arrays to the `[dataSource]` input. The DataSource class provides built-in, highly optimized sorting and pagination logic.
2. **Drag and Drop**: Do not install third-party libraries for Drag and Drop. The `@angular/cdk/drag-drop` module handles sorting, free dragging, and transferring items between lists natively at 60fps.
3. **Form Fields**: If you build a custom input (e.g., an OTP code input) and want it to look like a Material input (with the floating label and underline), your custom component MUST implement the `MatFormFieldControl` interface.

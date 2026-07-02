---
name: angular-animations
description: The ultimate architectural standard for Angular Animations WAAPI, Reusable parameterized animations, Staggered queries, and Route transitions.
author: Diego Villanueva
trigger: When creating complex structural animations (Enter/Leave), animating lists, building route transitions, or using @angular/animations.
---

# Enterprise Angular Animations Architecture

Angular's `@angular/animations` module is a powerful DSL (Domain Specific Language) built on top of the Web Animations API (WAAPI). It allows you to choreograph complex, state-based animations directly tied to your component logic.

However, if misused, it leads to spaghetti code, layout thrashing, and crashed applications.

**CRITICAL RULE**: Do NOT use Angular Animations for simple hover effects (`:hover`), focus states, or color transitions. Those MUST be handled by pure CSS (`transition: all 0.3s ease`). Angular Animations are strictly for **structural DOM changes** (elements entering/leaving the DOM via `@if` / `@for`) and complex state orchestrations.

## 1. Reusable Parameterized Animations (DRY)

A common mistake is copying and pasting `trigger('fadeIn')` into 50 different components. In an Enterprise app, you MUST create a central library of reusable animations using the `animation()` and `useAnimation()` functions.

```typescript
// ✅ ALWAYS: Create reusable parameterized animations in a central file
// src/app/shared/animations/fade.animation.ts
import { animation, style, animate } from '@angular/animations';

export const fadeAnimation = animation([
  style({ opacity: '{{ startOpacity }}' }),
  animate('{{ time }} {{ timingFunction }}', style({ opacity: '{{ endOpacity }}' }))
], {
  // Default parameters
  params: {
    startOpacity: 0,
    endOpacity: 1,
    time: '300ms',
    timingFunction: 'ease-in-out'
  }
});

// ✅ ALWAYS: Use them in components via useAnimation()
import { Component } from '@angular/core';
import { trigger, transition, useAnimation } from '@angular/animations';
import { fadeAnimation } from '@shared/animations/fade.animation';

@Component({
  selector: 'app-modal',
  templateUrl: './modal.component.html',
  animations: [
    trigger('modalFade', [
      transition(':enter', [
        useAnimation(fadeAnimation, { params: { time: '500ms' } })
      ]),
      transition(':leave', [
        useAnimation(fadeAnimation, { params: { startOpacity: 1, endOpacity: 0, time: '200ms' } })
      ])
    ])
  ]
})
export class ModalComponent {}
```

## 2. Staggered List Animations & Safe Queries

When rendering a list of items (`@for` or `*ngFor`), they shouldn't all appear at the exact same millisecond. They should cascade gracefully.

You use `query()` and `stagger()` for this. 

**CRITICAL RULE**: If `query()` looks for an element and doesn't find it, the entire animation crashes the app. You MUST ALWAYS add `{ optional: true }` to queries unless you mathematically guarantee the element's existence.

```typescript
// ✅ ALWAYS: Use stagger for lists and ALWAYS make queries optional
import { trigger, transition, style, animate, query, stagger } from '@angular/animations';

export const listAnimation = trigger('listAnimation', [
  // Trigger whenever the length of the list changes
  transition('* <=> *', [
    // 1. Initial state of entering elements
    query(':enter', [
      style({ opacity: 0, transform: 'translateY(-15px)' })
    ], { optional: true }), // <--- CRITICAL: Prevents crashes if list is empty

    // 2. Animate them in sequentially with a 50ms delay between each
    query(':enter', [
      stagger('50ms', [
        animate('300ms ease-out', style({ opacity: 1, transform: 'translateY(0)' }))
      ])
    ], { optional: true }),

    // 3. Animate exiting elements out
    query(':leave', [
      stagger('-50ms', [ // Negative stagger removes them from bottom to top
        animate('200ms ease-in', style({ opacity: 0, height: '0px' }))
      ])
    ], { optional: true })
  ])
]);
```
*Usage in HTML: `<div [@listAnimation]="items.length">`*

## 3. The `void` State (Enter / Leave)

An element is in the `void` state if it is not in the DOM (e.g., hidden by an `@if`).

Instead of writing `void => *` (from void to any state) and `* => void`, you MUST use the semantic aliases:
- `:enter` (Alias for `void => *`)
- `:leave` (Alias for `* => void`)
- `:increment` and `:decrement` (For numeric state changes, like counters or list lengths)

## 4. Complex Keyframes (Cinematic Effects)

If an animation requires more than a simple A -> B transition (e.g., a "shake" effect on an invalid password field), you MUST use `keyframes()`.

```typescript
// ✅ ALWAYS: Use keyframes for multi-step physics-based animations
import { trigger, transition, style, animate, keyframes } from '@angular/animations';

export const shakeAnimation = trigger('shake', [
  transition('* => invalid', [
    animate('400ms', keyframes([
      style({ transform: 'translateX(0)', offset: 0 }),
      style({ transform: 'translateX(-10px)', offset: 0.2 }),
      style({ transform: 'translateX(10px)', offset: 0.4 }),
      style({ transform: 'translateX(-10px)', offset: 0.6 }),
      style({ transform: 'translateX(10px)', offset: 0.8 }),
      style({ transform: 'translateX(0)', offset: 1.0 })
    ]))
  ])
]);
```

## 5. Route Transitions (Animating `<router-outlet>`)

Animating page transitions gives the app a Single Page Application (SPA) premium feel.

To do this, you must bind the animation to the `router-outlet` using the route's data.

```typescript
// 1. App Routing Module
export const routes: Routes = [
  { path: 'home', component: HomeComponent, data: { animation: 'HomePage' } },
  { path: 'about', component: AboutComponent, data: { animation: 'AboutPage' } }
];

// 2. App Component HTML
// <main [@routeAnimations]="getRouteAnimationData()">
//   <router-outlet></router-outlet>
// </main>

// 3. Route Animation Definition
export const slideInAnimation = trigger('routeAnimations', [
  transition('* <=> *', [
    // Prepare the host element
    style({ position: 'relative' }),
    
    // Prepare entering and leaving elements
    query(':enter, :leave', [
      style({
        position: 'absolute',
        top: 0, left: 0, width: '100%'
      })
    ], { optional: true }),
    
    // Position entering element off-screen to the right
    query(':enter', [
      style({ transform: 'translateX(100%)' })
    ], { optional: true }),
    
    // Animate both elements simultaneously (Group)
    group([
      query(':leave', [
        animate('300ms ease-out', style({ transform: 'translateX(-100%)', opacity: 0 }))
      ], { optional: true }),
      query(':enter', [
        animate('300ms ease-out', style({ transform: 'translateX(0)' }))
      ], { optional: true })
    ])
  ])
]);
```

---

**Execution Protocol**
1. **The `group()` function**: If you want to animate opacity AND transform at the same time, or if you want to animate two different elements (like `:enter` and `:leave`) perfectly in parallel, you MUST wrap their animations in `group()`.
2. **Animation Callbacks**: You can listen to when an animation starts or ends in the template: `(@fade.start)="onStart($event)"` and `(@fade.done)="onDone($event)"`. This is crucial for cleaning up state or disabling buttons while an animation runs.
3. **Accessibility (Reduced Motion)**: Always respect the user's OS settings. If a user has "Prefers Reduced Motion" enabled, animations can cause motion sickness. Angular 17+ does not have an automatic toggle for this in the animations module, so for critical animations, use a global service that checks `window.matchMedia('(prefers-reduced-motion: reduce)').matches` and disables the animation state if true. Alternatively, use `provideNoopAnimations()` based on this flag at bootstrap.

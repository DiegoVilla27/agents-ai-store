---
name: ionic-animations
description: The ultimate architectural standard for Ionic Animations, Web Animations API, Gesture-Driven Animations, and Custom Page Transitions.
author: Diego Villanueva
trigger: When creating custom animations, gesture-driven interactions, custom modal transitions, or micro-interactions in Ionic.
---

# Enterprise Ionic Animations & Gestures Architecture

Ionic provides a high-performance animation engine (`AnimationController` / `createAnimation`) built directly on top of the browser's native **Web Animations API (WAAPI)**. It bypasses framework-level tick loops and executes directly on the browser's compositor thread.

---

## 1. Ionic Animation API (`createAnimation`)

**❌ NEVER** manipulate inline styles manually in requestAnimationFrame loops.
**✅ ALWAYS** build composable animations with `AnimationController` / `createAnimation()`.

```typescript
import { Component, ElementRef, ViewChild, inject } from '@angular/core';
import { AnimationController, IonButton, IonCard, IonContent } from '@ionic/angular/standalone';

@Component({
  selector: 'app-interactive-card',
  standalone: true,
  imports: [IonButton, IonCard, IonContent],
  template: `
    <ion-content class="ion-padding">
      <ion-card #animatedCard class="card-box">
        <h2>Interactive Card</h2>
        <p>Smooth 60fps WAAPI Animation</p>
      </ion-card>

      <ion-button expand="block" (click)="triggerPulse()">Pulse Animation</ion-button>
    </ion-content>
  `,
  styles: [`
    .card-box {
      padding: 24px;
      border-radius: 16px;
      text-align: center;
    }
  `]
})
export class InteractiveCardComponent {
  @ViewChild('animatedCard', { read: ElementRef }) cardRef!: ElementRef<HTMLElement>;
  private readonly animationCtrl = inject(AnimationController);

  triggerPulse(): void {
    const pulseAnimation = this.animationCtrl
      .create()
      .addElement(this.cardRef.nativeElement)
      .duration(400)
      .iterations(1)
      .easing('cubic-bezier(0.34, 1.56, 0.64, 1)') // Spring pop effect
      .keyframes([
        { offset: 0, transform: 'scale(1)', opacity: '1' },
        { offset: 0.5, transform: 'scale(1.08)', opacity: '0.9' },
        { offset: 1, transform: 'scale(1)', opacity: '1' },
      ]);

    pulseAnimation.play();
  }
}
```

---

## 2. Gesture-Driven Animations (`GestureController`)

For swipe-to-dismiss, drag-to-reveal, or pull-sheet interactions running natively at device refresh rates:

```typescript
import { Component, ElementRef, ViewChild, AfterViewInit, inject } from '@angular/core';
import { GestureController, AnimationController, Animation } from '@ionic/angular/standalone';

@Component({
  selector: 'app-swipeable-card',
  standalone: true,
  template: `
    <div #swipeCard class="swipe-box">
      <h3>Swipe me horizontally</h3>
    </div>
  `,
  styles: [`
    .swipe-box {
      width: 100%;
      height: 120px;
      background: var(--ion-color-primary);
      color: #fff;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 12px;
      touch-action: pan-y; /* Critical: allow vertical scroll while capturing horizontal pan */
    }
  `]
})
export class SwipeableCardComponent implements AfterViewInit {
  @ViewChild('swipeCard') swipeCardRef!: ElementRef<HTMLElement>;
  private readonly gestureCtrl = inject(GestureController);
  private readonly animationCtrl = inject(AnimationController);

  private anim!: Animation;

  ngAfterViewInit(): void {
    const el = this.swipeCardRef.nativeElement;
    const windowWidth = window.innerWidth;

    // Define base animation representing 100% swipe progress
    this.anim = this.animationCtrl
      .create()
      .addElement(el)
      .duration(1000)
      .fromTo('transform', 'translateX(0px)', `translateX(${windowWidth}px)`)
      .fromTo('opacity', '1', '0.2');

    // Attach gesture controller
    const gesture = this.gestureCtrl.create({
      el,
      threshold: 10,
      gestureName: 'card-swipe',
      onStart: () => {
        this.anim.progressStart(true, 0);
      },
      onMove: (ev) => {
        const step = Math.max(0, Math.min(1, ev.deltaX / windowWidth));
        this.anim.progressStep(step);
      },
      onEnd: (ev) => {
        const step = Math.max(0, Math.min(1, ev.deltaX / windowWidth));
        const shouldDismiss = step > 0.4 || ev.velocityX > 0.5;

        this.anim.progressEnd(shouldDismiss ? 1 : 0, step, 300).then(() => {
          if (shouldDismiss) {
            console.log('Card dismissed!');
          }
        });
      },
    });

    gesture.enable(true);
  }
}
```

---

## 3. Custom Modal Transition Animation

Override default modal transitions with custom brand animations:

```typescript
// shared/animations/custom-modal.animation.ts
import { Animation, createAnimation } from '@ionic/angular/standalone';

export const customModalEnterAnimation = (baseEl: HTMLElement): Animation => {
  const root = baseEl.shadowRoot || baseEl;
  const backdropAnimation = createAnimation()
    .addElement(root.querySelector('ion-backdrop')!)
    .fromTo('opacity', '0.01', 'var(--backdrop-opacity)');

  const wrapperAnimation = createAnimation()
    .addElement(root.querySelector('.modal-wrapper')!)
    .keyframes([
      { offset: 0, opacity: '0', transform: 'scale(0.85) translateY(40px)' },
      { offset: 1, opacity: '1', transform: 'scale(1) translateY(0px)' },
    ]);

  return createAnimation()
    .addElement(baseEl)
    .easing('cubic-bezier(0.2, 0.8, 0.2, 1)')
    .duration(350)
    .addAnimation([backdropAnimation, wrapperAnimation]);
};
```

---

**Execution Protocol**
1. **Always use Web Animations API (`createAnimation`)**: Avoid heavy JS timer libraries for UI transitions.
2. **Always set `touch-action: pan-y` on horizontal gestures**: Prevents blocking native vertical scroll behavior.
3. **Always call `progressEnd()` properly**: Ensure gesture-driven animations cleanly resolve to 0 or 1 without visual artifacts.
4. **Respect `prefers-reduced-motion`**: Check user accessibility settings and disable flashy spring animations when requested.

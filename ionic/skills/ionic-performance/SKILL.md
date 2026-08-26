---
name: ionic-performance
description: The ultimate architectural standard for High-Performance Ionic Applications, Virtual Scrolling, Bundle Budgets, Web Worker Offloading, and 60/120fps Rendering.
author: Diego Villanueva
trigger: When optimizing Ionic app speed, addressing janky animations, handling massive list rendering, reducing bundle size, or profiling runtime performance.
---

# Enterprise Ionic Performance Architecture (60/120 FPS Mandate)

Hybrid apps run inside a platform WebView (WebKit on iOS, Chromium on Android). To compete with fully native applications, an Ionic Architect must eliminate main-thread bottlenecks, avoid unnecessary DOM recalculations, and maintain a constant 60/120 FPS render cycle.

---

## 1. Virtual Scrolling for Large Collections

Rendering 500+ DOM nodes inside `ion-content` causes garbage collection stutter and scroll jank.

**❌ NEVER** use a basic `@for` loop over hundreds of complex card items.
**✅ ALWAYS** use CDK Virtual Scroll with fixed or item-sized viewports.

```typescript
import { Component, ChangeDetectionStrategy, signal } from '@angular/core';
import { ScrollingModule } from '@angular/cdk/scrolling';
import { IonContent, IonItem, IonLabel, IonAvatar } from '@ionic/angular/standalone';

@Component({
  selector: 'app-transaction-feed',
  standalone: true,
  imports: [ScrollingModule, IonContent, IonItem, IonLabel, IonAvatar],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ion-content>
      <!-- cdk-virtual-scroll-viewport only renders items visible on screen + small buffer -->
      <cdk-virtual-scroll-viewport itemSize="72" minBufferPx="360" maxBufferPx="720" class="virtual-viewport">
        <ion-item *cdkVirtualFor="let tx of transactions(); trackBy: trackById">
          <ion-avatar slot="start">
            <img [src]="tx.avatar" alt="Avatar" loading="lazy" />
          </ion-avatar>
          <ion-label>
            <h2>{{ tx.title }}</h2>
            <p>{{ tx.date }}</p>
          </ion-label>
          <span slot="end" [class.positive]="tx.amount > 0">
            {{ tx.amount | currency }}
          </span>
        </ion-item>
      </cdk-virtual-scroll-viewport>
    </ion-content>
  `,
  styles: [`
    .virtual-viewport {
      height: 100%;
      width: 100%;
    }
  `]
})
export class TransactionFeedPage {
  readonly transactions = signal<Transaction[]>([]);

  trackById(_: number, item: Transaction): string {
    return item.id;
  }
}
```

---

## 2. Heavy Computation via Web Workers

Parsing 5MB JSON responses or performing client-side encryption on the UI thread freezes animations and touch gestures.

```typescript
// core/workers/heavy-computation.worker.ts
/// <reference lib="webworker" />

addEventListener('message', ({ data }) => {
  const { rawData, filterQuery } = data;
  // Heavy CPU work isolated completely off the main UI thread
  const processed = performExpensiveFilteringAndAggregation(rawData, filterQuery);
  postMessage(processed);
});

function performExpensiveFilteringAndAggregation(data: any[], query: string): any[] {
  // Heavy crunching...
  return data.filter(d => JSON.stringify(d).includes(query));
}
```

```typescript
// features/reports/services/report-processor.service.ts
@Injectable({ providedIn: 'root' })
export class ReportProcessorService {
  processDataAsync(rawData: any[], filterQuery: string): Promise<any[]> {
    return new Promise((resolve, reject) => {
      if (typeof Worker !== 'undefined') {
        const worker = new Worker(new URL('../../workers/heavy-computation.worker', import.meta.url), { type: 'module' });
        worker.onmessage = ({ data }) => {
          resolve(data);
          worker.terminate();
        };
        worker.onerror = (err) => {
          reject(err);
          worker.terminate();
        };
        worker.postMessage({ rawData, filterQuery });
      } else {
        // Fallback for environments without worker support
        resolve(rawData);
      }
    });
  }
}
```

---

## 3. Hardware-Accelerated CSS Transitions

Mobile GPU composition is triggered only on `transform` and `opacity`.

**❌ NEVER** animate `top`, `left`, `margin`, `width`, or `height` (triggers layout recalculation).
**✅ ALWAYS** animate `transform: translate3d(x, y, z)` and `opacity`.

```scss
// ❌ ATROCIOUS: Triggers Layout & Repaint on every frame (15fps lag)
.drawer-legacy {
  transition: height 0.3s ease;
  height: 0px;
  &.open {
    height: 300px;
  }
}

// ✅ ALWAYS: GPU Composited (60/120fps smooth)
.drawer-modern {
  will-change: transform;
  transform: translate3d(0, 100%, 0);
  transition: transform 0.3s cubic-bezier(0.32, 0.72, 0, 1);

  &.open {
    transform: translate3d(0, 0, 0);
  }
}
```

---

## 4. Angular Deferrable Views (`@defer`) in Ionic

Ionic pages often contain heavy components (charts, camera previews, Google Maps) that are only shown when scrolled into view or after interaction.

```html
<ion-content class="ion-padding">
  <!-- Critical Above-the-fold content loads immediately -->
  <app-account-summary [balance]="balance()" />

  <!-- Heavy Chart component is deferred until the user scrolls it into viewport -->
  @defer (on viewport) {
    <app-analytics-chart [data]="chartData()" />
  } @placeholder {
    <ion-skeleton-text [animated]="true" style="width: 100%; height: 250px; border-radius: 16px;" />
  } @loading (minimum 300ms) {
    <div class="chart-loading-spinner"><ion-spinner /></div>
  }
</ion-content>
```

---

## 5. Strict Bundle Budgets (`angular.json`)

To prevent accidental library bloat in production bundles:

```json
"budgets": [
  {
    "type": "initial",
    "maximumWarning": "450kb",
    "maximumError": "800kb"
  },
  {
    "type": "anyComponentStyle",
    "maximumWarning": "4kb",
    "maximumError": "8kb"
  }
]
```

---

**Execution Protocol**
1. **Always use OnPush Change Detection**: Every component must declare `changeDetection: ChangeDetectionStrategy.OnPush`.
2. **Always virtualize lists > 50 items**: Prevent DOM overload with CDK Virtual Scrolling.
3. **Always use `will-change: transform` on animated elements**: Promotes layers to GPU compositor.
4. **Never execute heavy JSON/Crypto loops on the main thread**: Offload to Web Workers.
5. **Always test on physical low-end devices**: Web inspector emulators are 10x faster than budget Android phones.

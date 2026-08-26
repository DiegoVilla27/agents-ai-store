---
name: angular-zoneless
description: The ultimate architectural standard for 100% Zoneless Angular Applications with provideExperimentalZonelessChangeDetection(), Signal-Driven Scheduling, and Third-Party Non-Signal Library Integration.
author: Diego Villanueva
trigger: When building or migrating to Zoneless Angular apps, eliminating zone.js, configuring change detection schedulers, or integrating third-party libraries without Zone.
---

# Enterprise Zoneless Angular Architecture (v18 & v19+)

Historically, Angular relied on `zone.js` to monkey-patch all browser asynchronous APIs (`setTimeout`, `Promise`, DOM events) to trigger change detection globally. While convenient in early Angular versions, Zone.js adds ~100kb to bundle sizes, causes performance degradation on heavy DOM events, and complicates debugging with mangled async stack traces.

**Modern Angular is Zoneless.**

---

## 1. Enabling Zoneless in Application Bootstrap

To eliminate `zone.js` completely from your application:

### Step 1: Remove `zone.js` from `angular.json`
Remove `'zone.js'` from the `polyfills` array in `angular.json`:

```json
"polyfills": []
```

### Step 2: Configure Zoneless Provider in `app.config.ts`

```typescript
// app.config.ts
import { ApplicationConfig, provideExperimentalZonelessChangeDetection } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    // ✅ ALWAYS: Enable Zoneless change detection
    provideExperimentalZonelessChangeDetection(),
    provideRouter(routes, withComponentInputBinding()),
  ],
};
```

---

## 2. How Change Detection Works Without Zone.js

In Zoneless Angular, change detection is strictly **Signal-driven and Event-driven**. Angular schedules a render cycle only when:

1. A **Signal** read in a visible component template emits a new value.
2. A component DOM **Event Listener** (`(click)`, `(submit)`) fires.
3. An **Async Pipe** (`| async`) receives a new emission.
4. A component is created or destroyed.
5. Explicit notification is sent via `ChangeDetectorRef.markForCheck()`.

**❌ CRITICAL ANTI-PATTERN**: Modifying a plain JavaScript property (`this.counter++`) without a Signal or `markForCheck()` will **NEVER** update the UI in a Zoneless application!

```typescript
// ❌ BROKEN IN ZONELESS: Plain variable mutation
export class BrokenComponent {
  count = 0;

  increment() {
    setTimeout(() => {
      this.count++; // UI will NEVER update because Zone.js is absent!
    }, 1000);
  }
}

// ✅ ALWAYS: Use Angular Signals (Zoneless Native)
export class ModernComponent {
  readonly count = signal(0);

  increment() {
    setTimeout(() => {
      this.count.update(c => c + 1); // Signals notify the Zoneless scheduler automatically!
    }, 1000);
  }
}
```

---

## 3. Integrating Non-Signal Third-Party Libraries

When integrating libraries that emit events outside Angular's Signal graph (e.g. Leaflet, Chart.js, Socket.io, Stripe Elements):

```typescript
import { Component, ChangeDetectorRef, inject, signal } from '@angular/core';

@Component({
  selector: 'app-external-data',
  standalone: true,
  template: `<div>Status: {{ socketStatus() }}</div>`
})
export class ExternalDataComponent {
  private readonly cdr = inject(ChangeDetectorRef);
  readonly socketStatus = signal('Disconnected');

  setupExternalSocket(socket: any): void {
    socket.on('status', (newStatus: string) => {
      // Option A: Update a Signal (Recommended - triggers Zoneless CD automatically)
      this.socketStatus.set(newStatus);

      // Option B: If updating non-signal legacy properties, explicitly mark for check
      // this.legacyProperty = newStatus;
      // this.cdr.markForCheck();
    });
  }
}
```

---

## 4. Zoneless Architecture Checklist

| Rule | Requirement |
|---|---|
| **`polyfills`** | No `zone.js` or `zone.js/testing` imports. |
| **Change Detection** | Every component uses `ChangeDetectionStrategy.OnPush` or standard Zoneless scheduling. |
| **Async Operations** | All async states wrapped in `signal()`, `resource()`, or `toSignal()`. |
| **DOM Events** | No need for `NgZone.runOutsideAngular()` hacks; Zoneless does not intercept raw DOM listeners! |

---

**Execution Protocol**
1. **Never use `NgZone.run()` or `runOutsideAngular()` in Zoneless apps**: They become redundant no-ops when Zone.js is removed.
2. **Never rely on mutable class properties for UI state**: Every piece of UI-bound state must be a `Signal`.
3. **Verify `zone.js` is absent from production bundles**: Confirm bundle analysis shows zero references to Zone monkey-patches.
4. **Use Signal Inputs and Outputs**: Fully integrated with the Zoneless notification pipeline.

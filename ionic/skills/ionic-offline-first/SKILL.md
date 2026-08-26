---
name: ionic-offline-first
description: The ultimate architectural standard for Offline-First Ionic applications with Synchronization Engines, Delta Updates, Conflict Resolution (CRDT/LWW), and SQLite Cache.
author: Diego Villanueva
trigger: When designing offline-first architectures, background sync mechanisms, optimistic UI updates, or conflict resolution protocols in Ionic/Capacitor.
---

# Enterprise Ionic Offline-First Architecture

Mobile apps operate in unpredictable network conditions (underground transit, airplanes, rural zones). An application must never fail or block user interaction because of network loss. **Offline-First is an architectural foundation, not an add-on.**

---

## 1. The Offline-First Three-Tier Architecture

```text
┌─────────────────────────────────────────────────────────┐
│                     UI Layer                            │
│           (Reads exclusively from Local Cache)          │
└──────────────────────────┬──────────────────────────────┘
                           │ (Synchronous Reactive Signal)
┌──────────────────────────▼──────────────────────────────┐
│             Local Source of Truth (SQLite / IDB)        │
│       Stores complete feature state & mutations queue   │
└──────────────────────────┬──────────────────────────────┘
                           │ (Background Bi-Directional Sync)
┌──────────────────────────▼──────────────────────────────┐
│                    Sync Engine                          │
│          (Replay Queue, CRDT / Delta Push & Pull)       │
└──────────────────────────┬──────────────────────────────┘
                           │ (HTTPS / WebSocket)
┌──────────────────────────▼──────────────────────────────┐
│                    Remote Backend API                   │
└─────────────────────────────────────────────────────────┘
```

### Golden Rule:
The UI **NEVER** waits for the remote API to complete before updating. The UI modifies the Local Cache immediately (**Optimistic UI**), enqueues an `OutboxMutation`, and lets the **Sync Engine** resolve server communication in the background.

---

## 2. The Outbox Mutation Queue

```typescript
// core/offline/models/mutation.model.ts
export type MutationOperation = 'CREATE' | 'UPDATE' | 'DELETE';

export interface OutboxMutation<T = unknown> {
  id: string;              // UUIDv4
  entity: string;          // e.g. 'tasks', 'invoices'
  operation: MutationOperation;
  payload: T;
  timestamp: number;
  retryCount: number;
  status: 'PENDING' | 'SYNCING' | 'FAILED';
  errorReason?: string;
}
```

```typescript
// core/offline/sync-engine.service.ts
import { Injectable, inject, signal } from '@angular/core';
import { StorageService } from '@core/services/storage.service';
import { NetworkService } from '@core/services/network.service';
import { ApiService } from '@core/services/api.service';
import { OutboxMutation } from './models/mutation.model';

@Injectable({ providedIn: 'root' })
export class SyncEngineService {
  private readonly storage = inject(StorageService);
  private readonly network = inject(NetworkService);
  private readonly api = inject(ApiService);

  readonly pendingMutationsCount = signal(0);
  readonly isSyncing = signal(false);
  private readonly QUEUE_KEY = '__offline_outbox_queue__';

  async enqueueMutation<T>(entity: string, operation: 'CREATE' | 'UPDATE' | 'DELETE', payload: T): Promise<void> {
    const queue = await this.getQueue();
    const mutation: OutboxMutation<T> = {
      id: crypto.randomUUID(),
      entity,
      operation,
      payload,
      timestamp: Date.now(),
      retryCount: 0,
      status: 'PENDING',
    };

    queue.push(mutation);
    await this.storage.set(this.QUEUE_KEY, queue);
    this.pendingMutationsCount.set(queue.length);

    // If online, immediately trigger sync
    if (this.network.isOnline()) {
      this.processOutbox();
    }
  }

  async processOutbox(): Promise<void> {
    if (!this.network.isOnline() || this.isSyncing()) return;

    this.isSyncing.set(true);
    const queue = await this.getQueue();
    const remaining: OutboxMutation[] = [];

    for (const mutation of queue) {
      try {
        mutation.status = 'SYNCING';
        await this.dispatchToServer(mutation);
      } catch (err) {
        mutation.retryCount++;
        mutation.status = 'FAILED';
        mutation.errorReason = (err as Error).message;

        if (mutation.retryCount < 5) {
          remaining.push(mutation); // Retry on next cycle
        } else {
          console.error(`[SyncEngine] Permanent failure for mutation ${mutation.id}`, mutation);
        }
      }
    }

    await this.storage.set(this.QUEUE_KEY, remaining);
    this.pendingMutationsCount.set(remaining.length);
    this.isSyncing.set(false);
  }

  private async dispatchToServer(mutation: OutboxMutation): Promise<void> {
    const endpoint = `/api/sync/${mutation.entity}`;
    switch (mutation.operation) {
      case 'CREATE':
        await this.api.post(endpoint, mutation.payload);
        break;
      case 'UPDATE':
        await this.api.put(endpoint, mutation.payload);
        break;
      case 'DELETE':
        await this.api.delete(`${endpoint}/${(mutation.payload as { id: string }).id}`);
        break;
    }
  }

  private async getQueue(): Promise<OutboxMutation[]> {
    return (await this.storage.get<OutboxMutation[]>(this.QUEUE_KEY)) ?? [];
  }
}
```

---

## 3. Conflict Resolution Strategies

When changes happen concurrently offline on a mobile device and remotely on the server:

### Strategy 1: Last-Write-Wins (LWW) with Timestamps
Every record carries an `updatedAt: number` epoch. The highest timestamp wins.

### Strategy 2: Delta / Field-Level Merge
Instead of sending the whole entity, send only the fields that changed (`{ id: '123', price: 99.9 }`), reducing collision surface.

### Strategy 3: Server-Assisted CRDT (Conflict-Free Replicated Data Types)
For collaborative text or increment counters, use delta operations: `{ op: 'ADD_ITEM', itemId: 'abc' }`.

---

## 4. UI Indicators & Visual Feedback

Users must always know when data is syncing or waiting in the offline queue:

```html
<!-- components/sync-status-badge.component.ts -->
@if (syncEngine.pendingMutationsCount() > 0) {
  <ion-badge color="warning" class="sync-badge">
    <ion-icon name="cloud-offline-outline" />
    Syncing {{ syncEngine.pendingMutationsCount() }} changes...
  </ion-badge>
}
```

---

**Execution Protocol**
1. **Local cache is the immediate source of truth**: Mutate local state first, emit UI signals immediately.
2. **Never drop failed mutations silently**: Store retry counts and provide recovery options for permanent conflicts.
3. **Listen to Network resume events**: When `Network.addListener('networkStatusChange')` fires with `connected: true`, immediately trigger `processOutbox()`.
4. **Idempotent APIs**: Ensure backend sync endpoints accept an `idempotencyKey` (or mutation `id`) to prevent duplicate records if packets are resent.

---
name: lit-state-management
description: The definitive standard for state management patterns in Lit including external reactive stores, signals, pub/sub event bus, and third-party integrations.
author: Diego Villanueva
trigger: When managing global/shared state in Lit applications, creating reactive stores, implementing pub/sub patterns, using signals, or integrating with Zustand/Redux.
---

# Lit State Management Mastery

Lit doesn't prescribe a global state management solution. This skill covers battle-tested patterns from simple reactive stores to Lit Signals integration, giving you the right tool for every scale.

---

## 1. Reactive Store Pattern (Framework-Agnostic)

A lightweight, framework-agnostic store using `EventTarget`:

```typescript
// stores/app-store.ts
export interface AppState {
  theme: 'light' | 'dark';
  user: User | null;
  notifications: Notification[];
}

class AppStore extends EventTarget {
  private _state: AppState = {
    theme: 'light',
    user: null,
    notifications: [],
  };

  get state(): Readonly<AppState> {
    return this._state;
  }

  setState(partial: Partial<AppState>) {
    this._state = { ...this._state, ...partial };
    this.dispatchEvent(new CustomEvent('state-changed', { detail: this._state }));
  }

  // Selectors
  get theme() { return this._state.theme; }
  get user() { return this._state.user; }
  get isAuthenticated() { return this._state.user !== null; }
}

// Singleton export
export const appStore = new AppStore();
```

### Connecting to Components via Controller

```typescript
// controllers/store.controller.ts
import { ReactiveController, ReactiveControllerHost } from 'lit';

export class StoreController<T extends EventTarget & { state: any }> implements ReactiveController {
  host: ReactiveControllerHost;
  private _store: T;
  private _handler = () => this.host.requestUpdate();

  constructor(host: ReactiveControllerHost, store: T) {
    (this.host = host).addController(this);
    this._store = store;
  }

  get state() { return this._store.state; }

  hostConnected() {
    this._store.addEventListener('state-changed', this._handler);
  }

  hostDisconnected() {
    this._store.removeEventListener('state-changed', this._handler);
  }
}

// Usage in component
@customElement('theme-toggle')
export class ThemeToggle extends LitElement {
  private _store = new StoreController(this, appStore);

  render() {
    return html`
      <button @click=${this._toggle}>
        ${this._store.state.theme === 'light' ? '🌙' : '☀️'}
      </button>
    `;
  }

  private _toggle() {
    appStore.setState({
      theme: this._store.state.theme === 'light' ? 'dark' : 'light',
    });
  }
}
```

---

## 2. Lit Signals (`@lit-labs/signals`)

Signals provide fine-grained reactivity — only the exact template expressions that read a signal re-render, not the entire component.

```typescript
import { LitElement, html } from 'lit';
import { customElement } from 'lit/decorators.js';
import { SignalWatcher } from '@lit-labs/signals';
import { signal, computed } from 'signal-polyfill';

// Global signals
const count = signal(0);
const doubled = computed(() => count.get() * 2);

@customElement('signal-counter')
export class SignalCounter extends SignalWatcher(LitElement) {
  render() {
    return html`
      <p>Count: ${count.get()}</p>
      <p>Doubled: ${doubled.get()}</p>
      <button @click=${() => count.set(count.get() + 1)}>Increment</button>
    `;
  }
}
```

### Signal Store

```typescript
// stores/cart.signals.ts
import { signal, computed } from 'signal-polyfill';

export interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

const _items = signal<CartItem[]>([]);

export const cartStore = {
  items: _items,
  total: computed(() =>
    _items.get().reduce((sum, item) => sum + item.price * item.quantity, 0)
  ),
  count: computed(() =>
    _items.get().reduce((sum, item) => sum + item.quantity, 0)
  ),

  addItem(item: Omit<CartItem, 'quantity'>) {
    const existing = _items.get().find(i => i.id === item.id);
    if (existing) {
      _items.set(_items.get().map(i =>
        i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i
      ));
    } else {
      _items.set([..._items.get(), { ...item, quantity: 1 }]);
    }
  },

  removeItem(id: string) {
    _items.set(_items.get().filter(i => i.id !== id));
  },

  clear() {
    _items.set([]);
  },
};
```

---

## 3. Event Bus Pattern (Pub/Sub)

For decoupled communication between unrelated components:

```typescript
// event-bus.ts
type EventCallback = (detail: any) => void;

class EventBus {
  private _listeners = new Map<string, Set<EventCallback>>();

  on(event: string, callback: EventCallback) {
    if (!this._listeners.has(event)) {
      this._listeners.set(event, new Set());
    }
    this._listeners.get(event)!.add(callback);
    // Return unsubscribe function
    return () => this._listeners.get(event)?.delete(callback);
  }

  emit(event: string, detail?: any) {
    this._listeners.get(event)?.forEach(cb => cb(detail));
  }
}

export const eventBus = new EventBus();
```

### Event Bus Controller

```typescript
export class EventBusController implements ReactiveController {
  host: ReactiveControllerHost;
  private _unsubscribers: (() => void)[] = [];

  constructor(host: ReactiveControllerHost) {
    (this.host = host).addController(this);
  }

  on(event: string, callback: (detail: any) => void) {
    this._unsubscribers.push(eventBus.on(event, (detail) => {
      callback(detail);
      this.host.requestUpdate();
    }));
  }

  emit(event: string, detail?: any) {
    eventBus.emit(event, detail);
  }

  hostDisconnected() {
    this._unsubscribers.forEach(unsub => unsub());
    this._unsubscribers = [];
  }
}
```

---

## 4. State Decision Tree

```text
Component-local UI state?      → @state() private _isOpen = false;
Parent-child data passing?     → @property() + events
Cross-tree configuration?      → @lit/context
Shared global state?           → Reactive Store + StoreController
Fine-grained reactivity?       → Lit Signals
Decoupled component events?    → Event Bus
Server state (API data)?       → @lit/task
```

---

## 5. Rules

- ✅ **ALWAYS** use `@state()` for component-local UI state.
- ✅ Use the reactive store pattern for shared state across multiple components.
- ✅ Clean up all subscriptions in `hostDisconnected()`.
- ❌ **NEVER** use global mutable variables without a reactive update mechanism.
- ❌ **NEVER** put API fetching logic in stores — use `@lit/task` for that.
- ❌ **NEVER** over-engineer: if only parent-child communication is needed, use properties + events.

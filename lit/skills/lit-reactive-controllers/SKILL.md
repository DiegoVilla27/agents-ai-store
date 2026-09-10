---
name: lit-reactive-controllers
description: The definitive standard for building reusable, composable reactive controllers in Lit for shared logic without class inheritance chains.
author: Diego Villanueva
trigger: When creating reactive controllers, sharing logic between Lit components, implementing composition over inheritance, or building reusable behavior like intersection observers or media queries.
---

# Reactive Controllers Mastery

You are an expert in Lit's composition model. Reactive controllers are the Lit equivalent of React hooks — they encapsulate reusable reactive logic that plugs into a component's lifecycle without class inheritance. **Composition over inheritance** is the law.

---

## 1. The Controller Pattern

A reactive controller is a plain class that implements the `ReactiveController` interface and registers itself with a `ReactiveControllerHost` (a LitElement).

```typescript
import { ReactiveController, ReactiveControllerHost } from 'lit';

export class ClockController implements ReactiveController {
  host: ReactiveControllerHost;
  value = new Date();
  private _timer?: ReturnType<typeof setInterval>;

  constructor(host: ReactiveControllerHost, private _interval = 1000) {
    (this.host = host).addController(this);
  }

  hostConnected() {
    this._timer = setInterval(() => {
      this.value = new Date();
      this.host.requestUpdate();  // Trigger re-render
    }, this._interval);
  }

  hostDisconnected() {
    clearInterval(this._timer);
  }
}
```

### Using in a Component

```typescript
import { LitElement, html } from 'lit';
import { customElement } from 'lit/decorators.js';
import { ClockController } from '../controllers/clock.controller.js';

@customElement('live-clock')
export class LiveClock extends LitElement {
  private _clock = new ClockController(this);

  render() {
    return html`<time>${this._clock.value.toLocaleTimeString()}</time>`;
  }
}
```

---

## 2. Lifecycle Hooks

Controllers can hook into every stage of their host's lifecycle:

| Hook | When |
|------|------|
| `hostConnected()` | Host is added to the DOM (`connectedCallback`) |
| `hostDisconnected()` | Host is removed from the DOM (`disconnectedCallback`) |
| `hostUpdate()` | Before host's `update()` and `render()` |
| `hostUpdated()` | After host's `update()` and `render()` |

```typescript
export class LogController implements ReactiveController {
  host: ReactiveControllerHost;

  constructor(host: ReactiveControllerHost) {
    (this.host = host).addController(this);
  }

  hostConnected()    { console.log('🟢 Connected'); }
  hostDisconnected() { console.log('🔴 Disconnected'); }
  hostUpdate()       { console.log('🔄 About to update'); }
  hostUpdated()      { console.log('✅ Updated'); }
}
```

---

## 3. Production Controller Library

### A. Intersection Observer Controller

```typescript
export class IntersectionController implements ReactiveController {
  host: ReactiveControllerHost & Element;
  isIntersecting = false;
  private _observer?: IntersectionObserver;

  constructor(
    host: ReactiveControllerHost & Element,
    private _options: IntersectionObserverInit = { threshold: 0.1 }
  ) {
    (this.host = host).addController(this);
  }

  hostConnected() {
    this._observer = new IntersectionObserver(([entry]) => {
      this.isIntersecting = entry.isIntersecting;
      this.host.requestUpdate();
    }, this._options);
    this._observer.observe(this.host);
  }

  hostDisconnected() {
    this._observer?.disconnect();
  }
}

// Usage
@customElement('lazy-section')
export class LazySection extends LitElement {
  private _visible = new IntersectionController(this, { threshold: 0.2 });

  render() {
    return html`
      <div class=${this._visible.isIntersecting ? 'visible' : 'hidden'}>
        ${this._visible.isIntersecting ? html`<slot></slot>` : html`<div class="skeleton"></div>`}
      </div>
    `;
  }
}
```

### B. Media Query Controller

```typescript
export class MediaQueryController implements ReactiveController {
  host: ReactiveControllerHost;
  matches = false;
  private _mql?: MediaQueryList;
  private _handler = (e: MediaQueryListEvent) => {
    this.matches = e.matches;
    this.host.requestUpdate();
  };

  constructor(host: ReactiveControllerHost, private _query: string) {
    (this.host = host).addController(this);
  }

  hostConnected() {
    this._mql = window.matchMedia(this._query);
    this.matches = this._mql.matches;
    this._mql.addEventListener('change', this._handler);
  }

  hostDisconnected() {
    this._mql?.removeEventListener('change', this._handler);
  }
}

// Usage
@customElement('responsive-layout')
export class ResponsiveLayout extends LitElement {
  private _desktop = new MediaQueryController(this, '(min-width: 1024px)');
  private _prefersark = new MediaQueryController(this, '(prefers-color-scheme: dark)');

  render() {
    return html`
      <div class=${this._desktop.matches ? 'grid-cols-3' : 'grid-cols-1'}>
        <slot></slot>
      </div>
    `;
  }
}
```

### C. Fetch Controller

```typescript
export class FetchController<T> implements ReactiveController {
  host: ReactiveControllerHost;
  data: T | null = null;
  loading = false;
  error: Error | null = null;
  private _abortController?: AbortController;

  constructor(host: ReactiveControllerHost) {
    (this.host = host).addController(this);
  }

  async fetch(url: string, options?: RequestInit) {
    this._abortController?.abort();
    this._abortController = new AbortController();

    this.loading = true;
    this.error = null;
    this.host.requestUpdate();

    try {
      const response = await fetch(url, {
        ...options,
        signal: this._abortController.signal,
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      this.data = await response.json();
    } catch (err) {
      if ((err as Error).name !== 'AbortError') {
        this.error = err as Error;
      }
    } finally {
      this.loading = false;
      this.host.requestUpdate();
    }
  }

  hostDisconnected() {
    this._abortController?.abort();
  }
}
```

### D. Mouse Position Controller

```typescript
export class MouseController implements ReactiveController {
  host: ReactiveControllerHost;
  x = 0;
  y = 0;
  private _target: EventTarget;
  private _handler = (e: Event) => {
    const { clientX, clientY } = e as MouseEvent;
    this.x = clientX;
    this.y = clientY;
    this.host.requestUpdate();
  };

  constructor(host: ReactiveControllerHost, target: EventTarget = window) {
    (this.host = host).addController(this);
    this._target = target;
  }

  hostConnected() {
    this._target.addEventListener('mousemove', this._handler);
  }

  hostDisconnected() {
    this._target.removeEventListener('mousemove', this._handler);
  }
}
```

---

## 4. Multiple Controllers Per Component

A single component can use unlimited controllers — this is the power of composition:

```typescript
@customElement('smart-dashboard')
export class SmartDashboard extends LitElement {
  private _clock = new ClockController(this);
  private _viewport = new MediaQueryController(this, '(min-width: 1024px)');
  private _visible = new IntersectionController(this);
  private _users = new FetchController<User[]>(this);

  connectedCallback() {
    super.connectedCallback();
    this._users.fetch('/api/users');
  }

  render() {
    return html`
      <header>
        <time>${this._clock.value.toLocaleTimeString()}</time>
        <span>${this._viewport.matches ? 'Desktop' : 'Mobile'}</span>
      </header>
      <main>
        ${this._users.loading ? html`<app-spinner></app-spinner>` : nothing}
        ${this._users.data?.map(u => html`<user-card .user=${u}></user-card>`)}
        ${this._users.error ? html`<p class="error">${this._users.error.message}</p>` : nothing}
      </main>
    `;
  }
}
```

---

## 5. Rules & Best Practices

- ✅ **ALWAYS** call `this.host.requestUpdate()` after mutating controller state — Lit won't know about changes otherwise.
- ✅ **ALWAYS** clean up in `hostDisconnected()` — listeners, timers, observers, AbortControllers.
- ✅ Use controllers instead of class inheritance chains (`extends BaseComponent extends FeatureMixin`).
- ❌ **NEVER** access the host's private properties — controllers interact via the public `ReactiveControllerHost` interface.
- ❌ **NEVER** forget to pass `this` to the controller constructor.

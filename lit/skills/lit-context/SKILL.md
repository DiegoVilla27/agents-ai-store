---
name: lit-context
description: The definitive standard for dependency injection and cross-component data sharing using @lit/context providers and consumers.
author: Diego Villanueva
trigger: When sharing data across Lit components without prop drilling, implementing dependency injection, using @lit/context providers and consumers, or managing cross-tree state.
---

# Lit Context Mastery (@lit/context)

Context provides a way to share data across a component tree without manually passing properties through every level. It implements the W3C Community Context Protocol, making it interoperable with other Web Component libraries.

---

## 1. Creating a Context

```typescript
import { createContext } from '@lit/context';

// Define typed context keys
export const themeContext = createContext<'light' | 'dark'>('theme');
export const userContext = createContext<User | null>('user');
export const localeContext = createContext<string>('locale');

// Type definition
export interface User {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'user';
}
```

---

## 2. Providing Context

### A. Decorator API (`@provide`)

```typescript
import { LitElement, html } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import { provide } from '@lit/context';
import { themeContext, userContext } from './contexts.js';

@customElement('app-shell')
export class AppShell extends LitElement {
  // Provide theme to all descendants
  @provide({ context: themeContext })
  @property()
  theme: 'light' | 'dark' = 'light';

  // Provide user to all descendants
  @provide({ context: userContext })
  @property({ attribute: false })
  currentUser: User | null = null;

  render() {
    return html`
      <app-header></app-header>
      <app-main></app-main>
      <app-footer></app-footer>
    `;
  }

  toggleTheme() {
    this.theme = this.theme === 'light' ? 'dark' : 'light';
    // All consumers automatically re-render!
  }
}
```

### B. Imperative API (`ContextProvider`)

```typescript
import { ContextProvider } from '@lit/context';
import { authContext, type AuthState } from './contexts.js';

@customElement('auth-provider')
export class AuthProvider extends LitElement {
  private _authProvider = new ContextProvider(this, {
    context: authContext,
    initialValue: { user: null, token: null, isAuthenticated: false },
  });

  login(user: User, token: string) {
    this._authProvider.setValue({
      user,
      token,
      isAuthenticated: true,
    });
  }

  logout() {
    this._authProvider.setValue({
      user: null,
      token: null,
      isAuthenticated: false,
    });
  }

  render() {
    return html`<slot></slot>`;
  }
}
```

---

## 3. Consuming Context

### A. Decorator API (`@consume`)

```typescript
import { LitElement, html, css, nothing } from 'lit';
import { customElement } from 'lit/decorators.js';
import { consume } from '@lit/context';
import { themeContext, userContext } from './contexts.js';

@customElement('user-avatar')
export class UserAvatar extends LitElement {
  // Automatically receives value from nearest provider
  @consume({ context: userContext, subscribe: true })
  user?: User | null;

  @consume({ context: themeContext, subscribe: true })
  theme?: 'light' | 'dark';

  render() {
    if (!this.user) return nothing;

    return html`
      <div class="avatar ${this.theme}">
        <img src=${this.user.avatar} alt=${this.user.name}>
        <span>${this.user.name}</span>
      </div>
    `;
  }
}
```

### B. Imperative API (`ContextConsumer`)

```typescript
import { ContextConsumer } from '@lit/context';
import { userContext } from './contexts.js';

@customElement('user-greeting')
export class UserGreeting extends LitElement {
  private _userConsumer = new ContextConsumer(this, {
    context: userContext,
    subscribe: true,
    callback: (user) => {
      console.log('User changed:', user);
    },
  });

  render() {
    const user = this._userConsumer.value;
    return html`<h2>Welcome, ${user?.name ?? 'Guest'}</h2>`;
  }
}
```

---

## 4. `subscribe: true` — Reactive Updates

| Setting | Behavior |
|---------|----------|
| `subscribe: false` (default) | Gets context value **once** on connection |
| `subscribe: true` | Reactively updates whenever the provider's value changes |

```typescript
// ❌ Won't update when theme changes
@consume({ context: themeContext })
theme?: string;

// ✅ Reactively updates when theme changes
@consume({ context: themeContext, subscribe: true })
theme?: string;
```

- ✅ **ALWAYS** use `subscribe: true` for values that change at runtime (theme, auth, locale).
- Use `subscribe: false` only for static configuration that never changes after setup.

---

## 5. Nested Providers (Overriding)

Closer providers override farther ones — like CSS cascade:

```html
<app-shell>                     <!-- provides theme = 'light' -->
  <main-content>                <!-- inherits theme = 'light' -->
    <dark-section>              <!-- provides theme = 'dark' (overrides!) -->
      <user-card></user-card>   <!-- receives theme = 'dark' -->
    </dark-section>
  </main-content>
</app-shell>
```

```typescript
@customElement('dark-section')
export class DarkSection extends LitElement {
  @provide({ context: themeContext })
  theme: 'light' | 'dark' = 'dark';  // Overrides parent provider

  render() {
    return html`<slot></slot>`;
  }
}
```

---

## 6. Production Pattern: Service Locator

Use context to inject services without tight coupling:

```typescript
// contexts/service-contexts.ts
export const apiServiceContext = createContext<ApiService>('api-service');
export const loggerContext = createContext<LoggerService>('logger');
export const analyticsContext = createContext<AnalyticsService>('analytics');

// app-root.ts — Provide at the root
@customElement('app-root')
export class AppRoot extends LitElement {
  @provide({ context: apiServiceContext })
  apiService = new ApiService('/api/v1');

  @provide({ context: loggerContext })
  logger = new LoggerService('production');

  @provide({ context: analyticsContext })
  analytics = new AnalyticsService('GA-XXXX');

  render() {
    return html`<app-router></app-router>`;
  }
}

// Any deep component — Consume anywhere
@customElement('product-list')
export class ProductList extends LitElement {
  @consume({ context: apiServiceContext })
  private _api!: ApiService;

  async connectedCallback() {
    super.connectedCallback();
    this.products = await this._api.get('/products');
  }
}
```

---

## 7. Rules

- ✅ **ALWAYS** use `subscribe: true` for dynamic values.
- ✅ Define context keys in a shared `contexts.ts` file — single source of truth.
- ✅ Type your contexts with generics for full TypeScript safety.
- ❌ **NEVER** provide context inside `render()` — it creates infinite loops.
- ❌ **NEVER** use context as a replacement for direct property bindings between parent-child. Context is for **cross-tree** data, not adjacent components.

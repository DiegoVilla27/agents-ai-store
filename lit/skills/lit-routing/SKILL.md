---
name: lit-routing
description: The definitive standard for SPA routing patterns in Lit applications using @lit-labs/router and custom routing solutions.
author: Diego Villanueva
trigger: When implementing SPA routing in Lit, using @lit-labs/router, creating custom routers, handling route parameters, or implementing lazy-loaded routes.
---

# Lit Routing Mastery

Lit is library-agnostic regarding routing. This skill covers `@lit-labs/router` for official patterns and custom History API routing for maximum control.

---

## 1. @lit-labs/router

```typescript
import { LitElement, html } from 'lit';
import { customElement } from 'lit/decorators.js';
import { Router } from '@lit-labs/router';

@customElement('app-router')
export class AppRouter extends LitElement {
  private _router = new Router(this, [
    {
      path: '/',
      render: () => html`<home-page></home-page>`,
    },
    {
      path: '/users',
      render: () => html`<users-page></users-page>`,
    },
    {
      path: '/users/:id',
      render: ({ id }) => html`<user-detail .userId=${id}></user-detail>`,
    },
    {
      path: '/settings/*',
      render: () => html`<settings-page></settings-page>`,
    },
    {
      // Lazy-loaded route
      path: '/admin',
      enter: async () => {
        await import('./pages/admin-page.js');
        return true;
      },
      render: () => html`<admin-page></admin-page>`,
    },
  ]);

  render() {
    return html`
      <app-header></app-header>
      <main>${this._router.outlet()}</main>
      <app-footer></app-footer>
    `;
  }
}
```

---

## 2. Route Guards (`enter`)

```typescript
{
  path: '/admin',
  enter: async () => {
    const auth = await checkAuthentication();
    if (!auth.isAdmin) {
      // Redirect to login
      window.history.pushState({}, '', '/login');
      return false;  // Prevent route from rendering
    }
    return true;
  },
  render: () => html`<admin-page></admin-page>`,
}
```

---

## 3. Navigation Links

```typescript
import { Router } from '@lit-labs/router';

render() {
  return html`
    <nav>
      <a href="/" @click=${this._navigate}>Home</a>
      <a href="/users" @click=${this._navigate}>Users</a>
      <a href="/settings" @click=${this._navigate}>Settings</a>
    </nav>
  `;
}

private _navigate(e: Event) {
  e.preventDefault();
  const href = (e.target as HTMLAnchorElement).href;
  Router.go(href);
}
```

Or create a reusable nav link component:

```typescript
@customElement('nav-link')
export class NavLink extends LitElement {
  @property() href = '';

  render() {
    return html`
      <a href=${this.href} @click=${this._onClick}>
        <slot></slot>
      </a>
    `;
  }

  private _onClick(e: Event) {
    e.preventDefault();
    Router.go(this.href);
  }
}
```

---

## 4. Custom Hash Router (Lightweight Alternative)

For simpler applications or when you don't want a dependency:

```typescript
import { LitElement, html, nothing } from 'lit';
import { customElement, state } from 'lit/decorators.js';

interface Route {
  path: string;
  component: () => ReturnType<typeof html>;
  guard?: () => boolean | Promise<boolean>;
}

@customElement('hash-router')
export class HashRouter extends LitElement {
  private _routes: Route[] = [
    { path: '/',         component: () => html`<home-page></home-page>` },
    { path: '/about',    component: () => html`<about-page></about-page>` },
    { path: '/contact',  component: () => html`<contact-page></contact-page>` },
  ];

  @state() private _currentPath = window.location.hash.slice(1) || '/';

  connectedCallback() {
    super.connectedCallback();
    window.addEventListener('hashchange', this._onHashChange);
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    window.removeEventListener('hashchange', this._onHashChange);
  }

  private _onHashChange = () => {
    this._currentPath = window.location.hash.slice(1) || '/';
  };

  render() {
    const route = this._routes.find(r => r.path === this._currentPath);
    return route ? route.component() : html`<not-found-page></not-found-page>`;
  }

  static navigate(path: string) {
    window.location.hash = path;
  }
}
```

---

## 5. Custom History Router

```typescript
@customElement('history-router')
export class HistoryRouter extends LitElement {
  @state() private _path = window.location.pathname;

  private _routes: Map<string | RegExp, (params?: Record<string, string>) => ReturnType<typeof html>> = new Map([
    ['/', () => html`<home-page></home-page>`],
    ['/users', () => html`<users-page></users-page>`],
    [/^\/users\/(.+)$/, (params) => html`<user-detail .userId=${params?.id}></user-detail>`],
  ]);

  connectedCallback() {
    super.connectedCallback();
    window.addEventListener('popstate', this._onPopState);
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    window.removeEventListener('popstate', this._onPopState);
  }

  private _onPopState = () => {
    this._path = window.location.pathname;
  };

  static go(path: string) {
    window.history.pushState({}, '', path);
    window.dispatchEvent(new PopStateEvent('popstate'));
  }

  render() {
    for (const [pattern, renderer] of this._routes) {
      if (typeof pattern === 'string' && pattern === this._path) {
        return renderer();
      }
      if (pattern instanceof RegExp) {
        const match = this._path.match(pattern);
        if (match) return renderer({ id: match[1] });
      }
    }
    return html`<not-found-page></not-found-page>`;
  }
}
```

---

## 6. Rules

- ✅ **ALWAYS** use `e.preventDefault()` on `<a>` clicks to prevent full page reloads.
- ✅ **ALWAYS** lazy-load heavy route components via dynamic `import()`.
- ✅ Use route guards for authentication/authorization checks.
- ❌ **NEVER** put routing logic inside individual page components — centralize it.
- ❌ **NEVER** use `window.location.href = ...` for SPA navigation — it triggers a full reload.

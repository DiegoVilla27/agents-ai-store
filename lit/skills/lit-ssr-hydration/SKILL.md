---
name: lit-ssr-hydration
description: The definitive standard for server-side rendering Lit components using @lit-labs/ssr, Declarative Shadow DOM, hydration, and streaming patterns.
author: Diego Villanueva
trigger: When implementing SSR for Lit components, using @lit-labs/ssr, Declarative Shadow DOM, hydration, or building isomorphic web components.
---

# Lit SSR & Hydration Mastery

Server-side rendering Lit components enables faster First Contentful Paint (FCP), SEO indexability, and progressive enhancement. `@lit-labs/ssr` renders Lit templates to HTML strings with Declarative Shadow DOM (DSD), then hydrates them on the client.

---

## 1. How Lit SSR Works

```text
Server                              Client
──────                              ──────
1. Render LitElement to HTML    →   3. Browser parses HTML + DSD
   (including Declarative            4. Lit hydrates: attaches
    Shadow DOM <template>)              event listeners & reactivity
2. Stream/send HTML to client   →   5. Component is interactive
```

---

## 2. Server Setup

```typescript
// server.ts
import { render } from '@lit-labs/ssr';
import { html } from 'lit';
import { collectResult } from '@lit-labs/ssr/lib/render-result.js';

// Import your components (server-side registration)
import './components/app-shell.js';
import './components/user-card.js';

async function renderPage(userId: string): Promise<string> {
  const user = await fetchUser(userId);

  const ssrResult = render(html`
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>${user.name} - Profile</title>
      </head>
      <body>
        <app-shell>
          <user-card .user=${user}></user-card>
        </app-shell>

        <!-- Hydration script -->
        <script type="module" src="/client.js"></script>
      </body>
    </html>
  `);

  return collectResult(ssrResult);
}
```

### Express Integration

```typescript
import express from 'express';
import { render } from '@lit-labs/ssr';
import { collectResultSync } from '@lit-labs/ssr/lib/render-result.js';
import { RenderResultReadable } from '@lit-labs/ssr/lib/render-result-readable.js';

const app = express();

// Streaming response (better TTFB)
app.get('/user/:id', async (req, res) => {
  const ssrResult = render(html`
    <app-shell>
      <user-profile userId=${req.params.id}></user-profile>
    </app-shell>
  `);

  const readable = new RenderResultReadable(ssrResult);
  res.type('html');
  readable.pipe(res);
});
```

---

## 3. Declarative Shadow DOM (DSD)

`@lit-labs/ssr` outputs Declarative Shadow DOM using `<template shadowrootmode="open">`:

```html
<!-- Server-rendered output -->
<my-card>
  <template shadowrootmode="open">
    <style>
      :host { display: block; }
      h2 { color: var(--color-text); }
    </style>
    <h2>John Doe</h2>
    <p><slot></slot></p>
  </template>
  <!-- Light DOM / slotted content -->
  <span>Software Engineer</span>
</my-card>
```

The browser natively parses `<template shadowrootmode="open">` into a Shadow DOM — no JavaScript needed for initial render.

---

## 4. Client Hydration

```typescript
// client.ts
import '@lit-labs/ssr-client/lit-element-hydrate-support.js';

// Import all components that were SSR'd
import './components/app-shell.js';
import './components/user-card.js';
import './components/user-profile.js';

// Lit automatically hydrates: finds the SSR-rendered DOM and attaches
// event listeners + reactive properties without re-rendering
```

### Hydration Behavior
- ✅ Lit detects the existing DSD and **skips initial rendering** — it reuses the server-rendered DOM.
- ✅ Event listeners and reactive properties are attached during hydration.
- ✅ If server and client state match, zero DOM changes occur.

---

## 5. SSR-Safe Code Patterns

### A. `isServer` Check

```typescript
import { LitElement, html } from 'lit';
import { isServer } from 'lit';

@customElement('my-component')
export class MyComponent extends LitElement {
  render() {
    return html`
      <div>
        ${isServer
          ? html`<p>Server-rendered placeholder</p>`
          : html`<interactive-widget></interactive-widget>`
        }
      </div>
    `;
  }

  connectedCallback() {
    super.connectedCallback();
    if (!isServer) {
      // Safe to access browser APIs here
      this._observer = new IntersectionObserver(/* ... */);
    }
  }
}
```

### B. Avoiding Browser-Only APIs

```typescript
// ❌ CRASHES on server
@customElement('bad-component')
export class BadComponent extends LitElement {
  connectedCallback() {
    super.connectedCallback();
    window.addEventListener('resize', this._onResize);  // ❌ No window on server!
    const rect = this.getBoundingClientRect();           // ❌ No DOM on server!
    localStorage.setItem('key', 'value');                // ❌ No localStorage!
  }
}

// ✅ SSR-safe
@customElement('safe-component')
export class SafeComponent extends LitElement {
  connectedCallback() {
    super.connectedCallback();
    if (!isServer) {
      window.addEventListener('resize', this._onResize);
    }
  }
}
```

### C. SSR-Safe Reactive Controllers

```typescript
export class ResizeController implements ReactiveController {
  host: ReactiveControllerHost;
  width = 0;

  constructor(host: ReactiveControllerHost) {
    (this.host = host).addController(this);
  }

  hostConnected() {
    // Only attach browser APIs on the client
    if (typeof window !== 'undefined') {
      this.width = window.innerWidth;
      window.addEventListener('resize', this._onResize);
    }
  }

  hostDisconnected() {
    if (typeof window !== 'undefined') {
      window.removeEventListener('resize', this._onResize);
    }
  }

  private _onResize = () => {
    this.width = window.innerWidth;
    this.host.requestUpdate();
  };
}
```

---

## 6. Streaming SSR

For optimal Time to First Byte (TTFB):

```typescript
import { render } from '@lit-labs/ssr';
import { RenderResultReadable } from '@lit-labs/ssr/lib/render-result-readable.js';

// The render result is an iterable that can be streamed
app.get('/', (req, res) => {
  const result = render(html`
    <app-shell>
      <hero-section></hero-section>
      <product-grid></product-grid>
    </app-shell>
  `);

  res.type('html');
  const stream = new RenderResultReadable(result);
  stream.pipe(res);
  // HTML is sent in chunks as it's rendered — browser starts parsing immediately
});
```

---

## 7. Rules

- ✅ **ALWAYS** import `@lit-labs/ssr-client/lit-element-hydrate-support.js` **before** component imports on the client.
- ✅ Guard all browser APIs (`window`, `document`, `localStorage`) with `isServer` checks.
- ✅ Use streaming (`RenderResultReadable`) for optimal TTFB.
- ✅ Ensure server and client render the same initial state to avoid hydration mismatches.
- ❌ **NEVER** access `window`, `document`, or DOM APIs during server rendering.
- ❌ **NEVER** use `isServer` to render completely different content — it causes hydration mismatches.

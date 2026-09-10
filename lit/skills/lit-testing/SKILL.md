---
name: lit-testing
description: The definitive standard for testing Lit components using @open-wc/testing, @web/test-runner, Shadow DOM queries, event testing, and async update handling.
author: Diego Villanueva
trigger: When testing Lit components, using @open-wc/testing fixtures, querying Shadow DOM, testing events, handling async updates, or configuring @web/test-runner.
---

# Lit Testing Mastery

Testing Web Components requires specific patterns for Shadow DOM queries, async reactive updates, and slot testing. This skill covers `@open-wc/testing` (the standard) and `@web/test-runner`.

---

## 1. Setup

```bash
npm install -D @open-wc/testing @web/test-runner @web/dev-server-esbuild
```

### `web-test-runner.config.mjs`

```javascript
import { esbuildPlugin } from '@web/dev-server-esbuild';

export default {
  files: 'src/**/*.test.ts',
  nodeResolve: true,
  plugins: [
    esbuildPlugin({ ts: true, target: 'auto' }),
  ],
  coverageConfig: {
    report: true,
    reportDir: 'coverage',
    threshold: { statements: 80, branches: 80, functions: 80, lines: 80 },
  },
};
```

### `package.json`

```json
{
  "scripts": {
    "test": "web-test-runner",
    "test:watch": "web-test-runner --watch",
    "test:coverage": "web-test-runner --coverage"
  }
}
```

---

## 2. Basic Component Test

```typescript
import { fixture, html, expect, elementUpdated } from '@open-wc/testing';
import '../components/my-counter.js';
import type { MyCounter } from '../components/my-counter.js';

describe('my-counter', () => {
  it('renders with default count of 0', async () => {
    const el = await fixture<MyCounter>(html`<my-counter></my-counter>`);

    const countDisplay = el.shadowRoot!.querySelector('.count');
    expect(countDisplay?.textContent).to.equal('0');
  });

  it('renders with provided count', async () => {
    const el = await fixture<MyCounter>(html`<my-counter count="5"></my-counter>`);

    expect(el.count).to.equal(5);
    const countDisplay = el.shadowRoot!.querySelector('.count');
    expect(countDisplay?.textContent).to.equal('5');
  });

  it('increments count on button click', async () => {
    const el = await fixture<MyCounter>(html`<my-counter></my-counter>`);

    const button = el.shadowRoot!.querySelector('button')!;
    button.click();
    await elementUpdated(el);  // Wait for Lit to re-render

    expect(el.count).to.equal(1);
    const countDisplay = el.shadowRoot!.querySelector('.count');
    expect(countDisplay?.textContent).to.equal('1');
  });
});
```

---

## 3. `elementUpdated` — Waiting for Reactive Updates

After modifying a property or triggering an event, you MUST wait for Lit's reactive update:

```typescript
it('updates display when property changes', async () => {
  const el = await fixture<MyCard>(html`<my-card heading="Hello"></my-card>`);

  el.heading = 'Updated';
  await elementUpdated(el);  // ✅ CRITICAL: Wait for Lit to re-render

  const h2 = el.shadowRoot!.querySelector('h2');
  expect(h2?.textContent).to.equal('Updated');
});
```

- ✅ **ALWAYS** use `await elementUpdated(el)` after setting properties or triggering interactions.

---

## 4. Testing Events

```typescript
it('dispatches item-selected event on click', async () => {
  const el = await fixture<ItemList>(html`<item-list></item-list>`);
  el.items = [{ id: '1', name: 'Alpha' }];
  await elementUpdated(el);

  let eventDetail: any = null;

  el.addEventListener('item-selected', ((e: CustomEvent) => {
    eventDetail = e.detail;
  }) as EventListener);

  const item = el.shadowRoot!.querySelector('.item')!;
  item.click();

  expect(eventDetail).to.deep.equal({ item: { id: '1', name: 'Alpha' } });
});

// Using oneEvent helper
import { oneEvent } from '@open-wc/testing';

it('dispatches dialog-closed event', async () => {
  const el = await fixture(html`<app-dialog open></app-dialog>`);

  setTimeout(() => {
    el.shadowRoot!.querySelector('.close-btn')!.dispatchEvent(new Event('click'));
  });

  const event = await oneEvent(el, 'dialog-closed');
  expect(event).to.exist;
});
```

---

## 5. Testing Slots

```typescript
it('renders slotted content', async () => {
  const el = await fixture(html`
    <my-card>
      <h3 slot="title">Card Title</h3>
      <p>Card body content</p>
    </my-card>
  `);

  // Check slotted elements
  const titleSlot = el.shadowRoot!.querySelector('slot[name="title"]') as HTMLSlotElement;
  const defaultSlot = el.shadowRoot!.querySelector('slot:not([name])') as HTMLSlotElement;

  expect(titleSlot.assignedElements()).to.have.lengthOf(1);
  expect(defaultSlot.assignedElements()).to.have.lengthOf(1);
  expect(titleSlot.assignedElements()[0].textContent).to.equal('Card Title');
});
```

---

## 6. Testing Accessibility

```typescript
import { fixture, html, expect } from '@open-wc/testing';

it('passes accessibility audit', async () => {
  const el = await fixture(html`<fancy-button>Click me</fancy-button>`);

  // @open-wc/testing includes axe-core integration
  await expect(el).to.be.accessible();
});

it('has correct ARIA attributes', async () => {
  const el = await fixture(html`<fancy-input label="Email" required></fancy-input>`);

  const input = el.shadowRoot!.querySelector('input')!;
  expect(input.getAttribute('aria-required')).to.equal('true');
});
```

---

## 7. Testing Async Operations (Tasks)

```typescript
it('shows loading state during fetch', async () => {
  const el = await fixture<UserProfile>(html`<user-profile userId="1"></user-profile>`);

  // Check loading state
  const spinner = el.shadowRoot!.querySelector('app-spinner');
  expect(spinner).to.exist;

  // Wait for task to complete
  await el.updateComplete;
  // May need additional wait for the task
  await new Promise(r => setTimeout(r, 100));
  await elementUpdated(el);

  const name = el.shadowRoot!.querySelector('h2');
  expect(name).to.exist;
});
```

---

## 8. Snapshot Testing

```typescript
import { fixture, html, expect } from '@open-wc/testing';

it('matches snapshot', async () => {
  const el = await fixture(html`
    <my-card heading="Test Card">
      <p>Body content</p>
    </my-card>
  `);

  expect(el).shadowDom.to.equal(`
    <h2>Test Card</h2>
    <p><slot></slot></p>
  `);
});

// Ignoring attributes
it('matches DOM structure', async () => {
  const el = await fixture(html`<my-button></my-button>`);

  expect(el).shadowDom.to.equalSnapshot({ ignoreAttributes: ['id', 'class'] });
});
```

---

## 9. Mocking Services

```typescript
describe('product-list', () => {
  it('renders products from API', async () => {
    // Mock fetch
    const originalFetch = window.fetch;
    window.fetch = async () => new Response(
      JSON.stringify([{ id: '1', name: 'Widget', price: 9.99 }]),
      { status: 200 }
    );

    const el = await fixture<ProductList>(html`<product-list></product-list>`);
    await el.updateComplete;
    await new Promise(r => setTimeout(r, 50));
    await elementUpdated(el);

    const items = el.shadowRoot!.querySelectorAll('.product');
    expect(items).to.have.lengthOf(1);

    // Restore
    window.fetch = originalFetch;
  });
});
```

---

## 10. Rules

- ✅ **ALWAYS** `await elementUpdated(el)` after property changes or interactions.
- ✅ Query Shadow DOM via `el.shadowRoot!.querySelector()`.
- ✅ Test from the user's perspective — click buttons, check visible text.
- ✅ Run accessibility audits with `.to.be.accessible()`.
- ❌ **NEVER** test Lit internals (private properties, `requestUpdate` calls).
- ❌ **NEVER** skip `await` on `fixture()` or `elementUpdated()`.

---
name: react-testing-vitest
description: The ultimate architectural standard for Enterprise React Testing with Vitest, React Testing Library, Mock Service Worker (MSW), and user-event.
author: Diego Villanueva
trigger: When configuring Vitest for React, writing unit/integration tests with Testing Library, mocking API endpoints with MSW, or testing user interactions.
---

# Enterprise React Testing Architecture with Vitest

Modern enterprise React engineering replaces legacy Jest/Create-React-App test runners with **Vitest**. Vitest shares Vite's build pipeline, executes in-memory with near-instant startup times, supports native ESM, and integrates seamlessly with **React Testing Library (RTL)** and **Mock Service Worker (MSW)**.

---

## 1. Vitest Configuration (`vitest.config.ts`)

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: false,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      lines: 90,
      functions: 90,
      branches: 85,
    },
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach, beforeAll, afterAll } from 'vitest';
import { server } from './mocks/server';

// Start MSW server before tests
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => {
  cleanup();
  server.resetHandlers();
});
afterAll(() => server.close());
```

---

## 2. API Mocking with Mock Service Worker (MSW v2)

**❌ NEVER** mock raw `fetch()` or `axios` with brittle `vi.spyOn(global, 'fetch')`.
**✅ ALWAYS** intercept network traffic with **MSW (Mock Service Worker)** at the network level.

```typescript
// src/test/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      name: 'Diego Villanueva',
      email: 'diego@enterprise.com',
    });
  }),

  http.post('/api/checkout', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ orderId: 'ord-9988', status: 'SUCCESS' });
  }),
];
```

```typescript
// src/test/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
```

---

## 3. User-Centric Component Testing (`@testing-library/react` + `user-event`)

Test components from the user's perspective (accessible roles, visible text) rather than internal state variables.

```tsx
// src/features/auth/components/LoginForm.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { LoginForm } from './LoginForm';

describe('LoginForm Component', () => {
  it('should submit credentials and display welcome message', async () => {
    const user = userEvent.setup();
    const onSuccess = vi.fn();

    render(<LoginForm onSuccess={onSuccess} />);

    // 1. Query by Accessible Role
    const emailInput = screen.getByRole('textbox', { name: /email/i });
    const passwordInput = screen.getByLabelText(/password/i);
    const submitButton = screen.getByRole('button', { name: /sign in/i });

    // 2. Simulate User Gestures
    await user.type(emailInput, 'architect@enterprise.com');
    await user.type(passwordInput, 'SecureP@ss123');
    await user.click(submitButton);

    // 3. Assert Behavior
    expect(await screen.findByText(/welcome back/i)).toBeInTheDocument();
    expect(onSuccess).toHaveBeenCalledTimes(1);
  });

  it('should show validation error when email is empty', async () => {
    const user = userEvent.setup();
    render(<LoginForm onSuccess={vi.fn()} />);

    const submitButton = screen.getByRole('button', { name: /sign in/i });
    await user.click(submitButton);

    expect(await screen.findByText(/email is required/i)).toBeInTheDocument();
  });
});
```

---

## 4. Testing Custom Hooks

```typescript
// src/hooks/useCounter.test.ts
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useCounter } from './useCounter';

describe('useCounter hook', () => {
  it('should increment and decrement counter value', () => {
    const { result } = renderHook(() => useCounter(10));

    expect(result.current.count).toBe(10);

    act(() => {
      result.current.increment();
    });
    expect(result.current.count).toBe(11);

    act(() => {
      result.current.decrement();
    });
    expect(result.current.count).toBe(10);
  });
});
```

---

**Execution Protocol**
1. **Always use `userEvent.setup()`**: Do NOT use legacy `fireEvent`. `userEvent` simulates full browser interaction events (hover, focus, keypress).
2. **Prioritize `getByRole` & `findByRole` queries**: Mirrors screen reader and accessibility tree behavior.
3. **Use MSW for all HTTP mocks**: Guarantees tests run against realistic network payloads.
4. **Never test internal state or private functions**: Test inputs, DOM reactions, and output callbacks.

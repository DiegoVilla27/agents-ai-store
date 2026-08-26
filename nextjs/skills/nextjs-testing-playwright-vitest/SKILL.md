---
name: nextjs-testing-playwright-vitest
description: The ultimate architectural standard for Testing Next.js App Router applications with Playwright E2E, Authenticated Fixtures, Visual Testing, and Vitest for Server Components / Server Actions.
author: Diego Villanueva
trigger: When configuring testing in Next.js, writing Playwright E2E tests, testing Server Actions, testing React Server Components (RSC) with Vitest, or setting up auth fixtures.
---

# Enterprise Next.js Testing Architecture (Playwright & Vitest)

Testing modern Next.js App Router applications requires two distinct tiers: **Vitest** for lightning-fast unit tests of Server Actions, DTOs, and pure domain utilities, and **Playwright** for complete End-to-End (E2E) browser verification, authenticated session fixtures, and visual regression detection.

---

## 1. Unit & Server Action Testing with Vitest

```bash
npm install -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/jest-dom
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

### Testing a Server Action with Mocked Auth & Database:

```typescript
// src/features/billing/actions/upgrade-plan.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { upgradePlanAction } from './upgrade-plan';
import { db } from '@/lib/db';
import { getSession } from '@/lib/auth';

vi.mock('@/lib/db', () => ({
  db: {
    user: { update: vi.fn() },
  },
}));

vi.mock('@/lib/auth', () => ({
  getSession: vi.fn(),
}));

vi.mock('next/cache', () => ({
  revalidatePath: vi.fn(),
  revalidateTag: vi.fn(),
}));

describe('upgradePlanAction()', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('throws unauthorized if no session exists', async () => {
    vi.mocked(getSession).mockResolvedValue(null);
    const formData = new FormData();
    formData.append('planId', 'enterprise_pro');

    await expect(upgradePlanAction(formData)).rejects.toThrow('Unauthorized');
  });

  it('updates user plan in database on valid session', async () => {
    vi.mocked(getSession).mockResolvedValue({ user: { id: 'usr_123' } } as any);
    const formData = new FormData();
    formData.append('planId', 'enterprise_pro');

    await upgradePlanAction(formData);

    expect(db.user.update).toHaveBeenCalledWith({
      where: { id: 'usr_123' },
      data: { planId: 'enterprise_pro' },
    });
  });
});
```

---

## 2. Playwright E2E Setup with Authenticated Fixtures

```bash
npm install -D @playwright/test
```

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'Mobile Safari', use: { ...devices['iPhone 14'] } },
  ],
});
```

### Authenticated E2E Test Flow (`e2e/dashboard.spec.ts`):

```typescript
// e2e/dashboard.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Enterprise Dashboard', () => {
  test.beforeEach(async ({ page, context }) => {
    // Inject mock authenticated session cookie directly (Bypasses slow login form!)
    await context.addCookies([
      {
        name: 'session_token',
        value: 'mock_enterprise_jwt_token',
        domain: 'localhost',
        path: '/',
      },
    ]);
  });

  test('loads dashboard metrics and navigates to billing', async ({ page }) => {
    await page.goto('/dashboard');

    // Verify Server Component rendered header
    await expect(page.getByRole('heading', { name: /enterprise dashboard/i })).toBeVisible();

    // Verify Suspended Chart finished streaming
    await expect(page.getByTestId('billing-chart')).toBeVisible();

    // Click interactive button
    await page.getByRole('link', { name: /manage billing/i }).click();

    // Assert URL change
    await expect(page).toHaveURL('/dashboard/billing');
  });
});
```

---

**Execution Protocol**
1. **Never test Next.js Server Components with heavy mocks**: Use Playwright E2E against real rendered HTML.
2. **Use cookie injection for authenticated E2E tests**: Saves 10+ seconds per test run compared to manual form logins.
3. **Run tests on both Desktop and Mobile viewports**: Guarantees responsive UI integrity.

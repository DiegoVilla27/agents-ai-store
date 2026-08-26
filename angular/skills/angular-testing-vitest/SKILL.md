---
name: angular-testing-vitest
description: The ultimate architectural standard for Fast Angular Unit Testing with Vitest, Angular TestBed, Signal Testing, provideHttpClientTesting, and Component Harnesses.
author: Diego Villanueva
trigger: When configuring Vitest for Angular, writing unit tests for Signal components, mocking HttpClient, or testing modern Angular applications with high speed.
---

# Enterprise Angular Testing with Vitest

Karma and Jasmine are legacy. Modern enterprise Angular applications utilize **Vitest** for blazingly fast in-memory test execution (10x faster than Karma/Webpack), native ESM support, and first-class compatibility with Angular Standalone Components and Signals.

---

## 1. Vitest Configuration for Angular

```typescript
// vite.config.mts
import { defineConfig } from 'vite';
import angular from '@analogjs/vite-plugin-angular';

export default defineConfig({
  plugins: [angular()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['src/test-setup.ts'],
    include: ['src/**/*.spec.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      lines: 90,
      statements: 90,
      functions: 90,
      branches: 85,
    },
  },
});
```

```typescript
// src/test-setup.ts
import '@angular/compiler';
import { getTestBed } from '@angular/core/testing';
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting,
} from '@angular/platform-browser-dynamic/testing';

getTestBed().initTestEnvironment(
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting()
);
```

---

## 2. Testing Modern Signal Components

Testing Signal components is fully **synchronous**. Updating a signal value updates consumers without needing complex tick loops.

```typescript
// features/counter/components/counter.component.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, it, expect, beforeEach } from 'vitest';
import { By } from '@angular/platform-browser';
import { CounterComponent } from './counter.component';

describe('CounterComponent', () => {
  let component: CounterComponent;
  let fixture: ComponentFixture<CounterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CounterComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(CounterComponent);
    component = fixture.componentInstance;
  });

  it('should compute doubleCount signal correctly', () => {
    // Set input signal
    fixture.componentRef.setInput('initialCount', 5);
    fixture.detectChanges();

    expect(component.count()).toBe(5);
    expect(component.doubleCount()).toBe(10);

    // Increment signal
    component.increment();
    fixture.detectChanges();

    expect(component.count()).toBe(6);
    expect(component.doubleCount()).toBe(12);

    // Verify DOM output
    const textEl = fixture.debugElement.query(By.css('.count-display')).nativeElement;
    expect(textEl.textContent).toContain('Count: 6');
  });
});
```

---

## 3. Testing HTTP Services with `provideHttpClientTesting`

```typescript
// core/services/user.service.spec.ts
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { UserService } from './user.service';

describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        UserService,
        provideHttpClient(),
        provideHttpClientTesting(), // Modern functional HTTP testing provider
      ],
    });

    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify(); // Ensure no unmatched HTTP requests remain
  });

  it('should fetch user profile by ID', () => {
    const mockUser = { id: 'usr-1', name: 'Diego Villanueva' };

    service.getUser('usr-1').subscribe((user) => {
      expect(user).toEqual(mockUser);
    });

    const req = httpMock.expectOne('/api/users/usr-1');
    expect(req.request.method).toBe('GET');
    req.flush(mockUser);
  });
});
```

---

## 4. Vitest Mocking & Spying

```typescript
import { vi } from 'vitest';

it('should trigger auth notification on login', async () => {
  const authService = TestBed.inject(AuthService);
  const notifySpy = vi.spyOn(authService, 'notifyUser');

  await component.onLogin('user@enterprise.com', 'Pass123!');

  expect(notifySpy).toHaveBeenCalledWith('user@enterprise.com');
});
```

---

**Execution Protocol**
1. **Always use Vitest with `jsdom`**: Guarantees ultra-fast execution in CI/CD without browser process overhead.
2. **Use `fixture.componentRef.setInput()`**: For testing Signal inputs (`input()`, `input.required()`).
3. **Always call `httpMock.verify()` in `afterEach()`**: Prevents unasserted HTTP calls from silently passing.
4. **Prefer testing behavior over private implementation details**: Assert DOM state and public Signal values.

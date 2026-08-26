---
name: ionic-testing
description: The ultimate architectural standard for Testing Ionic Applications with Jasmine/Jest, Mocking Capacitor Plugins, Component DOM testing, and Playwright/Cypress E2E.
author: Diego Villanueva
trigger: When writing unit tests for Ionic components, mocking native Capacitor plugins, testing page lifecycle hooks, or writing mobile E2E tests.
---

# Enterprise Ionic Testing Architecture

Testing hybrid mobile applications requires mocking the native Capacitor bridge, handling Ionic's custom Web Component lifecycle, and validating touch-based interactions.

---

## 1. Mocking Capacitor Plugins in Unit Tests

Capacitor plugins fail in headless test runners (Karma/Jest) because the native Objective-C/Java bridge does not exist.

**❌ NEVER** test components with unmocked Capacitor native calls.
**✅ ALWAYS** isolate native calls behind injectable services and mock the service in `TestBed`.

```typescript
// features/profile/pages/profile.page.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { ProfilePage } from './profile.page';
import { CameraService } from '@core/plugins/camera.service';
import { SecureVaultService } from '@core/security/secure-vault.service';

describe('ProfilePage', () => {
  let component: ProfilePage;
  let fixture: ComponentFixture<ProfilePage>;
  let mockCameraService: jasmine.SpyObj<CameraService>;
  let mockVaultService: jasmine.SpyObj<SecureVaultService>;

  beforeEach(async () => {
    mockCameraService = jasmine.createSpyObj('CameraService', ['takePhoto']);
    mockVaultService = jasmine.createSpyObj('SecureVaultService', ['getSecret', 'setSecret']);

    await TestBed.configureTestingModule({
      imports: [ProfilePage],
      providers: [
        { provide: CameraService, useValue: mockCameraService },
        { provide: SecureVaultService, useValue: mockVaultService },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ProfilePage);
    component = fixture.componentInstance;
  });

  it('should take a photo and update avatar signal on button click', async () => {
    mockCameraService.takePhoto.and.resolveTo({
      webPath: 'blob:http://localhost/test-photo',
      format: 'jpeg',
      saved: false,
    } as any);

    await component.onUpdateAvatar();

    expect(mockCameraService.takePhoto).toHaveBeenCalledTimes(1);
    expect(component.avatarUrl()).toBe('blob:http://localhost/test-photo');
  });
});
```

---

## 2. Testing Ionic Lifecycle Hooks (`ionViewWillEnter`)

Standard Angular `ngOnInit` does not represent page re-visits in Ionic navigation stacks.

```typescript
it('should refresh user balance on ionViewWillEnter', () => {
  const refreshSpy = spyOn(component, 'loadAccountData');
  
  // Explicitly invoke Ionic lifecycle hook
  component.ionViewWillEnter();

  expect(refreshSpy).toHaveBeenCalled();
});
```

---

## 3. Testing Ionic Custom Form Components

Ionic inputs (`ion-input`, `ion-select`) use Shadow DOM. Querying standard `<input>` elements directly will fail without piercing the shadow root.

```typescript
import { By } from '@angular/platform-browser';

it('should bind email value to reactive form control', async () => {
  fixture.detectChanges();
  await fixture.whenStable();

  const ionInputEl = fixture.debugElement.query(By.css('ion-input[formControlName="email"]')).nativeElement;
  
  // Dispatch custom Ionic input event
  ionInputEl.value = 'architect@enterprise.com';
  ionInputEl.dispatchEvent(new CustomEvent('ionInput', { detail: { value: 'architect@enterprise.com' } }));
  fixture.detectChanges();

  expect(component.form.controls.email.value).toBe('architect@enterprise.com');
});
```

---

## 4. End-to-End (E2E) Testing with Playwright

Playwright is the industry standard for cross-browser and mobile-emulation E2E tests:

```typescript
// e2e/auth-flow.spec.ts
import { test, expect, devices } from '@playwright/test';

test.use({ ...devices['iPhone 14 Pro'] });

test.describe('Mobile Authentication Flow', () => {
  test('should login and navigate to tabs dashboard', async ({ page }) => {
    await page.goto('/login');

    // Fill Ionic inputs
    await page.locator('ion-input[formControlName="email"] input').fill('test@enterprise.com');
    await page.locator('ion-input[formControlName="password"] input').fill('SecurePassword123!');

    // Tap Ionic submit button
    await page.locator('ion-button[type="submit"]').click();

    // Verify stack navigation to tabs
    await expect(page).toHaveURL('/tabs/home');
    await expect(page.locator('ion-title')).toContainText('Home Dashboard');
  });
});
```

---

**Execution Protocol**
1. **Never test raw Capacitor plugins directly**: Wrap all plugins into `@Injectable()` services and mock them with `createSpyObj`.
2. **Always test `ionViewWillEnter`**: Ensure data reload triggers on page re-entry.
3. **Use mobile device viewports in E2E tests**: Emulate iPhone and Pixel viewports in Playwright/Cypress.
4. **Piercing Shadow DOM**: When inspecting Ionic native inputs in tests, target the `ionInput` custom event.

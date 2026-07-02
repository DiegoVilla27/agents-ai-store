---
name: angular-testing-jasmine
description: The ultimate architectural standard for Enterprise Angular Testing with Jasmine fakeAsync, Signal Testing, HttpTestingController, and RouterTestingHarness.
author: Diego Villanueva
trigger: When writing unit tests, mocking services, dealing with async RxJS in tests, or testing Signals/DOM.
---

# Enterprise Angular Testing Architecture (Jasmine)

Unit tests in an Enterprise application must be fast, deterministic, and resilient to refactoring. If a test breaks because you changed a private variable name, the test is written poorly. 

**Test behavior, not implementation.**

## 1. TestBed Setup (Standalone Components)

With modern Angular (v14+), components are Standalone. You no longer need to declare them in a `declarations` array.

**❌ NEVER** provide real implementations of external services (like `HttpClient` or `UserService`) in a component test.
**✅ ALWAYS** mock dependencies using `jasmine.createSpyObj` to ensure true unit isolation.

```typescript
// ✅ ALWAYS: Properly mock dependencies and setup Standalone components
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserProfileComponent } from './user-profile.component';
import { UserService } from './user.service';
import { of } from 'rxjs';

describe('UserProfileComponent', () => {
  let component: UserProfileComponent;
  let fixture: ComponentFixture<UserProfileComponent>;
  let mockUserService: jasmine.SpyObj<UserService>;

  beforeEach(async () => {
    // 1. Create a Spy Object with the methods the component will call
    mockUserService = jasmine.createSpyObj('UserService', ['getUser']);
    
    // 2. Set default return values BEFORE compiling the component
    mockUserService.getUser.and.returnValue(of({ id: 1, name: 'Diego' }));

    await TestBed.configureTestingModule({
      imports: [UserProfileComponent], // Standalone components go in imports
      providers: [
        { provide: UserService, useValue: mockUserService }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(UserProfileComponent);
    component = fixture.componentInstance;
    
    // 3. Trigger initial data binding and lifecycle hooks (ngOnInit)
    fixture.detectChanges(); 
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
```

## 2. Testing Signals (The New Standard)

Signals are synchronous and heavily simplify testing. You do not need `fakeAsync` or RxJS marbles to test them.

**✅ ALWAYS** update the Signal, run `detectChanges()`, and assert against the DOM.

```typescript
it('should display the updated counter when clicked', () => {
  // 1. Assert initial state
  const button = fixture.debugElement.query(By.css('button')).nativeElement;
  expect(button.textContent).toContain('Count: 0');

  // 2. Interact with the component (or update the signal directly: component.count.set(1))
  button.click();
  
  // 3. Tell Angular to re-evaluate the HTML template based on the new Signal value
  fixture.detectChanges(); 

  // 4. Assert the DOM reflects the change
  expect(button.textContent).toContain('Count: 1');
});
```

## 3. Asynchronous Testing (`fakeAsync` & `tick`)

When a component relies on RxJS `delay`, `setTimeout`, or Promises, testing it asynchronously causes flaky tests (tests that fail randomly).

**❌ NEVER** use `done()` callbacks or `async/await` with `fixture.whenStable()` if you can avoid it.
**✅ ALWAYS** use `fakeAsync` and `tick()` to freeze time and execute async code synchronously.

```typescript
import { fakeAsync, tick, flush } from '@angular/core/testing';

it('should show success message after 3 seconds', fakeAsync(() => {
  component.submitForm();
  fixture.detectChanges();

  // The success message shouldn't be there yet
  expect(component.showSuccess).toBeFalse();

  // Fast-forward time by exactly 3000 milliseconds
  tick(3000);
  fixture.detectChanges();

  expect(component.showSuccess).toBeTrue();

  // If there are any pending setTimeouts left in the queue, clear them
  flush(); 
}));
```

## 4. Testing HTTP Requests (`HttpTestingController`)

When testing a **Service** that makes API calls, you MUST NOT make real network requests.

**✅ ALWAYS** use `provideHttpClientTesting()` and the `HttpTestingController`.

```typescript
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';

describe('ApiService', () => {
  let service: ApiService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        ApiService,
        provideHttpClient(),
        provideHttpClientTesting() // Intercepts all HTTP requests
      ]
    });
    service = TestBed.inject(ApiService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    // Ensure no requests are left hanging
    httpMock.verify(); 
  });

  it('should fetch data correctly', () => {
    const mockData = { id: 1, title: 'Test' };

    // 1. Subscribe to the service method
    service.getData().subscribe(data => {
      expect(data).toEqual(mockData);
    });

    // 2. Expect that exactly one GET request was made to this URL
    const req = httpMock.expectOne('/api/data');
    expect(req.request.method).toBe('GET');

    // 3. Flush (respond to) the request with our mock data
    req.flush(mockData);
  });
});
```

## 5. Testing Routing (`RouterTestingHarness`)

In the past, testing routes required `RouterTestingModule`, which is now deprecated.

**✅ ALWAYS** use `RouterTestingHarness` for modern route testing. It automatically handles the complex initialization of the router.

```typescript
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';

describe('Routing', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([
          { path: 'profile/:id', component: ProfileComponent }
        ])
      ]
    });
  });

  it('should navigate and bind route parameters', async () => {
    // 1. Create the harness
    const harness = await RouterTestingHarness.create();
    
    // 2. Navigate to the route. It returns the instantiated component!
    const component = await harness.navigateByUrl('/profile/123', ProfileComponent);
    
    // 3. Assert that the component received the ID (via withComponentInputBinding)
    expect(component.id()).toBe('123');
  });
});
```

---

**Execution Protocol**
1. **Never test private methods**: Do not use `component['privateMethod']()` or `@ts-ignore` to test private functions. If a method is private, it should be tested implicitly by testing the public method that calls it.
2. **DOM Queries**: Prefer querying by `data-testid` attributes (e.g., `By.css('[data-testid="submit-btn"]')`) rather than CSS classes (`.btn-primary`). CSS classes change often for styling; test IDs do not.
3. **Avoid `NO_ERRORS_SCHEMA`**: It hides legitimate errors like misspelled components. If your component uses a child component that you don't want to test, create a lightweight Stub component in the test file instead of ignoring all template errors.

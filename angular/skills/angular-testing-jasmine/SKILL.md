---
name: angular-testing-jasmine
description: >
  Enterprise-standard testing for Angular using Jasmine and Karma.
  Trigger: When writing unit or integration tests with Jasmine and Karma in Angular.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## TestBed Setup (REQUIRED)

Configure the testing environment before each spec.

```typescript
// ✅ ALWAYS: Use compileComponents and handle schema
beforeEach(async () => {
  await TestBed.configureTestingModule({
    imports: [UserProfileComponent],
    providers: [{ provide: UserService, useValue: mockUserService }]
  }).compileComponents();
});

// ❌ NEVER: Shallow testing by default
// Prefer testing the component and its template together as a unit.
```

---

## Mocking with Spies (REQUIRED)

```typescript
// ✅ ALWAYS: Use spyOn for service methods
const userService = TestBed.inject(UserService);
spyOn(userService, 'getUser').and.returnValue(of(mockUser));

fixture.detectChanges();
expect(userService.getUser).toHaveBeenCalled();

// ❌ NEVER: Manually creating large mock objects
// Use 'spyOn' to intercept calls on the real service or a lightweight mock.
```

---

## Async with fakeAsync (REQUIRED)

```typescript
// ✅ ALWAYS: Use fakeAsync and tick for timers and microtasks
it('should show message after delay', fakeAsync(() => {
  component.startDelay();
  tick(500); // Fast-forward time
  fixture.detectChanges();
  expect(component.message).toBe('Ready');
}));

// ❌ NEVER: Thread.sleep or actual timeouts in tests
// Use 'fakeAsync' and 'tick' to keep tests synchronous and fast.
```

---

## Querying the DOM (REQUIRED)

| Token Type | Recommendation |
|------------|----------------|
| **By.css** | Query elements using CSS selectors. |
| **By.directive** | Best for finding child components or custom directives. |
| **fixture.debugElement** | Access the underlying native element safely. |

---

## Execution Protocol (REQUIRED)

1. **Setup**: Configure `TestBed` with necessary components and mocks.
2. **Inject**: Retrieve instances using `TestBed.inject()`.
3. **Trigger**: Manually call `fixture.detectChanges()` to update the view.
4. **Assert**: Verify both the class state and the rendered HTML.

---

## Uncompromising Constraints

- **No Shared State**: Ensure every `it` block is independent and resets the `TestBed`.
- **Change Detection**: Remember that `fixture.detectChanges()` is required after every state change in tests.
- **Service Isolation**: Never let tests call actual backend services.
 Broadway.

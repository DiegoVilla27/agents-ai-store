---
name: clean-code
description: >
  Guardian of technical excellence and software sustainability.
  Trigger: When writing or refactoring any code to ensure it is readable, testable, and evolvable.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Universal Design Principles (REQUIRED)

Simplicity is the ultimate sophistication. Avoid over-engineering.

```typescript
// ✅ ALWAYS: SOLID, DRY, KISS, and YAGNI
// Apply SOLID to decouple components.
// Abstract recurring patterns to avoid duplication (DRY).
// Focus on current value; keep it simple and flexible.

// ❌ NEVER: Over-engineering or "just in case" features
// Do not implement functionality that isn't needed today.
// Do not use a 50-line solution when 5 lines will do safely.
```

---

## Semantic Naming & Purpose (REQUIRED)

Names must reveal intent without needing comments.

```typescript
// ✅ ALWAYS: Semantic naming and single-purpose functions
function calculateMonthlySubscription(user: User): number {
  return user.plan.price * user.usagePercentage;
}

// ❌ NEVER: Magic numbers or generic names
function data(u: any) {
  return u.p * 0.5; // What is 0.5? What is p?
}
```

---

## Fail Fast & Logic Safety (REQUIRED)

Code should fail as early and loudly as possible to avoid silent errors.

```typescript
// ✅ ALWAYS: Robust validation and early exits
function processOrder(order: Order) {
  if (!order.isValid) throw new InvalidOrderError();
  if (order.isExpired) return;
  
  // proceed with logic...
}

// ❌ NEVER: Silent failures or nested "if" hell
function processOrder(order: Order) {
  if (order.isValid) {
    if (!order.isExpired) {
      // deep nested logic...
    }
  }
}
```

---

## Execution Protocol (REQUIRED)

| Step | Action |
|------|--------|
| **Static Analysis** | Use linters and code analysis tools before committing. |
| **Continuous Refactor** | Clean the code as you build; don't wait for a "refactoring phase." |
| **Boy Scout Rule** | Always leave the code a little better than you found it. |
| **Peer Review** | Write code assuming the next maintainer knows where you live. |

---

## Uncompromising Constraints

- **Dead Code**: Commented-out or unused code must be removed immediately.
- **Complexity**: Do not allow a method's cyclomatic complexity to skyrocket.
- **Magic Values**: All magic numbers and strings must be replaced with named constants.

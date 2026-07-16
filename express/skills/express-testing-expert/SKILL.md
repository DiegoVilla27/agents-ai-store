---
name: express-testing-expert
description: Guidelines for unit testing Express.js application layers (controllers, use cases, domain entities) and integration/E2E testing of API routes using Vitest/Jest and Supertest.
author: Diego Villanueva
trigger: When writing unit tests for controllers or use cases, structuring integration flows, or configuring Supertest setups.
---

# Express.js Testing Engineering Protocol

Testing backend services must cover both atomic validation of domain rules (Unit Testing) and web routing boundaries including middlewares, validation, and HTTP statuses (Integration Testing).

---

## 1. Separate App Configuration from Server Listener

To perform integration tests on Express routing without opening active network socket connections, you must separate Express instantiation from the listening process.

**❌ NEVER** call `app.listen()` inside the same file where you configure middlewares and routes.
**✅ ALWAYS** isolate configuration in `app.ts` and call `app.listen()` in a separate entrypoint file (e.g. `server.ts`).

```typescript
// ❌ NEVER: Hard to test because importing this file automatically starts listening
import express from 'express';
const app = express();
app.get('/health', (req, res) => res.sendStatus(200));
app.listen(3000); // Bad!

// ✅ ALWAYS: Separate App from Server
// app.ts (configuration only)
import express from 'express';
export const app = express();
app.get('/health', (req, res) => res.sendStatus(200));

// server.ts (listener entrypoint)
import { app } from './app';
app.listen(process.env.PORT || 3000);
```

---

## 2. Integration Testing using Supertest

Integration tests target routing, request parsing, authentication guards, Zod schema validation, and error interceptors in one pipeline.

**❌ NEVER** test controllers in integration suites by manually creating dummy raw JavaScript requests and responses (e.g. `const req = {}`).
**✅ ALWAYS** use **Supertest** (`supertest`) to issue mock HTTP requests against the configured Express instance.

```typescript
// ✅ ALWAYS: Write clean route integration tests
import request from 'supertest';
import { app } from '../../app';

describe('POST /api/v1/users', () => {
  it('should validate inputs and return 400 when email is invalid', async () => {
    const response = await request(app)
      .post('/api/v1/users')
      .send({
        email: 'invalid-email',
        password: '123'
      });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
    expect(response.body.errors).toBeDefined();
  });
});
```

---

## 3. Mocking Database Dependencies in Unit Tests

Unit tests target the Core Business logic (Application Use Cases and Domain Entities) in isolation from external services. They must run fast and without a database connection.

**❌ NEVER** connect to a real, live database during unit tests.
**✅ ALWAYS** inject mock repository instances or stub implementations into the constructor.

```typescript
// ✅ ALWAYS: Test use cases with mocked repository adapters
import { RegisterUserUseCase } from '../../application/use-cases/RegisterUserUseCase';
import { IUserRepository } from '../../domain/repositories/IUserRepository';

describe('RegisterUserUseCase', () => {
  let mockUserRepository: vi.Mocked<IUserRepository>;
  let useCase: RegisterUserUseCase;

  beforeEach(() => {
    mockUserRepository = {
      findById: vi.fn(),
      save: vi.fn(),
    } as any;

    useCase = new RegisterUserUseCase(mockUserRepository);
  });

  it('should successfully save new user if username is unique', async () => {
    mockUserRepository.findById.mockResolvedValue(null); // Return empty (not registered)

    await useCase.execute({ email: 'new@domain.com', password: 'securePassword' });

    expect(mockUserRepository.save).toHaveBeenCalledTimes(1);
  });
});
```

---

## 4. Test Isolation & Database States

If integration tests read or write to a database, they must not pollute the state of subsequent test suites.

1. **Test DB Instance**: Run tests against a clean, dedicated PostgreSQL/MySQL container (e.g., using `Docker` or a test schema configuration).
2. **Transaction Rollback**: If using an ORM like Prisma or TypeORM, wrap integration test suites in a database transaction block and rollback modifications after each test executes, or run a database teardown script.
3. **Mocking External APIs**: Use **MSW (Mock Service Worker)** to intercept external network requests rather than hitting actual third-party HTTP endpoints during test runs.

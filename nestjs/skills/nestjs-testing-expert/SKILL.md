---
name: nestjs-testing-expert
description: The ultimate architectural standard for NestJS Testing Unit Testing, Deep Mocking (jest-mock-extended), Testcontainers for Integration Tests, and Supertest E2E.
author: Diego Villanueva
trigger: When writing tests, mocking dependencies, configuring Jest, or setting up E2E testing environments.
---

# NestJS Testing Architecture (Jest & Supertest)

A codebase without tests is legacy code the moment it is written. In NestJS, testing is built-in, but doing it wrong leads to slow, flaky, and unmaintainable test suites.

You must respect the Testing Pyramid: 70% Unit Tests (Blazing fast, no DB), 20% Integration Tests (Real DB), 10% E2E Tests (Full HTTP lifecycle).

## 1. Unit Testing (Domain & Services)

Unit tests must NOT connect to a database, Redis, or external APIs. They must use the `Test.createTestingModule` to instantiate the service, providing MOCKS for all its dependencies.

```typescript
// ✅ ALWAYS: Use jest-mock-extended for absolute type-safe mocking
import { Test, TestingModule } from '@nestjs/testing';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaService } from '../prisma/prisma.service';

describe('UserService', () => {
  let service: UserService;
  let prismaMock: DeepMockProxy<PrismaService>; // Type-safe deep mock!

  beforeEach(async () => {
    prismaMock = mockDeep<PrismaService>();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserService,
        { provide: PrismaService, useValue: prismaMock }, // Inject the mock
      ],
    }).compile();

    service = module.get<UserService>(UserService);
  });

  it('should ban a user', async () => {
    // Arrange
    prismaMock.user.findUnique.mockResolvedValue({ id: '1', status: 'ACTIVE' } as any);
    prismaMock.user.update.mockResolvedValue({ id: '1', status: 'BANNED' } as any);

    // Act
    const result = await service.banUser('1');

    // Assert
    expect(result.status).toBe('BANNED');
    expect(prismaMock.user.update).toHaveBeenCalledWith(expect.objectContaining({
      data: { status: 'BANNED' }
    }));
  });
});
```
*Note: Never use `any` to bypass TypeScript errors in manual mocks. Use `jest-mock-extended` (`mockDeep`).*

## 2. Integration Testing (The Database Rule)

- **❌ NEVER**: Use an in-memory SQLite database for integration tests if your production database is PostgreSQL. SQLite does not support JSONB, Enums, or specific Postgres functions. Your tests will pass locally but fail in production.
- **✅ ALWAYS**: Use **Testcontainers**.

Testcontainers spins up an ephemeral Docker container (e.g., Postgres) before your tests run, executes your Prisma migrations, runs the tests against a REAL database, and then destroys the container.

```typescript
// ✅ ALWAYS: Use Testcontainers for true Integration Testing
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { execSync } from 'child_process';

describe('UserRepository (Integration)', () => {
  let container: StartedPostgreSqlContainer;
  let prisma: PrismaService;

  beforeAll(async () => {
    // 1. Spin up a real Postgres DB in Docker
    container = await new PostgreSqlContainer().start();
    
    // 2. Override environment variable
    process.env.DATABASE_URL = container.getUri();
    
    // 3. Run migrations
    execSync('npx prisma migrate deploy');
    
    prisma = new PrismaService();
    await prisma.$connect();
  }, 30000); // Give Docker time to start

  afterAll(async () => {
    await prisma.$disconnect();
    await container.stop(); // Destroy the DB
  });

  it('should save a user to the real database', async () => {
    // Test actual DB behavior (Unique constraints, cascading deletes, etc.)
  });
});
```

## 3. End-to-End (E2E) Testing

E2E tests simulate a real user hitting your API. They test the entire stack: Routing, Guards, Interceptors, Pipes, Services, and the Database.

You MUST use `supertest` with the NestJS application instance.

```typescript
// ✅ ALWAYS: Configure a full E2E environment
import * as request from 'supertest';
import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AppModule } from './../src/app.module';

describe('UsersController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule], // Import the ENTIRE app
    }).compile();

    app = moduleFixture.createNestApplication();
    
    // CRITICAL: You must replicate your main.ts setup here!
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    
    await app.init();
  });

  afterAll(async () => {
    // CRITICAL: If you forget this, Jest will hang forever
    await app.close(); 
  });

  it('/users (POST) - should return 400 if validation fails', () => {
    return request(app.getHttpServer())
      .post('/users')
      .send({ email: 'not-an-email' }) // Triggers the ValidationPipe
      .expect(400);
  });
});
```

### Bypassing Authentication in E2E
If your endpoints are protected by a `JwtAuthGuard`, setting up a real token for every test is tedious. You can override the Guard dynamically during the test setup:

```typescript
// ✅ ALWAYS: Override Guards for faster E2E testing
const moduleFixture = await Test.createTestingModule({
  imports: [AppModule],
})
.overrideGuard(JwtAuthGuard) // Intercept the Guard
.useValue({ canActivate: () => true }) // Force it to always pass
.compile();
```

## 4. The Anti-Patterns

1. **Testing Private Methods**: NEVER use `service['myPrivateMethod']()` or `@ts-ignore` to test private methods. Private methods are implementation details. You must test them by calling the Public methods that use them.
2. **Leaky State**: Tests must be completely isolated. If Test A creates a user in the database, Test B must not assume that user exists. You MUST clean the database before every single integration/E2E test using a `beforeEach` hook (e.g., `await prisma.user.deleteMany()`).
3. **Flaky Tests (Dates & Timers)**: If your logic relies on `Date.now()` or `setTimeout`, your tests will randomly fail depending on server speed. You MUST use `jest.useFakeTimers()` and `jest.setSystemTime()` to freeze time during the test.

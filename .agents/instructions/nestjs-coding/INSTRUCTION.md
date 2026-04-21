---
name: nestjs-coding
description: >
  Senior NestJS standards focused on Clean Architecture, DDD, and SOLID.
  Trigger: When starting a NestJS project or adding new modules/features.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

# NestJS Professional Coding Standards

## 🏛️ Architectural Hierarchy (Clean Architecture)

All modules must follow a strict layering to decouple business logic from infrastructure.

1. **Domain Layer**: Pure business logic (Entities, Value Objects). No dependencies on NestJS or ORMs.
2. **Application Layer**: Use Cases and Workflows. Orchestrates the domain.
3. **Infrastructure Layer**: Persistence (Prisma/TypeORM implementation), External APIs, Adapters.
4. **Presentation Layer**: Controllers, DTOs, Guards, Pipes.

## 🛠 Directory & Naming Conventions

```text
src/
├── modules/
│   └── [domain_name]/
│       ├── domain/            # Entities, Interfaces (Repository Ports)
│       ├── application/       # Services (Use Cases), DTOs
│       ├── infrastructure/    # Repository Adapters, Mappers
│       └── presentation/      # Controllers, Guards, Pipes
│       └── [domain_name].module.ts
```

- Files must use kebab-case: `user-profile.service.ts`.
- Classes must use PascalCase with descriptive suffixes: `UserProfileService`.

## ✅ ALWAYS

- **Use Dependency Inversion**: Always inject interfaces (via `@Inject()`) for repositories rather than concrete classes.
- **Strict Validation**: Use Zod or Class-Validator for all incoming data in DTOs.
- **Custom Filters**: Use Global Exception Filters to normalize API responses.
- **Interceptors**: Use Interceptors for cross-cutting concerns like logging or response transformation.
- **Barrels (Index Pattern)**: Use `index.ts` files to export clean public APIs for each module layer.

## ❌ NEVER

- **No Logic in Controllers**: Controllers should only handle routing and input validation.
- **No Direct DB Access in Services**: Use the Repository pattern to isolate persistence logic.
- **No Circular Dependencies**: Use `forwardRef()` only as a last resort; prefer refactoring to a shared module.
- **No Big Services**: Split services into smaller, atomic units if they exceed 300 lines.

## 🧪 Testing Pyramid

1. **Unit Tests**: Test pure domain logic (no NestContext).
2. **Integration Tests**: Test repository adapters using real databases (Testcontainers).
3. **E2E Tests**: Test critical paths via `Supertest`.

## 🛡 Security & Auth

- Use `Passport` for strategy management.
- Protect all routes by default using a global `AuthGuard` and use `@Public()` decorator for exemptions.

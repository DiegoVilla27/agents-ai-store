---
description: 'Principal Express.js Architect - Clean Architecture, Domain-Driven Design (DDD) & Production Hardening'
applyTo: '**/*.ts'
---

# Enterprise Express.js Coding Standard & Architecture Protocol

You are a **Principal Backend Architect**. Your prime directive is to build production-grade, highly scalable, and secure RESTful APIs using **Express.js** and **TypeScript**. You strictly enforce **Clean Architecture**, **Domain-Driven Design (DDD)**, and **Security Hardening**.

---

## 🏛️ 1. ARCHITECTURAL PATTERN: Clean Architecture + DDD

The traditional Express pattern of dropping all database calls and business logic directly in route files or fat controllers is strictly **BANNED**.

Every module (bounded context) must reside under `src/modules/[module-name]/` and adhere to this exact 4-layer structure:

```text
src/modules/[module-name]/
├── domain/                  # 🟢 CORE: Pure TypeScript Business Rules (No dependencies)
│   ├── entities/            # Rich Domain Entities (with behavior, NOT just data)
│   ├── value-objects/       # Immutable objects (e.g., Email, PasswordHash, Amount)
│   ├── exceptions/          # Domain-specific errors (e.g., InsufficientFundsError)
│   └── repositories/        # Abstract interfaces for data access (Ports)
├── application/             # 🔵 USE CASES: Orchestration & Use Case flow
│   ├── use-cases/           # Individual service actions (e.g., CreateUserUseCase.ts)
│   ├── dtos/                # Input/Output boundaries
│   └── mappers/             # Mappers translating DB models <-> Domain entities
├── infrastructure/          # 🟡 ADAPTERS: External implementations
│   ├── persistence/         # Prisma, TypeORM, or Mongoose repository implementations
│   └── external-services/   # HTTP Clients, payment gateways, mail dispatchers
└── presentation/            # 🔴 DELIVERY: Express interfaces
    ├── controllers/         # Handler logic (validates, extracts inputs, calls use case)
    ├── routes/              # Express Router declarations
    └── middlewares/         # Route-specific validation or authentication guards
```

### Dependency Inversion Principle (DIP):
- **Domain** depends on absolutely nothing. No framework imports (`express`), no ORM decorators (`@Entity`), and no NPM packages (unless utility packages like `uuid`).
- **Application** depends only on Domain.
- **Infrastructure** and **Presentation** depend on Domain and Application.

---

## 🧠 2. DOMAIN-DRIVEN DESIGN (DDD) Rules

### A. Rich Entities vs Anemic Models
**❌ NEVER** create entities that are simply dumb objects containing public fields with getters/setters.
**✅ ALWAYS** encapsulate invariants and business logic inside the entity. State mutations must occur through descriptive methods.

```typescript
// 🟢 Domain Layer: Pure TypeScript
export class Product {
  private constructor(
    private readonly id: string,
    private name: string,
    private priceInCents: number,
    private stock: number
  ) {}

  static create(id: string, name: string, priceInCents: number, stock: number): Product {
    if (priceInCents < 0) throw new InvalidPriceError();
    if (stock < 0) throw new InvalidStockError();
    return new Product(id, name, priceInCents, stock);
  }

  decreaseStock(quantity: number): void {
    if (quantity <= 0) throw new InvalidQuantityError();
    if (this.stock < quantity) throw new OutOfStockError();
    this.stock -= quantity;
  }
  
  // Expose fields safely via getters if needed
  public getStock(): number { return this.stock; }
}
```

---

## ⚡ 3. DECOUPLED ROUTING & PRESENTATION

Controllers must contain ZERO business logic or database code. They only parse inputs, coordinate execution with the application layer, and format the HTTP response.

### A. Controller Pattern
**❌ NEVER** write route files that contain inline logic.
**✅ ALWAYS** bind controllers to classes or clean controller functions.

```typescript
// 🔴 Presentation Layer: Controller
import { Request, Response, NextFunction } from 'express';
import { RegisterUserUseCase } from '../../application/use-cases/RegisterUserUseCase';

export class RegisterUserController {
  constructor(private readonly registerUserUseCase: RegisterUserUseCase) {}

  async handle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password } = req.body; // Pre-validated by Zod middleware
      
      const result = await this.registerUserUseCase.execute({ email, password });
      
      res.status(201).json({
        success: true,
        data: result
      });
    } catch (error) {
      next(error); // Delegate error handling to global middleware
    }
  }
}
```

---

## 🛡️ 4. REQUEST VALIDATION BOUNDARY

Never trust incoming request payload parameters. You must validate them before they hit any controller.

**✅ ALWAYS** use **Zod** to validate headers, params, query variables, and request body parameters.

```typescript
// 🔴 Presentation Layer: Validation Middleware
import { Request, Response, NextFunction } from 'express';
import { AnyZodObject, ZodError } from 'zod';

export const validateRequest = (schema: AnyZodObject) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parsed = await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      
      // Re-assign parsed inputs for type safety downstream
      req.body = parsed.body;
      req.query = parsed.query;
      req.params = parsed.params;
      
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          errors: error.errors.map(err => ({
            field: err.path.join('.'),
            message: err.message
          }))
        });
        return;
      }
      next(error);
    }
  };
};
```

---

## 🔌 5. ROBUST ERROR HANDLING & BOUNDARIES

Express does not handle rejected promises automatically in version 4 unless using a wrapper or third-party packages.

**❌ NEVER** wrap every single controller method in explicit `try/catch` blocks manually.
**❌ NEVER** leak database stack traces, SQL errors, or system details to the client.

**✅ ALWAYS** wrap controllers using an asynchronous handler wrapper, or use Express v5 native promise handling.
**✅ ALWAYS** implement a custom `AppError` class separating operational errors from programmer bugs.

```typescript
// 🔵 Application Layer: Base App Error
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly message: string,
    public readonly isOperational = true
  ) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace(this, this.constructor);
  }
}

// 🔴 Presentation Layer: Global Exception Handler
import { Request, Response, NextFunction } from 'express';

export const globalErrorHandler = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const statusCode = error instanceof AppError ? error.statusCode : 500;
  const isOperational = error instanceof AppError ? error.isOperational : false;

  // Log programmer bugs or internal server issues
  if (!isOperational) {
    console.error('💥 Critical programmer error:', error);
  }

  res.status(statusCode).json({
    success: false,
    message: isOperational ? error.message : 'Internal Server Error'
  });
};
```

---

## 🔒 6. SECURITY HARDENING CHECKLIST

1. **Helmet**: Register `helmet()` early in the Express middleware chain to set secure HTTP headers.
2. **CORS Policies**: Explicitly whitelist origins. Never use wildcard `cors(*)` in production configurations.
3. **Rate Limiting**: Apply `express-rate-limit` globally and configure strict thresholds for sensitive routes (e.g. login, password resets).
4. **Data Sanitization**: Sanitize incoming parameters to defend against SQL Injection, NoSQL Injection, and Cross-Site Scripting (XSS).
5. **No Parameter Pollution**: Integrate `hpp` middleware to avoid HTTP parameter pollution vulnerabilities.

---

## 🚀 7. SUMMARY OF BANNED PRACTICES

- **No Inline Route Logic**: Routes only link path to controller/middlewares.
- **No Shared Mutability**: Keep controllers and handlers stateless.
- **No Raw Database Calls inside Presentation**: Keep ORM queries strictly inside the Infrastructure repository implementations.
- **No Uncaught Promise Rejections**: All controllers must delegate exceptions via `next(err)`.
- **No hardcoded Configuration**: Use typed environment validations (e.g. validated via Zod).

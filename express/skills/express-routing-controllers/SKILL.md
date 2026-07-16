---
name: express-routing-controllers
description: Standards for clean route structures, routing optimization, parameter binding, controller decoupling, and eliminating router bloat.
author: Diego Villanueva
trigger: When configuring Express router files, designing REST endpoints, parameter binding, or creating controllers.
---

# Express.js Routing & Controller Design

Express routing determines how an application responds to client requests at a specific endpoint (URI) and HTTP method. Without strict design principles, route definitions degrade into large, coupled scripts full of inline logic.

---

## 1. Zero-Logic Router Mapping

Router files must serve only one purpose: mapping URI routes to specific controllers and route-specific middleware guards.

**❌ NEVER** write inline controller logic or business decisions inside the router files.
**✅ ALWAYS** keep router files purely declarative, passing execution to decoupled controllers.

```typescript
// ❌ NEVER: Cluttered routing file containing inline handlers
import { Router } from 'express';
export const userRouter = Router();

userRouter.post('/', async (req, res) => {
  const user = await db.user.create({ data: req.body }); // Business logic leak!
  res.status(201).json(user);
});

// ✅ ALWAYS: Declarative routing mapping
import { Router } from 'express';
import { RegisterUserController } from '../presentation/controllers/RegisterUserController';
import { validateRequest } from '../../../shared/presentation/middlewares/validateRequest';
import { registerUserSchema } from '../application/dtos/registerUserSchema';

export const createProductRouter = (controller: RegisterUserController): Router => {
  const router = Router();
  
  router.post(
    '/',
    validateRequest(registerUserSchema),
    (req, res, next) => controller.handle(req, res, next)
  );

  return router;
};
```

---

## 2. Decoupled Controller Classes

Controllers are entry gates to the application layer. They parse requests, extract payload objects, trigger use cases, and format responses. They must be testable in isolation without mocking the entire HTTP request lifecycle.

**❌ NEVER** rely directly on Global State variables or import database connection objects directly in controllers.
**✅ ALWAYS** inject Application Use Cases or Services into the Controller constructor to practice Dependency Injection.

```typescript
// ✅ ALWAYS: Use class-based controllers with Dependency Injection
import { Request, Response, NextFunction } from 'express';
import { CreateOrderUseCase } from '../../application/use-cases/CreateOrderUseCase';

export class CreateOrderController {
  constructor(private readonly createOrderUseCase: CreateOrderUseCase) {}

  async handle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { items } = req.body;
      const userId = req.currentUser?.id; // Attached by auth middleware

      if (!userId) {
        res.status(401).json({ success: false, message: 'Unauthenticated' });
        return;
      }

      const order = await this.createOrderUseCase.execute({ userId, items });

      res.status(201).json({
        success: true,
        data: order
      });
    } catch (error) {
      next(error);
    }
  }
}
```

---

## 3. Safe Method Binding

When passing class controller methods to Express routes, the JavaScript execution context (`this` context) is frequently lost, leading to runtime undefined errors.

**❌ NEVER** pass class methods directly without binding context (e.g. `router.post('/', controller.handle)`).
**✅ ALWAYS** wrap calls in arrow functions, or bind `this` explicitly in the route registration.

```typescript
// ❌ NEVER: Loses 'this' context inside RegisterUserController
router.post('/', userController.handle);

// ✅ ALWAYS: Safely route execution using arrow functions
router.post('/', (req, res, next) => userController.handle(req, res, next));

// ✅ ALTERNATIVE: Explicitly bind 'this' inside the constructor
export class UserController {
  constructor() {
    this.handle = this.handle.bind(this);
  }
  async handle(req: Request, res: Response, next: NextFunction) { /* ... */ }
}
```

---

## 4. Parameter and Query Parsing

Express parameters and query variables are parsed as strings by default.

**❌ NEVER** pass raw, unparsed string parameters directly into domain structures or queries.
**✅ ALWAYS** parse and cast parameters (e.g., to integers or UUIDs) explicitly using validation schemas or helper utilities.

```typescript
// ❌ NEVER: Directly querying database with raw string param
const userId = req.params.id; // Could be non-numeric or SQL Injection vector

// ✅ ALWAYS: Parse and validate input boundaries
import { z } from 'zod';
const paramSchema = z.object({
  id: z.string().uuid('Invalid user identifier format')
});
```

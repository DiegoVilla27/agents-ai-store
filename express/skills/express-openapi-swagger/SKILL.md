---
name: express-openapi-swagger
description: The ultimate architectural standard for OpenAPI 3.0 Documentation in Express.js with zod-to-openapi, Swagger UI, Request/Response validation, and Type-Safe Schema Generation.
author: Diego Villanueva
trigger: When generating OpenAPI/Swagger documentation in Express, converting Zod schemas to OpenAPI, serving interactive Swagger UI, or enforcing API contract testing.
---

# Enterprise Express.js OpenAPI & Swagger Architecture

Manual API documentation quickly becomes out-of-date and drifts from the underlying code. By combining **Zod** with **`@asteasolutions/zod-to-openapi`** and **`swagger-ui-express`**, an Express.js application maintains a single source of truth for runtime validation, TypeScript types, and OpenAPI 3.0 documentation.

---

## 1. Setting Up OpenAPI Registry

```bash
npm install @asteasolutions/zod-to-openapi swagger-ui-express zod
npm install -D @types/swagger-ui-express
```

```typescript
// src/common/docs/openapi-registry.ts
import {
  OpenAPIRegistry,
  OpenApiGeneratorV3,
  extendZodWithOpenApi,
} from '@asteasolutions/zod-to-openapi';
import { z } from 'zod';

// Extend Zod with .openapi() metadata methods
extendZodWithOpenApi(z);

export const registry = new OpenAPIRegistry();

// Register Security Scheme
registry.registerComponent('securitySchemes', 'bearerAuth', {
  type: 'http',
  scheme: 'bearer',
  bearerFormat: 'JWT',
});

export function generateOpenApiDocument() {
  const generator = new OpenApiGeneratorV3(registry.definitions);

  return generator.generateDocument({
    openapi: '3.0.0',
    info: {
      title: 'Enterprise Express API',
      version: '1.0.0',
      description: 'Production-ready REST API with auto-generated OpenAPI documentation.',
    },
    servers: [{ url: '/api/v1', description: 'Primary API Gateway' }],
  });
}
```

---

## 2. Defining Schemas with OpenAPI Metadata

```typescript
// src/modules/users/dtos/user.dto.ts
import { z } from 'zod';
import { registry } from '@/common/docs/openapi-registry';

// 1. Zod Schema with OpenAPI metadata
export const CreateUserSchema = registry.register(
  'CreateUserInput',
  z.object({
    email: z.string().email().openapi({
      example: 'architect@enterprise.com',
      description: 'Primary user email address',
    }),
    fullName: z.string().min(2).max(50).openapi({
      example: 'Diego Villanueva',
    }),
    role: z.enum(['USER', 'ADMIN']).default('USER').openapi({
      example: 'USER',
    }),
  })
);

export const UserResponseSchema = registry.register(
  'UserResponse',
  z.object({
    id: z.string().uuid().openapi({ example: '123e4567-e89b-12d3-a456-426614174000' }),
    email: z.string().email(),
    fullName: z.string(),
    role: z.string(),
    createdAt: z.string().datetime(),
  })
);

export type CreateUserInput = z.infer<typeof CreateUserSchema>;
export type UserResponse = z.infer<typeof UserResponseSchema>;
```

---

## 3. Registering Route Paths in the Registry

```typescript
// src/modules/users/routes/user.routes.ts
import { Router } from 'express';
import { registry } from '@/common/docs/openapi-registry';
import { CreateUserSchema, UserResponseSchema } from '../dtos/user.dto';
import { validateRequest } from '@/common/middlewares/validation.middleware';
import { UserController } from '../controllers/user.controller';

const router = Router();
const controller = new UserController();

// Register OpenAPI endpoint specification
registry.registerPath({
  method: 'post',
  path: '/users',
  description: 'Create a new user account',
  summary: 'User Registration',
  tags: ['Users'],
  request: {
    body: {
      content: {
        'application/json': {
          schema: CreateUserSchema,
        },
      },
    },
  },
  responses: {
    201: {
      description: 'User created successfully',
      content: {
        'application/json': {
          schema: UserResponseSchema,
        },
      },
    },
    400: {
      description: 'Validation error',
    },
  },
});

router.post('/users', validateRequest(CreateUserSchema), (req, res, next) => controller.create(req, res, next));

export default router;
```

---

## 4. Serving Interactive Swagger UI

```typescript
// src/app.ts
import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { generateOpenApiDocument } from './common/docs/openapi-registry';

const app = express();
const openApiDoc = generateOpenApiDocument();

// Serve raw JSON spec
app.get('/docs/openapi.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(openApiDoc);
});

// Serve interactive Swagger UI documentation
app.use('/docs', swaggerUi.serve, swaggerUi.setup(openApiDoc));
```

---

**Execution Protocol**
1. **Single Source of Truth**: Never write manual YAML docs. Always generate OpenAPI from Zod schemas.
2. **Always include realistic examples in `.openapi({ example: ... })`**: Enables client developers to understand payload structures instantly.
3. **Register security schemes for authenticated endpoints**: Document `security: [{ bearerAuth: [] }]` on protected routes.
4. **Enforce validation middleware**: Ensure the schema registered in OpenAPI matches the middleware validating the route.

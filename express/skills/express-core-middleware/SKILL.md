---
name: express-core-middleware
description: Standards for custom middleware architecture, application-level bindings, request lifecycles, and request/response object manipulation.
author: Diego Villanueva
trigger: When designing Express middlewares, adjusting standard body parsers, adding custom context parameters, or defining global middleware chains.
---

# Express.js Core Middleware Architecture

Express is essentially a routing and middleware web framework. Its core functionality is built entirely around executing a series of middleware functions during the HTTP request-response cycle. Ensuring middlewares are modular, performant, and correctly typed is critical.

---

## 1. Modular Middleware Separation

Middlewares must be stateless, atomic, and reside in their own files. Do not declare multiple unrelated middleware functions in a single utility file.

**❌ NEVER** clutter `app.ts` or `server.ts` with inline custom middleware handlers.
**✅ ALWAYS** isolate middlewares into dedicated modules and export them cleanly.

```typescript
// ✅ ALWAYS: Isolate and type middlewares properly
import { Request, Response, NextFunction } from 'express';

export const requestCorrelationId = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const correlationId = req.header('x-correlation-id') || crypto.randomUUID();
  req.headers['x-correlation-id'] = correlationId;
  res.setHeader('x-correlation-id', correlationId);
  next();
};
```

---

## 2. Strong Typing for Request Extension

To share state (such as authentication context, transactional database connections, or correlation IDs) between middlewares and controllers, extend Express's native interface definitions safely.

**❌ NEVER** cast the request parameter as `any` (e.g. `(req as any).user`) to bypass TypeScript compiler checks.
**✅ ALWAYS** use declaration merging to declare type extensions on the global Express namespace.

```typescript
// src/types/express.d.ts
import { UserDecodedPayload } from '../modules/auth/domain/value-objects/UserDecodedPayload';

declare global {
  namespace Express {
    interface Request {
      currentUser?: UserDecodedPayload;
      correlationId?: string;
    }
  }
}
```

---

## 3. Middleware Lifecycle execution rules

Middlewares execute in the exact order they are registered. You must separate configuration, global setup, route handling, and post-handler handlers (like error interceptors).

- **Early Execution**: Logging (Morgan), Correlation IDs, CORS, Helmet, and Compression.
- **Middle Execution**: Body Parsers, Custom Sanitizers.
- **Route Level**: Route validation, Auth guards.
- **Trailing Execution**: Page not found (404) catch-alls and Global Error Handler.

```typescript
// app.ts
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { globalErrorHandler } from './shared/presentation/middlewares/globalErrorHandler';

const app = express();

// 1. Edge middlewares
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' })); // Restrict large payload attacks

// 2. Register routes
app.use('/api/v1/users', userRouter);

// 3. Fallbacks
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Resource not found' });
});

// 4. Global Error handling MUST be the last middleware registered
app.use(globalErrorHandler);
```

---

## 4. Execution Protocol & Best Practices

1. **Avoid Next Blockages**: Every middleware path must call `next()` or send a final response. If a logical path fails to do either, the request will hang indefinitely.
2. **Read-Only Request Bodies**: Avoid mutating the payload body (`req.body`) inside intermediate validation/logging middlewares, except for explicit sanitization/normalization.
3. **Handle Middleware Exceptions**: Wrap middleware logic that executes async code in try-catch blocks and pass exceptions to `next(error)`.

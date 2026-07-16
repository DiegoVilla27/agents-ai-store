---
name: express-error-handling
description: Implementation guidelines for robust error handling, asynchronous wrappers, custom application exceptions, and global error boundaries.
author: Diego Villanueva
trigger: When building custom errors, managing uncaught promises, or configuring the global error response middleware.
---

# Express.js Robust Error Handling Blueprint

Error handling is one of the most critical parts of an enterprise application. Unhandled exceptions or promise rejections in Express can crash the Node.js process entirely, or cause memory leaks and leave the application in an undefined state.

---

## 1. Operational vs. Programmer Errors

You must categorize all runtime exceptions into two types:
1. **Operational Errors**: Predictable failures that we know can happen (e.g. Validation errors, Not Found, Conflict, Unauthorized). We must send a clean HTTP status code and an informative error message.
2. **Programmer Errors**: Unanticipated bugs (e.g. `TypeError: Cannot read property of undefined`, database connection drops, syntax errors). We must hide stack traces from users, log details to monitoring platforms, and gracefully restart if the process becomes unstable.

**❌ NEVER** return generic `500 Internal Server Error` containing database tracebacks or raw exceptions.
**✅ ALWAYS** classify operational errors using a custom `AppError` base class.

```typescript
// ✅ ALWAYS: Create a standard classification boundary
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

// Example sub-classes:
export class ResourceNotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(404, `${resource} could not be found.`);
  }
}
```

---

## 2. Resolving Async Request Limitations

In Express 4.x, asynchronous errors thrown inside request handlers or middleware are NOT caught automatically by the framework. If not caught manually, they trigger an `UnhandledPromiseRejection` and can freeze or crash the process.

**❌ NEVER** wrap every route function block in explicit `try/catch` boilerplate blocks.
**✅ ALWAYS** wrap asynchronous controllers in a utility function (`asyncHandler`) to catch and pipe rejections to `next(error)`.

```typescript
// ✅ ALWAYS: Implement an async safety wrapper
import { Request, Response, NextFunction, RequestHandler } from 'express';

export const asyncHandler = (fn: RequestHandler): RequestHandler => {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Usage in Route configuration:
router.get('/products', asyncHandler(async (req, res) => {
  const products = await service.getProducts();
  res.json({ success: true, data: products });
}));
```

---

## 3. Global Error Handling Middleware

An Express global error handling middleware is defined by providing exactly **four parameters** to the middleware function.

**❌ NEVER** register a global handler containing less than 4 arguments (e.g. omitting `next`). Express will not recognize it as an error middleware.
**✅ ALWAYS** declare the global handler with signature `(error, req, res, next)` at the absolute bottom of the middleware chain.

```typescript
// ✅ ALWAYS: Centralize error processing
import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/AppError';

export const globalErrorHandler = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  let statusCode = 500;
  let message = 'Internal Server Error';

  if (error instanceof AppError) {
    statusCode = error.statusCode;
    message = error.message;
  } else if (error.name === 'ValidationError') {
    statusCode = 400; // Translate database/ORM validation error
    message = error.message;
  }

  // 1. Log bad programmer bugs to monitoring / logging systems
  if (statusCode === 500) {
    console.error('💥 Critical internal error:', error);
  }

  // 2. Respond to the client cleanly
  res.status(statusCode).json({
    success: false,
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
};
```

---

## 4. Uncaught Process Failures

Programmer errors can happen outside the request-response lifecycle (e.g., failed startup database connections, timers).

**❌ NEVER** allow uncaught exceptions to go ignored, leaving the application in a potentially broken state.
**✅ ALWAYS** listen for process level error hooks and trigger a graceful shutdown process.

```typescript
// server.ts
import { server } from './app';

process.on('unhandledRejection', (reason: Error) => {
  console.error('💥 UNHANDLED PROMISE REJECTION! Shutting down gracefully...');
  console.error(reason);
  
  // Close HTTP server before exiting to terminate active requests cleanly
  server.close(() => {
    process.exit(1);
  });
});

process.on('uncaughtException', (error: Error) => {
  console.error('💥 UNCAUGHT EXCEPTION! Shutting down immediately...');
  console.error(error);
  process.exit(1);
});
```

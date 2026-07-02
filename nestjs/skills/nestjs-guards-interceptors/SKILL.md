---
name: nestjs-guards-interceptors
description: The ultimate architectural standard for NestJS Security Guards, Aspect-Oriented Interceptors, Context Reflection, and Response Transformation.
author: Diego Villanueva
trigger: When implementing authentication/authorization logic, standardizing API responses, logging requests, or managing metadata.
---

# NestJS Guards & Interceptors Architecture

NestJS separates request lifecycle concerns into highly specialized classes. **Guards** determine *if* a request should proceed (Security). **Interceptors** add extra logic *before* or *after* the execution of a handler using Aspect-Oriented Programming (AOP) via RxJS.

Never mix these responsibilities. Never authorize users inside a Controller. Never format JSON responses inside a Service.

## 1. Guards (Authentication & Authorization)

Guards must implement the `CanActivate` interface. They return a boolean (or a Promise/Observable of a boolean) indicating whether the request is allowed to hit the Controller.

### The Role-Based Access Control (RBAC) Pattern

To build a robust RBAC system, you need three pieces: a Custom Decorator (to attach metadata), a Guard (to read the metadata), and the `Reflector` (to extract it).

```typescript
// ✅ ALWAYS: Step 1 - Define the Custom Metadata Decorator
import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';
// @Roles('admin', 'manager')
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
```

```typescript
// ✅ ALWAYS: Step 2 - Build the Roles Guard
import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from './roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  // Inject the Reflector to read metadata
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    // 1. Extract the required roles from the route handler or controller class
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    // If no roles are required, allow access
    if (!requiredRoles) {
      return true; 
    }

    // 2. Get the user from the Request (assuming an AuthGuard ran before this)
    const { user } = context.switchToHttp().getRequest();

    if (!user || !user.roles) {
      throw new ForbiddenException('Access denied');
    }

    // 3. Verify if the user has at least one of the required roles
    const hasRole = () => user.roles.some((role: string) => requiredRoles.includes(role));
    
    if (!hasRole()) {
      throw new ForbiddenException('Insufficient permissions');
    }

    return true;
  }
}
```

## 2. Interceptors (Aspect-Oriented Programming)

Interceptors implement the `NestInterceptor` interface. They have access to the request *before* the controller runs, and they have access to the response *after* the controller runs via an RxJS stream (`next.handle()`).

### The Global Response Transformer (Standardized JSON)

If your controllers return raw objects or arrays, your API is inconsistent. You MUST use an Interceptor to wrap all successful responses in a standardized envelope (e.g., `{ data: ... }`).

```typescript
// ✅ ALWAYS: Wrap successful responses in a standard envelope
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface StandardResponse<T> {
  data: T;
  timestamp: string;
}

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, StandardResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<StandardResponse<T>> {
    
    // The code BEFORE next.handle() runs before the Controller
    
    return next.handle().pipe(
      // The code AFTER next.handle() intercepts the Controller's return value
      map(data => ({
        data,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
```

### The Performance Logging Interceptor

Interceptors are the perfect place to measure request duration or log incoming payloads without polluting business logic.

```typescript
// ✅ ALWAYS: Use Interceptors for cross-cutting observability
import { Injectable, NestInterceptor, ExecutionContext, CallHandler, Logger } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const method = req.method;
    const url = req.url;
    const now = Date.now();

    return next.handle().pipe(
      // tap() executes side-effects without modifying the response data
      tap(() => this.logger.log(`[${method}] ${url} - ${Date.now() - now}ms`)),
    );
  }
}
```

## 3. The Execution Context (Protocol Agnostic)

NestJS is not just an HTTP framework; it supports WebSockets, Microservices (TCP/Redis/Kafka), and GraphQL. 

**CRITICAL RULE**: Do not blindly cast `context.switchToHttp().getRequest()`. If your application scales to Microservices or GraphQL, your Guards and Interceptors will crash.

```typescript
// ✅ ALWAYS: Verify context type if building shared Guards/Interceptors
export class AgnosticGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    if (context.getType() === 'http') {
      const request = context.switchToHttp().getRequest();
      return this.validateHttp(request);
    } else if (context.getType() === 'rpc') {
      const data = context.switchToRpc().getData();
      return this.validateRpc(data);
    } else if (context.getType() === 'graphql') {
      // Requires @nestjs/graphql GqlExecutionContext
      // const ctx = GqlExecutionContext.create(context);
      return true; 
    }
    return false;
  }
}
```

---

**Execution Protocol**
1. **Binding Order**: Guards run *before* Interceptors. If a Guard throws a `ForbiddenException`, the Interceptor will never execute.
2. **Global Binding vs Local Binding**: You can bind Guards/Interceptors globally in `main.ts` (`app.useGlobalGuards(...)`), at the Controller level (`@UseGuards(RolesGuard)`), or at the method level. Prefer applying AuthGuards globally and using an `@IsPublic()` metadata decorator to opt-out specific routes (like `/login`).
3. **RxJS Mastery**: Interceptors require a solid understanding of RxJS operators. If you need to catch errors thrown by the Controller inside an Interceptor, use the `catchError` operator instead of `map` or `tap`. However, standard error formatting should be handled by Exception Filters, not Interceptors.

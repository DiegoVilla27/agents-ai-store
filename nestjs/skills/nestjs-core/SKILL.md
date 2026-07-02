---
name: nestjs-core
description: The ultimate architectural standard for NestJS Core Dependency Injection, Module Boundaries, The Request Lifecycle, and SOLID Principles.
author: Diego Villanueva
trigger: When configuring NestJS modules, writing providers, implementing DI, or designing the global request lifecycle (Guards/Interceptors).
---

# NestJS Core Architecture

NestJS is an incredibly opinionated framework designed for Enterprise Node.js applications. It relies heavily on Dependency Injection (DI), Decorators, and strict Architectural Boundaries. If you fight the framework or ignore SOLID principles, you will end up with an untestable, tightly coupled monolith.

## 1. Module Architecture (The Modular Monolith)

Do not put all your controllers and providers into `app.module.ts`. You MUST build a Modular Monolith, separating domains into distinct feature modules.

- **Feature Modules**: Encapsulate a specific domain (e.g., `UsersModule`, `OrdersModule`).
- **Shared/Core Modules**: Encapsulate cross-cutting concerns (e.g., `DatabaseModule`, `LoggerModule`).
- **Global Modules**: Use `@Global()` EXTREMELY sparingly (only for configuration or database connections) to avoid silent namespace collisions.

```typescript
// ✅ ALWAYS: Strict Module Encapsulation
@Module({
  imports: [DatabaseModule], // Import dependencies
  controllers: [UsersController],
  providers: [UsersService, UsersRepository], // Internal providers
  exports: [UsersService], // Explicitly export what other modules can use
})
export class UsersModule {}
```

## 2. Dependency Injection (SOLID Principles)

In TypeScript, interfaces do not exist at runtime. If you want to adhere to the Dependency Inversion Principle (DIP) and inject an interface rather than a concrete class, you MUST use Custom Providers with string or `Symbol` tokens.

```typescript
// ❌ ATROCIOUS: Tightly coupled to a concrete class (Hard to mock in tests)
constructor(private usersRepository: PostgresUsersRepository) {}

// ✅ ALWAYS: Inject by Interface using Tokens
export const I_USER_REPOSITORY = Symbol('IUserRepository');

export interface IUserRepository {
  findById(id: string): Promise<User>;
}

@Injectable()
export class UsersService {
  constructor(
    @Inject(I_USER_REPOSITORY) private readonly usersRepo: IUserRepository
  ) {}
}

// In your Module:
providers: [
  UsersService,
  {
    provide: I_USER_REPOSITORY,
    useClass: PostgresUsersRepository, // Easily swap this with MockUserRepository for tests!
  }
]
```

## 3. The Request Lifecycle (The Pipeline)

You must memorize the exact order of execution in NestJS to know where to place your logic:
**Middleware** -> **Guards** -> **Interceptors (Pre-Controller)** -> **Pipes** -> **Controller** -> **Service** -> **Interceptors (Post-Controller)** -> **Exception Filters**

- **Guards**: Authentication and Authorization (Can this user access this?).
- **Pipes**: Validation and Transformation (Is the payload a valid UUID? Is the JSON body matching the DTO?).
- **Interceptors**: Logging, Caching, and Response Mapping.
- **Filters**: Catching unhandled errors and formatting the standard HTTP response.

## 4. Global Exception Filters

Never allow a raw 500 error or stack trace to leak to the client. You MUST implement a Global Exception Filter to standardize all error responses.

```typescript
// ✅ ALWAYS: Standardize Error Responses globally
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    
    const status = 
      exception instanceof HttpException 
        ? exception.getStatus() 
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message = 
      exception instanceof HttpException 
        ? exception.getResponse() 
        : 'Internal server error';

    // Log the actual error to your observability platform (e.g., Datadog, Sentry)
    console.error(exception); 

    response.status(status).json({
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: ctx.getRequest<Request>().url,
      message,
    });
  }
}
```
*Register this globally in `main.ts` using `app.useGlobalFilters(new AllExceptionsFilter());`*

## 5. Custom Decorators (Clean Controllers)

Controllers should be absolutely pristine. They should simply route the request to the service. Do not write logic to extract headers or decode tokens inside the controller.

```typescript
// ✅ ALWAYS: Use Custom Decorators for repetitive extraction
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user; // Assuming a Guard already validated and attached the user
  },
);

// In the Controller:
@Get('me')
getProfile(@CurrentUser() user: UserEntity) {
  return this.usersService.getProfile(user.id);
}
```

## 6. Provider Scopes (Performance Warning)

By default, every Provider in NestJS is a **Singleton**. It is instantiated once when the application starts.

**CRITICAL WARNING**: Do not use `Scope.REQUEST` unless absolutely necessary (e.g., multi-tenant DB connections per request). If you mark a service as `Scope.REQUEST`, NestJS will instantiate a NEW copy of that service, and all its dependencies, on *every single incoming HTTP request*. This will destroy your Garbage Collector and tank your performance.

```typescript
// ❌ ATROCIOUS: Will destroy server performance under load
@Injectable({ scope: Scope.REQUEST })
export class AnalyticsService {}

// ✅ ALWAYS: Default to Singleton (omit scope)
@Injectable()
export class AnalyticsService {}
```

---

**Execution Protocol**
1. **Dynamic Modules**: When building reusable libraries (like a `StripeModule` that needs API keys), use the modern `ConfigurableModuleBuilder` instead of writing the `register()` or `forRoot()` boilerplate by hand.
2. **DTO Validation**: Always use `class-validator` and `class-transformer` alongside a globally registered `ValidationPipe({ whitelist: true })`. This strips out malicious or unexpected fields from the incoming JSON payload before it even hits your controller.
3. **Avoid Fat Controllers**: Controllers handle HTTP. Services handle Business Logic. Repositories handle Data. Never inject a database connection or ORM directly into a Controller.

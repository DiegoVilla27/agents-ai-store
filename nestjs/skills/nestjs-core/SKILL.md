---
name: nestjs-core
description: >
  Core NestJS patterns: Dependency Injection, Modules, and Global Concerns.
  Trigger: When configuring modules, providers, or global application logic.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

# NestJS Core Mastery

## 🧩 Module System

Standardize on **Modular Monolith** principles before splitting into microservices.

### Dynamic Modules
Use the `ConfigurableModuleBuilder` for modern dynamic module definitions.

```typescript
// ✅ ALWAYS
export const { ConfigurableModuleClass, MODULE_OPTIONS_TOKEN } =
  new ConfigurableModuleBuilder<MyModuleOptions>().build();
```

## 💉 Dependency Injection (DI)

### Interface Injection (The Right Way)
Use a string or symbol token to inject interfaces, ensuring decoupling.

```typescript
// ✅ ALWAYS
export const I_USER_REPO = Symbol('IUserRepository');

@Injectable()
export class UserService {
  constructor(
    @Inject(I_USER_REPO) private readonly userRepo: IUserRepository
  ) {}
}
```

## 🌍 Global Concerns

### Custom Decorators
Create semantic decorators for commonly accessed data (current user, roles).

```typescript
// ✅ ALWAYS
export const User = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
```

### Global Filters & Interceptors
Ensure consistent API response shapes.

```typescript
// ✅ ALWAYS
app.useGlobalFilters(new HttpExceptionFilter());
app.useGlobalInterceptors(new ResponseTransformInterceptor());
```

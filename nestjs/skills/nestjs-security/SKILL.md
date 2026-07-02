---
name: nestjs-security
description: The ultimate architectural standard for NestJS Security Passport JWT Authentication, CASL ABAC/RBAC Authorization, DTO Sanitization, and HTTP Hardening.
author: Diego Villanueva
trigger: When configuring authentication strategies, role-based access, JWT tokens, DTO validation pipes, or securing HTTP headers.
---

# NestJS Security & Authorization Architecture

Enterprise security requires a defense-in-depth strategy. In NestJS, this means strictly separating Authentication (Who are you?), Authorization (What can you do?), Payload Sanitization (Is your data safe?), and Network Hardening (Are the headers secure?).

## 1. Authentication (Passport & JWT)

NestJS relies heavily on the `passport` ecosystem. You must encapsulate your validation logic inside Strategies, never inside controllers or middlewares.

```typescript
// ✅ ALWAYS: Isolate JWT extraction and validation in a Strategy
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private usersService: UsersService // DO NOT inject the Repo directly
  ) {
    super({
      // Extract from standard Authorization header
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET'),
    });
  }

  // This method ONLY executes if the JWT signature is valid and not expired
  async validate(payload: JwtPayload) {
    // Optional: Fetch fresh user data if the JWT payload is not enough
    // Or if you need to check if the user was banned AFTER the token was issued
    const user = await this.usersService.findById(payload.sub);
    if (!user || user.status === 'BANNED') {
      throw new UnauthorizedException('Token revoked or user banned');
    }
    
    // Whatever is returned here is injected into req.user
    return user; 
  }
}
```

### The Refresh Token Pattern
- **❌ NEVER**: Set your JWT expiry to "1 year" so users don't get logged out. If that token is stolen, the attacker has a 1-year free pass.
- **✅ ALWAYS**: Set JWT expiry to 15-30 minutes. Issue a long-lived `Refresh Token` stored securely in the database (hashed, like a password) and sent to the client via an `HttpOnly` cookie.

## 2. Authorization (RBAC vs ABAC)

Authentication proves the user exists. Authorization proves they have permission.

### RBAC (Role-Based Access Control)
For simple "Admin vs User" rules, use Custom Decorators and a global `RolesGuard` using the `Reflector` (See the `nestjs-guards-interceptors` skill for the implementation details).

```typescript
// ✅ ALWAYS: Use composable decorators for RBAC
@Post('admin/users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'SUPERUSER')
createUser() { ... }
```

### ABAC (Attribute-Based Access Control) with CASL
If your business logic requires rules like "A user can only update an article if they are the author OR an admin", RBAC fails. You MUST implement ABAC using a library like `CASL`.

```typescript
// ✅ ALWAYS: Use CASL for complex ownership rules
import { AbilityBuilder, createMongoAbility, InferSubjects } from '@casl/ability';

type Subjects = InferSubjects<typeof Article | typeof User> | 'all';

export function createForUser(user: User) {
  const { can, cannot, build } = new AbilityBuilder(createMongoAbility);

  if (user.role === 'ADMIN') {
    can('manage', 'all'); // Admin can do everything
  } else {
    can('read', 'Article'); // Anyone can read
    can('update', 'Article', { authorId: user.id }); // Only author can update
  }

  return build();
}

// In the controller:
const ability = this.caslAbilityFactory.createForUser(req.user);
if (ability.cannot('update', articleToUpdate)) {
  throw new ForbiddenException('You do not own this article');
}
```

## 3. Input Sanitization (The Global Pipe)

Never trust the client. If your DTO expects `{ name: "John" }` and the attacker sends `{ name: "John", isAdmin: true }`, a poorly written TypeORM save operation will make them an admin (Mass Assignment Vulnerability).

```typescript
// ✅ ALWAYS: Configure the Global ValidationPipe securely in main.ts
import { ValidationPipe } from '@nestjs/common';

app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true, // STRIPS OUT properties not defined in the DTO
    forbidNonWhitelisted: true, // THROWS 400 error if extra properties are sent
    transform: true, // Automatically converts strings to numbers/booleans based on TS types
    disableErrorMessages: process.env.NODE_ENV === 'production', // Optional: hide detailed validation errors in prod
  }),
);
```

## 4. HTTP Hardening (Helmet & CORS)

NestJS uses Express (or Fastify) under the hood, which means it inherits default HTTP vulnerabilities.

```typescript
// ✅ ALWAYS: Secure headers with Helmet
import helmet from 'helmet';

// Blocks XSS, Clickjacking, and removes the "X-Powered-By: Express" header
app.use(helmet()); 
```

```typescript
// ✅ ALWAYS: Restrict CORS in production
app.enableCors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://acme.com', 'https://admin.acme.com'] 
    : '*',
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  credentials: true, // Required if using HttpOnly cookies for refresh tokens
});
```

## 5. Rate Limiting (DDoS Protection)

Even cap with Cloudflare, you must protect your endpoints at the application layer to prevent brute-force attacks on your `/login` or `/reset-password` routes.

```typescript
// ✅ ALWAYS: Use @nestjs/throttler globally
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot([{
      ttl: 60000, // 1 minute
      limit: 100, // 100 requests per minute per IP
    }]),
  ],
})
export class AppModule {}
```

---

**Execution Protocol**
1. **Never store secrets in code**: `JWT_SECRET` must always be injected via `ConfigService`. If you hardcode it, you compromise the entire application.
2. **Bcrypt Cost Factor**: When hashing passwords with `bcrypt`, ensure the salt rounds (cost factor) is at least `12`.
3. **Guard Execution Order**: If you apply multiple guards `@UseGuards(JwtAuthGuard, RolesGuard)`, they execute sequentially. If `JwtAuthGuard` fails, `RolesGuard` is never called.

---
name: nestjs-security
description: >
  Robust NestJS security: JWT, Passport Strategies, and RBAC.
  Trigger: When implementing authentication, authorization, or role management.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

# NestJS Security & Authorization

## 🔐 Authentication Ecosystem

### Passport Strategies
Always isolate strategy logic in dedicated classes.

```typescript
// ✅ ALWAYS
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: configService.get('JWT_SECRET'),
    });
  }
}
```

## 🛡️ Authorization (RBAC/ABAC)

### Role Guards
Use metadata and guards for declarative security.

```typescript
// ✅ ALWAYS
@Roles(Role.ADMIN)
@UseGuards(JwtAuthGuard, RolesGuard)
@Get('dashboard')
getDashboard() { ... }
```

## 🧹 Input Sanitization
Use `ValidationPipe` with `whitelist: true` and `forbidNonWhitelisted: true` to prevent injection.

```typescript
// ✅ ALWAYS
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,
  forbidNonWhitelisted: true,
  transform: true,
}));
```

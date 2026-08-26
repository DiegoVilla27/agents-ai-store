---
name: nestjs-authentication-auth0-oidc
description: The ultimate architectural standard for Enterprise Single Sign-On (SSO), OpenID Connect (OIDC), Auth0 / Keycloak Integration, and JWKS Token Verification in NestJS.
author: Diego Villanueva
trigger: When configuring Enterprise SSO, integrating Auth0, Keycloak, or Okta in NestJS, validating JWKS public keys, or handling OIDC tokens.
---

# Enterprise NestJS SSO & Auth0 / OIDC Architecture

In enterprise B2B applications, authentication is federated to external Identity Providers (IdPs) like **Auth0**, **Keycloak**, **Okta**, or **Azure AD** using OpenID Connect (OIDC) and JSON Web Key Sets (JWKS).

---

## 1. JWKS Passport Strategy Configuration

```bash
npm install @nestjs/passport passport passport-jwt jwks-rsa
npm install -D @types/passport-jwt
```

```typescript
// src/common/auth/jwt-auth0.strategy.ts
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { passportJwtSecret } from 'jwks-rsa';

export interface Auth0JwtPayload {
  iss: string;
  sub: string; // Auth0 user ID: 'auth0|12345'
  aud: string[];
  iat: number;
  exp: number;
  scope?: string;
  'https://api.enterprise.com/roles'?: string[];
}

@Injectable()
export class JwtAuth0Strategy extends PassportStrategy(Strategy, 'auth0') {
  constructor() {
    super({
      secretOrKeyProvider: passportJwtSecret({
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 5,
        jwksUri: `${process.env.AUTH0_ISSUER_URL}.well-known/jwks.json`, // Dynamic Public Key Rotation
      }),
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      audience: process.env.AUTH0_AUDIENCE,
      issuer: process.env.AUTH0_ISSUER_URL,
      algorithms: ['RS256'], // Asymmetric RSA Signature Verification
    });
  }

  validate(payload: Auth0JwtPayload) {
    // Map external IdP claims to internal User Principal
    return {
      id: payload.sub,
      roles: payload['https://api.enterprise.com/roles'] || [],
      scope: payload.scope ? payload.scope.split(' ') : [],
    };
  }
}
```

---

## 2. Dynamic Scope & Permission Guard

```typescript
// src/common/auth/guards/scopes.guard.ts
import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

export const REQUIRE_SCOPES_KEY = 'require_scopes';
export const RequireScopes = (...scopes: string[]) => SetMetadata(REQUIRE_SCOPES_KEY, scopes);

@Injectable()
export class ScopesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredScopes = this.reflector.getAllAndOverride<string[]>(REQUIRE_SCOPES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredScopes || requiredScopes.length === 0) return true;

    const { user } = context.switchToHttp().getRequest();
    if (!user || !user.scope) throw new ForbiddenException('Missing token scopes');

    const hasScope = requiredScopes.every((scope) => user.scope.includes(scope));
    if (!hasScope) {
      throw new ForbiddenException(`Forbidden: Missing required scope [${requiredScopes.join(', ')}]`);
    }

    return true;
  }
}
```

---

## 3. Global Auth Module Registration

```typescript
// src/common/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { JwtAuth0Strategy } from './jwt-auth0.strategy';
import { APP_GUARD } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { ScopesGuard } from './guards/scopes.guard';

@Module({
  imports: [PassportModule.register({ defaultStrategy: 'auth0' })],
  providers: [
    JwtAuth0Strategy,
    // Protect ALL routes by default with Auth0 JWT Guard
    {
      provide: APP_GUARD,
      useClass: AuthGuard('auth0'),
    },
    // Enforce Scope Guard globally
    {
      provide: APP_GUARD,
      useClass: ScopesGuard,
    },
  ],
})
export class AuthModule {}
```

---

**Execution Protocol**
1. **Always use RS256 with dynamic JWKS caching**: Never hardcode public keys or secrets in environment variables.
2. **Always validate `issuer` and `audience`**: Prevents token substitution attacks from different IdP tenants.
3. **Map custom claims using namespaced URIs**: e.g. `https://mycompany.com/tenant_id`.

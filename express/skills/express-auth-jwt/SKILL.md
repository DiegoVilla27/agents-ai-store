---
name: express-auth-jwt
description: The ultimate architectural standard for Express.js Authentication with JWT Access/Refresh Token Rotation, Argon2 Hashing, HTTP-Only Secure Cookies, and RBAC/ABAC Guards.
author: Diego Villanueva
trigger: When implementing authentication in Express, configuring JWT tokens, setting up refresh token rotation, hashing passwords with Argon2, or building role-based authorization.
---

# Enterprise Express.js Authentication Architecture (JWT & RBAC)

Authentication in production Node.js applications demands a defense-in-depth approach. Storing tokens in client-side localStorage exposes apps to XSS attacks, while long-lived access tokens create severe security vulnerabilities.

---

## 1. Token Architecture: Access Token + Refresh Token Rotation

| Token | Lifespan | Storage | Purpose |
|---|---|---|---|
| **Access Token** | 10 - 15 minutes | In-Memory (or Authorization Header) | Authenticating API requests. |
| **Refresh Token** | 7 - 30 days | `httpOnly`, `secure`, `sameSite: 'strict'` Cookie | Reissuing access tokens via rotating single-use tokens. |

---

## 2. Password Hashing with Argon2

**❌ NEVER** use plain MD5, SHA256, or weak bcrypt cost factors.
**✅ ALWAYS** use **Argon2** (winner of the Password Hashing Competition) with memory and time cost parameters.

```typescript
// src/common/security/password-hasher.ts
import argon2 from 'argon2';

export class PasswordHasher {
  static async hash(password: string): Promise<string> {
    return argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16, // 64 MB
      timeCost: 3,
      parallelism: 1,
    });
  }

  static async verify(hash: string, plain: string): Promise<boolean> {
    return argon2.verify(hash, plain);
  }
}
```

---

## 3. JWT Service & Token Generation

```typescript
// src/common/security/jwt.service.ts
import jwt from 'jsonwebtoken';
import { env } from '@/config/env';

export interface TokenPayload {
  userId: string;
  role: 'USER' | 'ADMIN' | 'MANAGER';
}

export class JwtService {
  static generateAccessToken(payload: TokenPayload): string {
    return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
      expiresIn: '15m',
      algorithm: 'HS256',
    });
  }

  static generateRefreshToken(payload: TokenPayload, tokenId: string): string {
    return jwt.sign({ ...payload, jti: tokenId }, env.JWT_REFRESH_SECRET, {
      expiresIn: '7d',
      algorithm: 'HS256',
    });
  }

  static verifyAccessToken(token: string): TokenPayload {
    return jwt.verify(token, env.JWT_ACCESS_SECRET) as TokenPayload;
  }

  static verifyRefreshToken(token: string): TokenPayload & { jti: string } {
    return jwt.verify(token, env.JWT_REFRESH_SECRET) as TokenPayload & { jti: string };
  }
}
```

---

## 4. Authentication Middleware & Cookie Configuration

```typescript
// src/common/middlewares/auth.middleware.ts
import { Request, Response, NextFunction } from 'express';
import { JwtService, TokenPayload } from '../security/jwt.service';
import { AppError } from '../errors/AppError';

// Augment Express Request interface
declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

export const authenticate = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new AppError(401, 'Authentication token missing or malformed');
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = JwtService.verifyAccessToken(token);
    req.user = payload;
    next();
  } catch (err: any) {
    if (err.name === 'TokenExpiredError') {
      throw new AppError(401, 'Access token expired', false);
    }
    throw new AppError(401, 'Invalid authentication token');
  }
};
```

---

## 5. Role-Based Access Control (RBAC) Guard

```typescript
// src/common/middlewares/role.guard.ts
import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/AppError';

export const requireRole = (...allowedRoles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      throw new AppError(401, 'User unauthenticated');
    }

    if (!allowedRoles.includes(req.user.role)) {
      throw new AppError(403, 'Forbidden: Insufficient privileges');
    }

    next();
  };
};
```

---

## 6. Refresh Token Rotation Handler

```typescript
// src/modules/auth/controllers/auth.controller.ts
export class AuthController {
  async refresh(req: Request, res: Response): Promise<void> {
    const refreshToken = req.cookies?.refreshToken;
    if (!refreshToken) {
      throw new AppError(401, 'Refresh token missing');
    }

    const payload = JwtService.verifyRefreshToken(refreshToken);

    // 1. Verify token exists in DB / Redis whitelist (Detect Reuse Attacks)
    const isValid = await tokenRepository.isTokenValid(payload.userId, payload.jti);
    if (!isValid) {
      // Possible token theft / replay attack: Revoke ALL user sessions immediately
      await tokenRepository.revokeAllUserTokens(payload.userId);
      res.clearCookie('refreshToken');
      throw new AppError(401, 'Compromised token detected. Please login again.');
    }

    // 2. Invalidate used refresh token
    await tokenRepository.invalidateToken(payload.jti);

    // 3. Issue NEW Access Token and NEW Refresh Token
    const newJti = crypto.randomUUID();
    const newAccessToken = JwtService.generateAccessToken({ userId: payload.userId, role: payload.role });
    const newRefreshToken = JwtService.generateRefreshToken({ userId: payload.userId, role: payload.role }, newJti);

    // 4. Save new refresh token in store
    await tokenRepository.saveRefreshToken(payload.userId, newJti);

    // 5. Send new cookie and response
    res.cookie('refreshToken', newRefreshToken, {
      httpOnly: true,
      secure: env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    res.status(200).json({
      success: true,
      accessToken: newAccessToken,
    });
  }
}
```

---

**Execution Protocol**
1. **Never store refresh tokens in localStorage**: Always use `httpOnly`, `secure`, `sameSite: 'strict'` cookies.
2. **Implement Refresh Token Rotation (RTR)**: Invalidate the previous refresh token on every issuance; revoke all sessions on reuse detection.
3. **Use Argon2 for password hashing**: Prevents GPU cracking and side-channel attacks.
4. **Always verify token signatures with explicit algorithms**: Pass `{ algorithm: 'HS256' }` to prevent "none" algorithm attacks.

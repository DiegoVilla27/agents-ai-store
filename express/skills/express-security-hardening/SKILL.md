---
name: express-security-hardening
description: Production checklist and configuration guidelines for securing Express.js applications, prevent XSS, CORS misconfig, injection, rate-limiting, and dependency issues.
author: Diego Villanueva
trigger: When configuring security headers, setting CORS policies, applying rate limits, handling passwords, or auditing code vulnerabilities.
---

# Express.js Security Hardening Protocol

By default, Express is barebones and does not include advanced security setups. Running Express in production without manual hardening leaves the server vulnerable to denial of service (DoS), Cross-Site Scripting (XSS), Parameter Pollution, and SQL/NoSQL Injection attacks.

---

## 1. Secure HTTP Headers (Helmet)

Helmet is a collection of middleware functions that set secure HTTP headers to mitigate cross-site scripting (XSS), clickjacking, and mime-type sniffing.

**❌ NEVER** expose Express default headers like `X-Powered-By: Express` to the public web (it reveals implementation details).
**✅ ALWAYS** register `helmet` early and explicitly disable `xPoweredBy` (or let Helmet clean it up).

```typescript
// ✅ ALWAYS: Register Helmet with robust configurations
import express from 'express';
import helmet from 'helmet';

const app = express();

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'trusted-cdn.com'"],
      objectSrc: ["'none'"],
      upgradeInsecureRequests: [],
    },
  },
  referrerPolicy: { policy: 'no-referrer' },
  xssFilter: true, // Prevents XSS reflection attacks
}));

// Manual fallback just in case
app.disable('x-powered-by');
```

---

## 2. Hardened CORS Configuration

Cross-Origin Resource Sharing (CORS) must be configured strictly.

**❌ NEVER** register CORS using wildcard configurations `cors(*)` or reflect requests blindly in production.
**✅ ALWAYS** define an origin whitelist checked by a dynamic validator callback function.

```typescript
// ✅ ALWAYS: Configure CORS with strict whitelist policies
import cors from 'cors';

const allowedOrigins = ['https://app.productiondomain.com', 'https://admin.productiondomain.com'];

export const corsOptions: cors.CorsOptions = {
  origin: (origin, callback) => {
    // Allow server-to-server or local automated tests (where origin is undefined)
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Cross-Origin Request Blocked by Security Policy'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Correlation-ID'],
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
```

---

## 3. Distributed Rate Limiting

Limit incoming request speed to protect authentication endpoints, payment interfaces, and compute-heavy resources from brute force or DoS attacks.

**❌ NEVER** leave sensitive endpoints (like login, reset password, register) unprotected without rate constraints.
**✅ ALWAYS** apply custom rate limit thresholds using `express-rate-limit` coupled with a Redis store if scaling horizontally.

```typescript
// ✅ ALWAYS: Rate limit sensitive endpoints
import rateLimit from 'express-rate-limit';

export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 requests per window
  message: {
    success: false,
    message: 'Too many authentication attempts. Please try again later.'
  },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

app.use('/api/v1/auth/login', authRateLimiter);
```

---

## 4. Parameter Pollution Prevention

HTTP Parameter Pollution (HPP) happens when multiple parameters with the same key are passed (e.g. `?id=1&id=2`), transforming values into arrays that can break application logic.

**❌ NEVER** allow uncleaned multi-value parameters to pass unchecked to database queries.
**✅ ALWAYS** load the `hpp` middleware directly after the Express body parsers.

```typescript
// ✅ ALWAYS: Protect against parameter pollution
import hpp from 'hpp';
import express from 'express';

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(hpp()); // Filter duplicate query parameters
```

---

## 5. Security Best Practices

1. **NoSQL Injection**: When using MongoDB/Mongoose, avoid parsing query objects directly (e.g., passing `{ username: req.body.username }` where username could be `{"$ne": ""}`). Sanitize inputs or validate variables strictly using Zod.
2. **SQL Injection**: Always write parametrized queries or use type-safe ORMs (Prisma, TypeORM). Never build SQL query strings using concatenation.
3. **Session Cookie Hardening**: Always configure session cookies with attributes: `httpOnly: true`, `secure: true` (requires HTTPS), and `sameSite: 'strict'`.

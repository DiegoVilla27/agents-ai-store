---
name: nestjs-database-multitenancy
description: The ultimate architectural standard for Enterprise Multi-Tenancy in NestJS with Schema-per-tenant, DB-per-tenant, Row-Level Security (RLS), and ClsModule (AsyncLocalStorage) Request Scoping.
author: Diego Villanueva
trigger: When designing multi-tenant SaaS architectures in NestJS, isolating tenant data, managing dynamic database connections, or propagating tenant contexts via AsyncLocalStorage.
---

# Enterprise NestJS Multi-Tenancy Architecture

In Enterprise B2B SaaS applications, tenant isolation is a core compliance and security requirement (SOC2, GDPR, HIPAA). NestJS must enforce strict tenant boundaries without incurring memory leaks from request-scoped providers.

---

## 1. The Three Multi-Tenancy Isolation Models

| Isolation Model | Pros | Cons | Best Used For |
|---|---|---|---|
| **1. Database-per-Tenant** | Total isolation, custom backups, highest security | Highest infra cost, connection pool overhead | Enterprise / Banking / Healthcare |
| **2. Schema-per-Tenant** | Strong isolation in single DB instance | Migration complexity across 1000s schemas | Mid-market B2B SaaS |
| **3. Shared DB + Tenant ID (RLS)** | Lowest cost, easiest migrations | Risk of accidental data leakage on missing WHERE clause | High-volume B2C / Startup SaaS |

---

## 2. Request-Scoped Tenant Context via `nestjs-cls` (AsyncLocalStorage)

**❌ NEVER** use `@Injectable({ scope: Scope.REQUEST })` on services or repositories. It recreates the entire dependency tree per HTTP request, destroying performance.
**✅ ALWAYS** use **`nestjs-cls`** (built on Node.js `AsyncLocalStorage`) to make tenant context globally accessible across singleton services.

```bash
npm install nestjs-cls
```

```typescript
// src/common/multitenancy/tenant.middleware.ts
import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { ClsService } from 'nestjs-cls';

@Injectable()
export class TenantMiddleware implements NestMiddleware {
  constructor(private readonly cls: ClsService) {}

  use(req: Request, res: Response, next: NextFunction) {
    // Extract tenant identifier from Subdomain, Header, or JWT claims
    const tenantId =
      (req.headers['x-tenant-id'] as string) ||
      req.hostname.split('.')[0]; // e.g. "acme.app.com" -> "acme"

    if (!tenantId) {
      throw new UnauthorizedException('Missing tenant context identifier');
    }

    // Set in AsyncLocalStorage context (available to entire async call stack)
    this.cls.set('TENANT_ID', tenantId);
    next();
  }
}
```

---

## 3. Dynamic DataSource Multi-Tenancy Provider (Schema / DB Switcher)

```typescript
// src/common/multitenancy/tenant-connection.service.ts
import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ClsService } from 'nestjs-cls';
import { DataSource } from 'typeorm';

@Injectable()
export class TenantConnectionService implements OnModuleDestroy {
  private readonly connectionPool = new Map<string, DataSource>();

  constructor(private readonly cls: ClsService) {}

  async getTenantDataSource(): Promise<DataSource> {
    const tenantId = this.cls.get<string>('TENANT_ID');
    if (!tenantId) throw new Error('Tenant ID not set in current request context');

    if (this.connectionPool.has(tenantId)) {
      return this.connectionPool.get(tenantId)!;
    }

    // Initialize dedicated schema or database connection
    const dataSource = new DataSource({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: 5432,
      username: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      schema: `tenant_${tenantId}`, // Schema-per-tenant isolation
      entities: [/* ... */],
      synchronize: false,
    });

    await dataSource.initialize();
    this.connectionPool.set(tenantId, dataSource);
    return dataSource;
  }

  async onModuleDestroy() {
    for (const ds of this.connectionPool.values()) {
      if (ds.isInitialized) await ds.destroy();
    }
  }
}
```

---

## 4. Row-Level Security (RLS) with Prisma Client Extension

If using a shared database with a `tenantId` column, enforce RLS at the ORM client level:

```typescript
// src/common/prisma/prisma.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { ClsService } from 'nestjs-cls';

@Injectable()
export class PrismaService {
  private client: PrismaClient;

  constructor(private readonly cls: ClsService) {
    this.client = new PrismaClient().$extends({
      query: {
        $allModels: {
          async findMany({ args, query }) {
            const tenantId = cls.get('TENANT_ID');
            args.where = { ...args.where, tenantId }; // Auto-inject tenantId filter
            return query(args);
          },
          async create({ args, query }) {
            const tenantId = cls.get('TENANT_ID');
            args.data = { ...args.data, tenantId }; // Auto-inject tenantId on insert
            return query(args);
          },
        },
      },
    }) as any;
  }

  get db() {
    return this.client;
  }
}
```

---

**Execution Protocol**
1. **Never use `Scope.REQUEST` for multi-tenancy**: Always use `nestjs-cls` with `AsyncLocalStorage`.
2. **Automate tenant schema migrations**: Run migration scripts across all tenant schemas upon CI/CD deployment.
3. **Always validate tenant existence against a central Master catalog**: Prevent arbitrary schema injection attacks.
4. **Isolate Redis and Cache keys by tenant**: Prefix all cache keys: `tenant:${tenantId}:cacheKey`.

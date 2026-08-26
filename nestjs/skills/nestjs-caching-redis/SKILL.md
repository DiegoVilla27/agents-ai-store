---
name: nestjs-caching-redis
description: The ultimate architectural standard for Distributed Caching in NestJS with Redis Cluster, CacheInterceptor, Cache Tagging / Invalidation, and Distributed Locks (Redlock).
author: Diego Villanueva
trigger: When configuring caching in NestJS, setting up Redis cluster cache stores, implementing CacheInterceptor, or acquiring distributed locks with Redlock.
---

# Enterprise NestJS Distributed Caching Architecture (Redis & Redlock)

High-scale enterprise APIs cannot rely on single-node in-memory caches. NestJS applications require **Distributed Redis Caching**, **Declarative Invalidation**, and **Distributed Locks (Redlock)** to prevent cache stamps and race conditions.

---

## 1. Redis Cache Configuration (`@nestjs/cache-manager`)

```bash
npm install @nestjs/cache-manager cache-manager cache-manager-redis-yet redis redlock ioredis
```

```typescript
// src/common/cache/redis-cache.module.ts
import { Module, Global } from '@nestjs/common';
import { CacheModule } from '@nestjs/cache-manager';
import { redisStore } from 'cache-manager-redis-yet';

@Global()
@Module({
  imports: [
    CacheModule.registerAsync({
      useFactory: async () => ({
        store: await redisStore({
          url: process.env.REDIS_URL || 'redis://localhost:6379',
          ttl: 60 * 1000, // Default 60 seconds TTL
        }),
      }),
    }),
  ],
  exports: [CacheModule],
})
export class RedisCacheModule {}
```

---

## 2. Declarative Controller Endpoint Caching (`CacheInterceptor`)

```typescript
// src/modules/products/controllers/products.controller.ts
import { Controller, Get, UseInterceptors, Param } from '@nestjs/common';
import { CacheInterceptor, CacheTTL, CacheKey } from '@nestjs/cache-manager';
import { ProductsService } from '../services/products.service';

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  // Automatically caches HTTP GET responses in Redis
  @Get('top-sellers')
  @UseInterceptors(CacheInterceptor)
  @CacheKey('products:top-sellers')
  @CacheTTL(300 * 1000) // 5 minutes TTL
  async getTopSellers() {
    return this.productsService.getTopSellers();
  }
}
```

---

## 3. Distributed Locking with Redlock (Preventing Race Conditions)

When performing critical atomic operations across multiple instances (e.g. inventory decrements, payment processing):

```typescript
// src/common/locks/distributed-lock.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';
import Redlock, { Lock } from 'redlock';

@Injectable()
export class DistributedLockService implements OnModuleInit {
  private redlock: Redlock;

  onModuleInit() {
    const redisClient = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
    this.redlock = new Redlock([redisClient], {
      driftFactor: 0.01,
      retryCount: 10,
      retryDelay: 200, // 200ms
      retryJitter: 200,
    });
  }

  async withLock<T>(resourceKey: string, ttlMs: number, routine: () => Promise<T>): Promise<T> {
    const lock: Lock = await this.redlock.acquire([`locks:${resourceKey}`], ttlMs);
    try {
      return await routine();
    } finally {
      await lock.release();
    }
  }
}
```

### Consuming Distributed Lock in Service:

```typescript
@Injectable()
export class InventoryService {
  constructor(private readonly lockService: DistributedLockService) {}

  async reserveStock(productId: string, quantity: number): Promise<void> {
    // Guarantees only ONE worker can modify this product's stock at any given millisecond across the cluster
    await this.lockService.withLock(`product:${productId}:stock`, 5000, async () => {
      const stock = await this.getStock(productId);
      if (stock < quantity) throw new Error('Out of stock');
      await this.decrementStock(productId, quantity);
    });
  }
}
```

---

**Execution Protocol**
1. **Always set explicit TTLs on all Redis entries**: Prevents unbounded memory growth.
2. **Use Distributed Locks (`Redlock`) for critical mutations**: Prevents double-spend and race condition exploits.
3. **Use Redis Cache Tags for bulk invalidation**: Invalidate `products:*` upon catalog updates.

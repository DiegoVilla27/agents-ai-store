---
name: nestjs-health-audit
description: The ultimate architectural standard for NestJS Application Reliability Kubernetes Probes (Terminus), Graceful Shutdowns, and Structured Audit Logging.
author: Diego Villanueva
trigger: When configuring health checks, Kubernetes liveness/readiness probes, managing application shutdowns, or implementing structured logging.
---

# NestJS Health, Reliability, & Audit Architecture

A robust Enterprise API must communicate its state clearly to orchestration platforms (Kubernetes, AWS ECS) and shut down without dropping active connections. Returning `200 OK` from a basic `/ping` endpoint is an anti-pattern because it does not verify if the underlying database or cache is actually reachable.

## 1. Health Checks (Liveness vs Readiness)

You must use `@nestjs/terminus` to provide deep health insights. Furthermore, you MUST split your checks into two distinct concepts to prevent Kubernetes from needlessly killing healthy pods that are just suffering from temporary network partitions.

- **Liveness Probe**: "Is the Node.js process frozen?" If this fails, the orchestrator kills and restarts the pod.
- **Readiness Probe**: "Is the database reachable? Can I process traffic?" If this fails, the orchestrator stops sending traffic to the pod, but *does not kill it*, waiting for the database to recover.

```typescript
// ✅ ALWAYS: Split Liveness and Readiness Probes using Terminus
import { Controller, Get } from '@nestjs/common';
import { HealthCheckService, HttpHealthIndicator, MemoryHealthIndicator, HealthCheck } from '@nestjs/terminus';
import { PrismaHealthIndicator } from './prisma-health.indicator';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private http: HttpHealthIndicator,
    private prisma: PrismaHealthIndicator,
    private memory: MemoryHealthIndicator,
  ) {}

  // LIVENESS: K8s calls this to see if the process is alive. Keep it extremely fast.
  @Get('liveness')
  @HealthCheck()
  checkLiveness() {
    return this.health.check([
      // Only check if the heap is under 300MB
      () => this.memory.checkHeap('memory_heap', 300 * 1024 * 1024),
    ]);
  }

  // READINESS: K8s calls this to decide if it should route traffic here.
  @Get('readiness')
  @HealthCheck()
  checkReadiness() {
    return this.health.check([
      // Check if the Database responds to a ping
      () => this.prisma.isHealthy('database'),
      // Check if critical external APIs are up
      () => this.http.pingCheck('payment-gateway', 'https://api.stripe.com/health'),
    ]);
  }
}
```

## 2. Graceful Shutdowns

When you deploy a new version, Kubernetes sends a `SIGTERM` signal to the old pods. By default, Node.js will instantly terminate, dropping any active HTTP requests or database transactions currently in progress. 

You MUST configure Graceful Shutdowns to let active requests finish before dying.

```typescript
// ✅ ALWAYS: Enable Shutdown Hooks in main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // This tells Nest to listen for SIGTERM and SIGINT
  // It triggers the OnModuleDestroy and OnApplicationShutdown lifecycle hooks
  // allowing DB connections to close cleanly.
  app.enableShutdownHooks();

  await app.listen(3000);
}
bootstrap();
```

## 3. Custom Health Indicators

If you use a specialized technology (e.g., an MQTT broker, or a custom gRPC microservice), Terminus won't have a built-in checker. You must implement a custom `HealthIndicator`.

```typescript
// ✅ ALWAYS: Build Custom Indicators for unsupported services
import { Injectable } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult, HealthCheckError } from '@nestjs/terminus';

@Injectable()
export class KafkaHealthIndicator extends HealthIndicator {
  constructor(private kafkaClient: KafkaClient) {
    super();
  }

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    try {
      // Custom logic to ping the broker
      const isConnected = await this.kafkaClient.ping();
      
      if (isConnected) {
        return this.getStatus(key, true, { message: 'Kafka is connected' });
      }
      throw new Error('Kafka ping failed');
    } catch (e) {
      throw new HealthCheckError('KafkaHealthCheck failed', this.getStatus(key, false, { error: e.message }));
    }
  }
}
```

## 4. Audit Logging & Request Tracing (AsyncLocalStorage)

`console.log` is unacceptable for Enterprise auditing. You must use structured JSON logging (e.g., `nestjs-pino`) so that tools like Datadog, ELK, or CloudWatch can parse the logs.

Furthermore, in an asynchronous Node environment, finding all logs related to a single user's request is impossible without a trace ID.

```typescript
// ✅ ALWAYS: Inject a Trace ID into logs using AsyncLocalStorage (ClsHooked)
import { Injectable, NestMiddleware } from '@nestjs/common';
import { AsyncLocalStorage } from 'async_hooks';
import { randomUUID } from 'crypto';

export const als = new AsyncLocalStorage<Map<string, string>>();

@Injectable()
export class TraceIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const traceId = req.headers['x-request-id'] || randomUUID();
    const store = new Map<string, string>();
    store.set('traceId', traceId as string);

    // Everything inside 'next()' will have access to this traceId without passing it as props!
    als.run(store, () => {
      // Add it to the response headers for the client
      res.setHeader('x-trace-id', traceId);
      next();
    });
  }
}

// In any deep service class:
const traceId = als.getStore()?.get('traceId');
logger.info({ traceId, msg: 'Processing payment...' });
```

---

**Execution Protocol**
1. **Public vs Private Probes**: Your `/health/readiness` endpoint often leaks internal architecture (e.g., "redis: DOWN"). You should ideally expose these endpoints on an internal port only, or restrict them via Middleware to specific internal IPs (like the K8s control plane).
2. **Timeouts**: Health checks MUST have strict timeouts (e.g., 3000ms). If the database takes 10 seconds to respond to a ping, the application is effectively dead, and the health check should fail quickly to allow the orchestrator to act.

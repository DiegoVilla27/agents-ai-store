---
name: express-observability-metrics
description: The ultimate architectural standard for Observability in Express.js with Structured Pino Logging, Prometheus Metrics (prom-client), Health Checks (/health/live & /health/ready), and Distributed Tracing.
author: Diego Villanueva
trigger: When configuring structured JSON logging, exporting Prometheus metrics, implementing health-check endpoints, or monitoring production Express apps.
---

# Enterprise Express.js Observability & Metrics Architecture

In production microservices and enterprise backends, unformatted `console.log` statements are unacceptable. Production systems mandate **Structured JSON Logging (Pino)**, **Prometheus Metrics (`prom-client`)**, and **Kubernetes Liveness/Readiness Probes**.

---

## 1. High-Performance Structured Logging with Pino

```bash
npm install pino pino-http
npm install -D pino-pretty
```

```typescript
// src/common/logger/logger.ts
import pino from 'pino';
import { env } from '@/config/env';

export const logger = pino({
  level: env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label.toUpperCase() }),
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  transport:
    env.NODE_ENV === 'development'
      ? {
          target: 'pino-pretty',
          options: { colorize: true, translateTime: 'SYS:standard' },
        }
      : undefined, // Pure JSON in production for Datadog / ELK / CloudWatch
});
```

```typescript
// src/common/middlewares/http-logger.middleware.ts
import pinoHttp from 'pino-http';
import { logger } from '../logger/logger';

export const httpLogger = pinoHttp({
  logger,
  customLogLevel: (req, res, err) => {
    if (res.statusCode >= 500 || err) return 'error';
    if (res.statusCode >= 400) return 'warn';
    return 'info';
  },
  serializers: {
    req: (req) => ({
      id: req.id,
      method: req.method,
      url: req.url,
      ip: req.remoteAddress,
    }),
    res: (res) => ({
      statusCode: res.statusCode,
    }),
  },
});
```

---

## 2. Prometheus Metrics (`prom-client`)

```bash
npm install prom-client
```

```typescript
// src/common/metrics/metrics.ts
import client from 'prom-client';

// Enable default OS and NodeJS runtime metrics (CPU, Memory, Event Loop Lag)
client.collectDefaultMetrics({ prefix: 'express_app_' });

// HTTP Request Duration Histogram
export const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
});

// Active Connections Gauge
export const activeConnectionsGauge = new client.Gauge({
  name: 'http_active_connections',
  help: 'Number of active HTTP connections',
});

// Metrics Middleware
export const metricsMiddleware = (req: any, res: any, next: any) => {
  const start = process.hrtime();
  activeConnectionsGauge.inc();

  res.on('finish', () => {
    activeConnectionsGauge.dec();
    const diff = process.hrtime(start);
    const durationInSeconds = diff[0] + diff[1] / 1e9;
    const route = req.route?.path || req.path;

    httpRequestDuration
      .labels(req.method, route, res.statusCode.toString())
      .observe(durationInSeconds);
  });

  next();
};
```

---

## 3. Health Check Endpoints (Kubernetes Probes)

```typescript
// src/common/routes/health.routes.ts
import { Router } from 'express';
import client from 'prom-client';
import { db } from '@/infrastructure/database';
import { redisClient } from '@/infrastructure/redis';

const router = Router();

// 1. Prometheus Scrape Endpoint (Secured or internal network only)
router.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.send(await client.register.metrics());
});

// 2. Liveness Probe (Is the process running?)
router.get('/health/live', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
});

// 3. Readiness Probe (Are dependencies reachable: DB, Redis, Queues?)
router.get('/health/ready', async (req, res) => {
  const checks: Record<string, 'UP' | 'DOWN'> = {
    server: 'UP',
    database: 'DOWN',
    redis: 'DOWN',
  };

  try {
    // Check DB
    await db.$queryRaw`SELECT 1`;
    checks.database = 'UP';

    // Check Redis
    await redisClient.ping();
    checks.redis = 'UP';

    const isReady = Object.values(checks).every((s) => s === 'UP');
    res.status(isReady ? 200 : 503).json({
      status: isReady ? 'READY' : 'NOT_READY',
      checks,
    });
  } catch (error: any) {
    res.status(503).json({
      status: 'NOT_READY',
      checks,
      error: error.message,
    });
  }
});

export default router;
```

---

## 4. App Integration

```typescript
// src/app.ts
import express from 'express';
import { httpLogger } from './common/middlewares/http-logger.middleware';
import { metricsMiddleware } from './common/metrics/metrics';
import healthRoutes from './common/routes/health.routes';

const app = express();

// Register observability early
app.use(httpLogger);
app.use(metricsMiddleware);
app.use(healthRoutes);
```

---

**Execution Protocol**
1. **Never use `console.log` in production**: Use Pino structured logger with proper log levels (`trace`, `debug`, `info`, `warn`, `error`, `fatal`).
2. **Always separate Liveness (`/health/live`) from Readiness (`/health/ready`)**: A container failing DB readiness should not be restarted, only removed from load balancer rotation.
3. **Always track route patterns, not raw URLs**: Metric labels must be `/users/:id` rather than `/users/123` to prevent high-cardinality memory leaks in Prometheus.

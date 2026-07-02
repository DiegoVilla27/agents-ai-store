---
name: nestjs-lgtm-metrics
description: The ultimate architectural standard for NestJS Full-Stack Observability: LGTM Stack (Loki, Grafana, Tempo, Prometheus), OpenTelemetry, and RED Metrics.
author: Diego Villanueva
trigger: When configuring monitoring, distributed tracing, structured logging, or exporting Prometheus metrics in NestJS.
---

# NestJS Observability (LGTM & OpenTelemetry)

Running an Enterprise application without profound observability is like driving blindfolded at 200 km/h. If the system crashes or performance degrades, you need to know exactly *why*, *where*, and *when*. 

The modern standard is the **LGTM Stack** (Loki for Logs, Grafana for Dashboards, Tempo for Traces, Prometheus for Metrics), powered by **OpenTelemetry (OTel)**.

## 1. The OpenTelemetry Standard (OTel)

You MUST NOT couple your application to a specific vendor's SDK (e.g., Datadog, New Relic, or Dynatrace) directly inside your business logic. You must use OpenTelemetry. OTel standardizes how traces and metrics are collected. You then use an OTel Collector to export that telemetry data to your backend of choice (Grafana Tempo, Datadog, etc.).

### Distributed Tracing (Tempo)

Tracing tracks a single request as it jumps across multiple microservices or database calls.

```typescript
// ✅ ALWAYS: Initialize OpenTelemetry before NestJS starts
// instrument.ts (must be imported at the very top of main.ts before anything else!)
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://localhost:4318/v1/traces', // Your OTel Collector or Tempo endpoint
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```
*Because of `getNodeAutoInstrumentations()`, every HTTP request, Express middleware, Postgres query, and Redis call is automatically traced without modifying your business logic.*

## 2. Structured Logging (Loki + Pino)

Standard `console.log` is useless for log aggregation. Logs must be structured JSON. They must also contain the `trace_id` so you can jump directly from a Grafana Trace to the exact Loki logs for that specific request.

```typescript
// ✅ ALWAYS: Use Pino for high-performance JSON logging with Trace Injection
import { LoggerModule } from 'nestjs-pino';
import { trace } from '@opentelemetry/api';

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        // Automatically inject the OpenTelemetry Trace ID into every log line
        customProps: (req, res) => {
          const span = trace.getSpan(trace.context.active());
          return span ? { trace_id: span.spanContext().traceId } : {};
        },
        // Auto-scrub PII (Personally Identifiable Information)
        redact: ['req.headers.authorization', 'body.password', 'body.creditCard'],
      },
    }),
  ],
})
export class AppModule {}
```

## 3. Metrics & The RED Method (Prometheus)

You must expose a `/metrics` endpoint for Prometheus to scrape. The most important metrics to track for any API are the **RED Metrics**:
- **Rate**: Number of requests per second.
- **Errors**: Number of failed requests.
- **Duration**: How long requests take (Latency).

```typescript
// ✅ ALWAYS: Expose Prometheus Metrics using @willsoto/nestjs-prometheus
import { Controller, Get, UseInterceptors } from '@nestjs/common';
import { InjectMetric } from '@willsoto/nestjs-prometheus';
import { Histogram } from 'prom-client';

@Controller('payments')
export class PaymentsController {
  constructor(
    // Define a custom Histogram for critical business logic latency
    @InjectMetric('payment_processing_duration_seconds')
    private readonly paymentHistogram: Histogram<string>,
  ) {}

  @Post('process')
  async processPayment() {
    // Start the timer
    const end = this.paymentHistogram.startTimer();
    
    try {
      await this.paymentService.charge();
      // Record success metric
      end({ status: 'success' }); 
    } catch (error) {
      // Record error metric
      end({ status: 'error' });
      throw error;
    }
  }
}
```

## 4. Alerting Architecture

Metrics are useless if nobody looks at them. You must configure Grafana Alerts based on your Prometheus metrics.

- **❌ NEVER**: Alert on CPU hitting 80%. CPU is meant to be used. Auto-scaling handles this.
- **✅ ALWAYS**: Alert on High Error Rates (e.g., 5xx errors > 5% in a 5-minute window).
- **✅ ALWAYS**: Alert on High Latency (e.g., P99 latency for `/checkout` exceeds 2000ms).

---

**Execution Protocol**
1. **Trace Context Propagation**: When making HTTP calls to another internal microservice, you MUST forward the `traceparent` header. OpenTelemetry handles this automatically if you use the standard Node `http` or `axios` instrumentations, but be careful if you use custom fetch wrappers.
2. **Cardinality Explosion Warning**: When defining custom Prometheus metrics, NEVER use unbounded labels like `user_id` or `email`. If you have 1 million users, Prometheus will create 1 million distinct time series and crash. Only use low-cardinality labels like `status_code`, `method`, or `payment_type`.
3. **Performance Impact**: OpenTelemetry adds a slight overhead. In extremely high-throughput systems, you should use "Tail-based sampling" (e.g., only storing traces for 10% of successful requests, but 100% of failed requests) configured at the OTel Collector level.

---
name: nestjs-observability-opentelemetry
description: The ultimate architectural standard for Distributed Tracing, OpenTelemetry (OTel), Pino JSON Structured Logging, and Prometheus Metrics in NestJS.
author: Diego Villanueva
trigger: When configuring OpenTelemetry tracing, exporting distributed traces to Jaeger/Datadog, implementing Pino logger, or instrumenting NestJS spans.
---

# Enterprise NestJS Observability & OpenTelemetry (OTel) Architecture

Modern distributed systems require end-to-end trace correlation. **OpenTelemetry (OTel)** provides vendor-neutral distributed tracing across microservices, while **Pino** ensures high-performance structured JSON logging with correlation IDs.

---

## 1. OpenTelemetry Tracing SDK Initialization (`tracer.ts`)

OTel must initialize **before** any other module imports to properly monkey-patch HTTP and database drivers.

```bash
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-trace-otlp-grpc
npm install nestjs-pino pino-http pino-pretty
```

```typescript
// src/tracer.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-grpc';

const traceExporter = new OTLPTraceExporter({
  url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4317',
});

export const otelSDK = new NodeSDK({
  serviceName: 'enterprise-nestjs-service',
  traceExporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      // Auto-instrument HTTP, Express, Redis, PostgreSQL, gRPC, and Kafka!
      '@opentelemetry/instrumentation-fs': { enabled: false }, // Reduce noise
    }),
  ],
});

// Start tracing SDK
otelSDK.start();

process.on('SIGTERM', () => {
  otelSDK.shutdown()
    .then(() => console.log('OTel SDK terminated'))
    .catch((error) => console.log('Error terminating OTel SDK', error))
    .finally(() => process.exit(0));
});
```

---

## 2. High-Speed Structured Logging with `nestjs-pino`

```typescript
// src/app.module.ts
import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL || 'info',
        transport:
          process.env.NODE_ENV !== 'production'
            ? { target: 'pino-pretty', options: { colorize: true } }
            : undefined, // Raw JSON in production
        // Automatically inject current OpenTelemetry Trace ID into every log line!
        customProps: () => {
          const trace = require('@opentelemetry/api').trace.getActiveSpan();
          const spanContext = trace?.spanContext();
          return {
            traceId: spanContext?.traceId,
            spanId: spanContext?.spanId,
          };
        },
      },
    }),
  ],
})
export class AppModule {}
```

---

## 3. Custom Span Instrumentation with `@Trace()`

```typescript
// src/modules/billing/services/payment.service.ts
import { Injectable } from '@nestjs/common';
import { trace, SpanStatusCode } from '@opentelemetry/api';

@Injectable()
export class PaymentService {
  private readonly tracer = trace.getTracer('billing-service');

  async processPayment(orderId: string, amount: number) {
    // Create manual child span for critical business operation
    return this.tracer.startActiveSpan('process_payment_charge', async (span) => {
      try {
        span.setAttribute('order.id', orderId);
        span.setAttribute('payment.amount', amount);

        const result = await this.chargeCustomerCard(orderId, amount);
        span.setStatus({ code: SpanStatusCode.OK });
        return result;
      } catch (error: any) {
        span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
        span.recordException(error);
        throw error;
      } finally {
        span.end();
      }
    });
  }
}
```

---

**Execution Protocol**
1. **Always import `tracer.ts` at the very top of `main.ts` before anything else**: Ensures auto-instrumentation wraps all downstream network drivers.
2. **Never log raw PII (Personally Identifiable Information)**: Redact credit card numbers, passwords, and tokens in Pino serializers.
3. **Correlate Trace IDs with logs**: Allows engineers to click a log error and instantly view the corresponding distributed span trace in Datadog/Jaeger.

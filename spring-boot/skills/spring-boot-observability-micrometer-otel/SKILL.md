---
name: spring-boot-observability-micrometer-otel
description: The ultimate architectural standard for Enterprise Observability in Spring Boot 3.x with Micrometer, Prometheus Metrics, OpenTelemetry Distributed Tracing, and SLF4J MDC Correlation IDs.
author: Diego Villanueva
trigger: When configuring Actuator metrics, exporting Prometheus /metrics, setting up OpenTelemetry distributed tracing with Micrometer Tracing, or correlating logs with trace IDs in Spring Boot 3.x.
---

# Enterprise Spring Boot Observability (Micrometer & OpenTelemetry)

Production enterprise microservices require deep visibility across the three pillars of observability: **Metrics (Prometheus & Micrometer)**, **Distributed Traces (OpenTelemetry & Zipkin/Jaeger)**, and **Structured Logs (SLF4J MDC with Correlation IDs)**.

---

## 1. Dependencies Setup (Spring Boot 3.x Starter Actuator)

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
```

---

## 2. Actuator & Tracing Configuration (`application.yml`)

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, prometheus
  endpoint:
    health:
      show-details: when_authorized
      probes:
        enabled: true # Enables Kubernetes /health/liveness and /health/readiness
    prometheus:
      enabled: true
  metrics:
    tags:
      application: ${spring.application.name}
      environment: ${ENVIRONMENT:production}
    distribution:
      percentiles-histogram:
        http.server.requests: true # Generate SLO / P99 latency buckets
  tracing:
    sampling:
      probability: 1.0 # 100% trace sampling (tune to 0.1 for high-volume prod)
    propagation:
      type: W3C # Standard W3C TraceContext headers (traceparent)
```

---

## 3. Logback Structured JSON & Correlation IDs (`logback-spring.xml`)

Automatically inject `traceId` and `spanId` from Micrometer Tracing into SLF4J MDC:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <appender name="JSON_CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
            <providers>
                <timestamp><timeZone>UTC</timeZone></timestamp>
                <logLevel/>
                <loggerName/>
                <message/>
                <mdc/> <!-- Injects traceId, spanId, userId automatically -->
                <stackTrace/>
            </providers>
        </encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="JSON_CONSOLE"/>
    </root>
</configuration>
```

---

## 4. Custom Business Metrics with Micrometer (`MeterRegistry`)

```java
// service/PaymentProcessingService.java
package com.enterprise.app.payment.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Service;

@Service
public class PaymentProcessingService {

    private final Counter paymentSuccessCounter;
    private final Counter paymentFailureCounter;
    private final Timer paymentProcessingTimer;

    public PaymentProcessingService(MeterRegistry registry) {
        this.paymentSuccessCounter = Counter.builder("payment.transactions.total")
            .tag("status", "success")
            .description("Total successful payment transactions")
            .register(registry);

        this.paymentFailureCounter = Counter.builder("payment.transactions.total")
            .tag("status", "failure")
            .description("Total failed payment transactions")
            .register(registry);

        this.paymentProcessingTimer = Timer.builder("payment.processing.duration")
            .description("Time taken to process payment through payment gateway")
            .register(registry);
    }

    public void processPayment(PaymentRequest request) {
        paymentProcessingTimer.record(() -> {
            try {
                // Execute charge
                gateway.charge(request);
                paymentSuccessCounter.increment();
            } catch (Exception e) {
                paymentFailureCounter.increment();
                throw e;
            }
        });
    }
}
```

---

**Execution Protocol**
1. **Always export Prometheus metrics via `/actuator/prometheus`**: Provides standardized scraping for Grafana.
2. **Enable Kubernetes Liveness and Readiness Probes**: Allows k8s orchestrators to detect deadlocks and restart containers automatically.
3. **Correlate Trace IDs across Microservices**: W3C `traceparent` headers propagate automatically through `RestTemplate` / `RestClient` / `WebClient`.

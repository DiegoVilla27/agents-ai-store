---
name: spring-boot-resilience4j-circuit-breaker
description: The ultimate architectural standard for Enterprise Fault Tolerance in Spring Boot 3.x with Resilience4j (Circuit Breaker, Rate Limiter, Retry, Bulkhead, and Fallbacks).
author: Diego Villanueva
trigger: When configuring fault tolerance in Spring Boot 3.x, setting up Resilience4j circuit breakers, defining fallback methods, or implementing exponential backoff retries.
---

# Enterprise Spring Boot Resilience & Circuit Breakers (Resilience4j)

Distributed microservice architectures fail when upstream service outages cascade into downstream thread pool exhaustion. **Resilience4j** provides lightweight fault-tolerance patterns: **Circuit Breaker**, **Retry (Exponential Backoff)**, **Rate Limiter**, **Bulkhead**, and **Fallback Methods**.

---

## 1. Dependencies Setup

```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-spring-boot3</artifactId>
    <version>2.2.0</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

---

## 2. Declarative Circuit Breaker & Retry Configuration (`application.yml`)

```yaml
resilience4j:
  circuitbreaker:
    instances:
      paymentGateway:
        slidingWindowType: COUNT_BASED
        slidingWindowSize: 10
        minimumNumberOfCalls: 5
        failureRateThreshold: 50.0 # Open circuit if 50% of last 10 calls fail
        waitDurationInOpenState: 10s # Stay OPEN for 10s before transitioning to HALF_OPEN
        permittedNumberOfCallsInHalfOpenState: 3
        automaticTransitionFromOpenToHalfOpenEnabled: true
  retry:
    instances:
      paymentGateway:
        maxAttempts: 3
        waitDuration: 1000ms
        enableExponentialBackoff: true
        exponentialBackoffMultiplier: 2.0
        retryExceptions:
          - java.io.IOException
          - org.springframework.web.client.ResourceAccessException
```

---

## 3. Applying `@CircuitBreaker` and `@Retry` with Fallbacks

```java
// client/PaymentGatewayClient.java
package com.enterprise.app.payment.client;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
@Slf4j
public class PaymentGatewayClient {

    private final RestClient restClient = RestClient.create("https://api.stripe.com");

    @CircuitBreaker(name = "paymentGateway", fallbackMethod = "paymentFallback")
    @Retry(name = "paymentGateway")
    public ChargeResponse executeCharge(ChargeRequest request) {
        log.info("Attempting to charge customer: {}", request.customerId());

        return restClient.post()
            .uri("/v1/charges")
            .body(request)
            .retrieve()
            .body(ChargeResponse.class);
    }

    // Fallback method (MUST match original method signature + Throwable parameter!)
    public ChargeResponse paymentFallback(ChargeRequest request, Throwable ex) {
        log.error("Payment gateway is DOWN. Executing fallback for order: {}. Cause: {}", 
            request.orderId(), ex.getMessage());

        // Return degraded response: Queue payment for asynchronous processing
        return new ChargeResponse(
            request.orderId(),
            "PENDING_OFFLINE",
            "Payment queued for processing upon gateway recovery"
        );
    }
}
```

---

## 4. Bulkhead & Rate Limiting (Preventing Resource Exhaustion)

```java
// Limit concurrent executions to 20 concurrent threads
@Bulkhead(name = "reportGenerator", type = Bulkhead.Type.SEMAPHORE)
// Limit calls to 100 requests per minute
@RateLimiter(name = "publicApiRateLimit")
public Report generateHeavyFinancialReport(String accountId) {
    return reportEngine.compile(accountId);
}
```

---

**Execution Protocol**
1. **Always specify exact fallback signatures**: Fallback methods must take the original method arguments followed by `Throwable ex`.
2. **Never retry non-idempotent operations without idempotent keys**: Prevents duplicate credit card charges on retry.
3. **Expose Circuit Breaker states in Actuator**: Monitor transition metrics (`resilience4j.circuitbreaker.state`) in Prometheus/Grafana.

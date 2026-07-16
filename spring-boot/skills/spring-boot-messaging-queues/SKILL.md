---
name: spring-boot-messaging-queues
description: Event-driven systems integration using Spring Cloud Stream / Kafka, listener concurrency configs, consumer retry, and Dead Letter Queue (DLQ) implementations.
author: Diego Villanueva
trigger: When configuring Spring Kafka listeners, designing message publishers, establishing event-driven retry logic, or setting up DLQ configs.
---

# Spring Boot Messaging & Event-Driven Architecture

Integrating message brokers (Apache Kafka, RabbitMQ) into Spring Boot applications decouples microservices and allows asynchronous event processing. To ensure reliability, you must design for consumer retries, message idempotency, and transactional output boundaries.

---

## 1. Poison Pills & Resilient Consumers (Retry + DLQ)

When an event payload fails validation or causes an unhandled runtime error inside a listener, the consumer can get stuck in an endless retry loop (blocking the partition) or drop the message entirely.

**❌ NEVER** allow unhandled listener exceptions to block message consumption or silently discard failed messages.
**✅ ALWAYS** configure a retry template with backoff policies (e.g., Exponential Backoff) and route persistently failing messages to a **Dead Letter Queue (DLQ)** topic.

```java
// ✅ ALWAYS: Configure resilient Kafka listeners with custom error handlers and DLQ routing
@Component
@Slf4j
public class OrderEventConsumer {

    @KafkaListener(
        topics = "order-created-events",
        groupId = "order-processing-group",
        errorHandler = "kafkaListenerErrorHandler"
    )
    public void consume(OrderCreatedEvent event) {
        log.info("Processing order creation event: {}", event.orderId());
        // Business logic execution
    }
}

// Config file: Set up CommonErrorHandler with DeadLetterPublishingRecoverer
@Configuration
public class KafkaConfig {

    @Bean
    public CommonErrorHandler errorHandler(KafkaTemplate<Object, Object> template) {
        // Route after 3 retries to [original-topic].DLT
        DeadLetterPublishingRecoverer recoverer = new DeadLetterPublishingRecoverer(template);
        
        BackOff backOff = new ExponentialBackOffWithMaxRetries(3); // 3 retries, exponential delay
        
        return new DefaultErrorHandler(recoverer, backOff);
    }
}
```

---

## 2. Idempotent Consumer Pattern

In distributed systems, message brokers guarantee "at-least-once" delivery, which means consumers can receive duplicate events due to network glitches or rebalances.

**❌ NEVER** assume that every message will only be delivered exactly once.
**✅ ALWAYS** implement duplicate message filtering using a database unique constraint check or an **Idempotent Consumer (Inbox Pattern)** store.

```java
@Component
@RequiredArgsConstructor
public class PaymentConsumer {

    private final IdempotencyStore store;
    private final ProcessPaymentUseCase useCase;

    @KafkaListener(topics = "payment-events")
    public void handle(PaymentEvent event) {
        // Enforces event execution exactly once by checking event hash keys
        if (store.isDuplicate(event.eventId())) {
            log.warn("Duplicate event detected: {}. Skipping.", event.eventId());
            return;
        }
        
        useCase.process(event);
        store.markAsProcessed(event.eventId());
    }
}
```

---

## 3. Transactional Outbox Pattern

Directly publishing events during database transactions can lead to inconsistencies: if the message is published successfully but the database transaction rolls back, external services will act on fake data.

**❌ NEVER** publish events directly inside `@Transactional` methods before the database transaction commits.
**✅ ALWAYS** implement the **Transactional Outbox Pattern** (saving the event in a database `outbox` table within the transaction and publishing it asynchronously via a separate thread or Change Data Capture utility).

```java
// ✅ ALWAYS: Save outbox records inside the transaction boundary
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OutboxRepository outboxRepository;

    @Transactional
    public void createOrder(Order order) {
        orderRepository.save(order);
        
        // Write the event in the database outbox table, keeping it atomic
        OutboxEvent event = new OutboxEvent("OrderCreated", order.getId().toString());
        outboxRepository.save(event);
    }
}
```

---
name: nestjs-microservices-kafka
description: The ultimate architectural standard for Distributed Event-Driven Microservices in NestJS with Apache Kafka (kafkajs), Consumer Groups, Partition Keys, DLQ Topics, and Transporters.
author: Diego Villanueva
trigger: When building microservices with Apache Kafka in NestJS, consuming event streams, configuring partition keys, handling message serialization, or implementing dead-letter topics.
---

# Enterprise NestJS Microservices with Apache Kafka

Apache Kafka is the enterprise standard for high-throughput, distributed event streaming. In a NestJS microservices mesh, Kafka provides decoupled communication, horizontal consumer scaling, message replayability, and partition-ordered execution.

---

## 1. Microservice Bootstrap with Kafka Transporter

```bash
npm install @nestjs/microservices kafkajs
```

```typescript
// src/main.ts (Kafka Consumer Microservice)
import { NestFactory } from '@nestjs/core';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.KAFKA,
    options: {
      client: {
        clientId: 'payment-microservice',
        brokers: process.env.KAFKA_BROKERS?.split(',') || ['localhost:9092'],
        ssl: process.env.NODE_ENV === 'production',
      },
      consumer: {
        groupId: 'payment-service-consumer-group',
        allowAutoTopicCreation: false, // Production safety
      },
    },
  });

  await app.listen();
  console.log('🚀 Payment Kafka Microservice listening for event streams');
}

bootstrap();
```

---

## 2. Event Controller & Message Pattern Handlers

```typescript
// src/modules/payments/controllers/payment-events.controller.ts
import { Controller } from '@nestjs/common';
import { EventPattern, Payload, Ctx, KafkaContext } from '@nestjs/microservices';
import { PaymentService } from '../services/payment.service';

export interface OrderCreatedMessage {
  orderId: string;
  customerId: string;
  amount: number;
}

@Controller()
export class PaymentEventsController {
  constructor(private readonly paymentService: PaymentService) {}

  // Consumes from 'order.created' topic
  @EventPattern('order.created')
  async handleOrderCreated(
    @Payload() message: OrderCreatedMessage,
    @Ctx() context: KafkaContext
  ) {
    const originalMessage = context.getMessage();
    const partition = context.getPartition();
    const topic = context.getTopic();

    console.log(`[Kafka] Received event from ${topic} (Partition ${partition}) for Order: ${message.orderId}`);

    try {
      await this.paymentService.processPayment(message.orderId, message.amount);
    } catch (error: any) {
      // Forward to Dead Letter Queue (DLQ) if unrecoverable
      await this.paymentService.forwardToDlq('order.created.dlq', message, error.message);
    }
  }
}
```

---

## 3. Emitting Events with Partition Keys (Ordering Guarantee)

Kafka guarantees strict ordering **per partition**. You MUST supply a `key` (e.g. `customerId` or `orderId`) so all events for the same entity hash to the same partition.

```typescript
// src/modules/orders/services/order.service.ts
import { Injectable, Inject, OnModuleInit } from '@nestjs/common';
import { ClientKafka } from '@nestjs/microservices';

@Injectable()
export class OrderService implements OnModuleInit {
  constructor(
    @Inject('KAFKA_PRODUCER_SERVICE')
    private readonly kafkaClient: ClientKafka
  ) {}

  async onModuleInit() {
    // Connect producer and pre-fetch metadata
    this.kafkaClient.subscribeToResponseOf('order.created');
    await this.kafkaClient.connect();
  }

  async createOrder(orderId: string, customerId: string, amount: number) {
    // 1. Save to DB...

    // 2. Emit Kafka Event with Partition Key
    this.kafkaClient.emit('order.created', {
      key: customerId, // Critical: Enforces partition-level ordering for this customer
      value: {
        orderId,
        customerId,
        amount,
        timestamp: new Date().toISOString(),
      },
    });
  }
}
```

---

## 4. Producer Module Configuration

```typescript
// src/modules/orders/orders.module.ts
import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';

@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'KAFKA_PRODUCER_SERVICE',
        transport: Transport.KAFKA,
        options: {
          client: {
            clientId: 'order-producer',
            brokers: ['localhost:9092'],
          },
          producer: {
            allowAutoTopicCreation: false,
            idempotent: true, // Guarantees exactly-once producer semantics
          },
        },
      },
    ]),
  ],
})
export class OrdersModule {}
```

---

**Execution Protocol**
1. **Always use partition keys**: Ensures sequential ordering for events belonging to the same entity/tenant.
2. **Enable `idempotent: true` on Kafka producers**: Prevents duplicate message emission during transient network retries.
3. **Disable `allowAutoTopicCreation` in production**: All topics must be managed declaratively via IaC / Terraform.
4. **Implement Dead-Letter Topics (DLQ)**: Route permanently failed messages to `*.dlq` topics with error stack context.

---
name: nestjs-microservices-rabbitmq
description: The ultimate architectural standard for AMQP Messaging in NestJS with RabbitMQ, Exchanges (Direct, Topic, Fanout), Manual Acknowledgment (Ack/Nack), and Dead Letter Exchanges (DLX).
author: Diego Villanueva
trigger: When building microservices with RabbitMQ in NestJS, configuring AMQP exchanges/queues, managing manual message acknowledgments, or routing messages.
---

# Enterprise NestJS RabbitMQ & AMQP Architecture

RabbitMQ provides fine-grained, flexible message routing through **Exchanges** (Direct, Topic, Fanout, Headers), guaranteed message delivery with **Manual Acknowledgments (Ack/Nack)**, and automated failure routing via **Dead Letter Exchanges (DLX)**.

---

## 1. RabbitMQ Server Microservice Bootstrap

```bash
npm install @nestjs/microservices amqplib amqp-connection-manager
```

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.RMQ,
    options: {
      urls: [process.env.RABBITMQ_URL || 'amqp://guest:guest@localhost:5672'],
      queue: 'orders_processing_queue',
      noAck: false, // Mandate Manual Acknowledgments for Zero-Loss reliability
      queueOptions: {
        durable: true, // Persist queue across RabbitMQ broker restarts
        arguments: {
          'x-dead-letter-exchange': 'orders_dlx',
          'x-dead-letter-routing-key': 'orders.dead',
        },
      },
    },
  });

  await app.listen();
  console.log('🚀 RabbitMQ Orders Worker listening...');
}

bootstrap();
```

---

## 2. Message Consumer with Manual Ack/Nack

```typescript
// src/modules/orders/controllers/orders-consumer.controller.ts
import { Controller } from '@nestjs/common';
import { MessagePattern, Payload, Ctx, RmqContext } from '@nestjs/microservices';
import { OrdersService } from '../services/orders.service';

@Controller()
export class OrdersConsumerController {
  constructor(private readonly ordersService: OrdersService) {}

  @MessagePattern('order.created')
  async processOrder(@Payload() data: { orderId: string; total: number }, @Ctx() context: RmqContext) {
    const channel = context.getChannelRef();
    const originalMsg = context.getMessage();

    try {
      // Execute business processing
      await this.ordersService.processOrder(data.orderId, data.total);

      // Explicitly acknowledge successful processing
      channel.ack(originalMsg);
    } catch (error) {
      console.error(`Failed to process order ${data.orderId}:`, error);

      // Reject message without requeue (auto-routed to Dead Letter Exchange 'orders_dlx')
      channel.nack(originalMsg, false, false);
    }
  }
}
```

---

## 3. RabbitMQ Producer Client Integration

```typescript
// src/modules/checkout/checkout.module.ts
import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { CheckoutService } from './services/checkout.service';

@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'RABBITMQ_ORDERS_CLIENT',
        transport: Transport.RMQ,
        options: {
          urls: ['amqp://localhost:5672'],
          queue: 'orders_processing_queue',
          queueOptions: { durable: true },
        },
      },
    ]),
  ],
  providers: [CheckoutService],
})
export class CheckoutModule {}
```

```typescript
// src/modules/checkout/services/checkout.service.ts
import { Injectable, Inject } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';

@Injectable()
export class CheckoutService {
  constructor(
    @Inject('RABBITMQ_ORDERS_CLIENT')
    private readonly rmqClient: ClientProxy
  ) {}

  async checkout(orderId: string, total: number) {
    // Publish message to RabbitMQ queue
    this.rmqClient.emit('order.created', { orderId, total });
  }
}
```

---

**Execution Protocol**
1. **Always set `noAck: false`**: Automatic acknowledgments drop messages if the worker crashes mid-execution.
2. **Configure `x-dead-letter-exchange` on every production queue**: Catches poisoned messages without blocking queue throughput.
3. **Always declare queues as `durable: true`**: Survives broker restarts and container redeployments.
4. **Use Prefetch Count (QoS)**: Set channel prefetch (e.g. `prefetch: 10`) to prevent overwhelming worker memory.

---
name: nestjs-microservices-grpc
description: The ultimate architectural standard for High-Throughput RPC Microservices in NestJS with gRPC, Protocol Buffers (Protobuf), Client Streaming, and Load Balancing.
author: Diego Villanueva
trigger: When building low-latency synchronous microservices in NestJS, defining Protobuf contracts, implementing gRPC servers/clients, or streaming binary RPC payloads.
---

# Enterprise NestJS gRPC Microservices Architecture

When microservices communicate synchronously (internal RPCs), standard HTTP/REST introduces massive overhead (JSON serialization, large headers, TCP connection handshakes). **gRPC** over **HTTP/2** with binary **Protocol Buffers (Protobuf)** delivers 7-10x higher throughput and strict contract typing.

---

## 1. Protobuf Contract Definition (`hero.proto`)

```protobuf
// src/modules/hero/hero.proto
syntax = "proto3";

package hero;

service HeroService {
  rpc FindOne (HeroById) returns (Hero) {}
  rpc StreamHeroes (HeroFilter) returns (stream Hero) {}
}

message HeroById {
  int32 id = 1;
}

message HeroFilter {
  string powerType = 1;
}

message Hero {
  int32 id = 1;
  string name = 2;
  string power = 3;
}
```

---

## 2. gRPC Server Microservice Bootstrap

```bash
npm install @nestjs/microservices @grpc/grpc-js @grpc/proto-loader
```

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.GRPC,
    options: {
      package: 'hero',
      protoPath: join(__dirname, 'modules/hero/hero.proto'),
      url: '0.0.0.0:50051',
    },
  });

  await app.listen();
  console.log('🚀 gRPC Microservice listening on port 50051');
}

bootstrap();
```

---

## 3. gRPC Service Controller Implementation

```typescript
// src/modules/hero/hero.controller.ts
import { Controller } from '@nestjs/common';
import { GrpcMethod, GrpcStreamMethod } from '@nestjs/microservices';
import { Observable, Subject } from 'rxjs';

interface HeroById {
  id: number;
}

interface Hero {
  id: number;
  name: string;
  power: string;
}

@Controller()
export class HeroController {
  private readonly heroes: Hero[] = [
    { id: 1, name: 'Flash', power: 'Super Speed' },
    { id: 2, name: 'Superman', power: 'Flight' },
  ];

  // 1. Unary RPC Handler
  @GrpcMethod('HeroService', 'FindOne')
  findOne(data: HeroById): Hero {
    const hero = this.heroes.find((h) => h.id === data.id);
    if (!hero) throw new Error('Hero not found');
    return hero;
  }

  // 2. Server Streaming RPC Handler
  @GrpcMethod('HeroService', 'StreamHeroes')
  streamHeroes(data: { powerType: string }): Observable<Hero> {
    const heroStream$ = new Subject<Hero>();

    setTimeout(() => {
      this.heroes.forEach((h) => heroStream$.next(h));
      heroStream$.complete();
    }, 100);

    return heroStream$.asObservable();
  }
}
```

---

## 4. Consuming gRPC from another NestJS Service (Client)

```typescript
// src/modules/gateway/services/hero-gateway.service.ts
import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';
import { Observable, firstValueFrom } from 'rxjs';

interface HeroServiceClient {
  findOne(data: { id: number }): Observable<Hero>;
  streamHeroes(data: { powerType: string }): Observable<Hero>;
}

@Injectable()
export class HeroGatewayService implements OnModuleInit {
  private heroService: HeroServiceClient;

  constructor(@Inject('HERO_PACKAGE') private readonly client: ClientGrpc) {}

  onModuleInit() {
    this.heroService = this.client.getService<HeroServiceClient>('HeroService');
  }

  async getHero(id: number): Promise<Hero> {
    // Convert gRPC Observable into Promise
    return await firstValueFrom(this.heroService.findOne({ id }));
  }
}
```

---

**Execution Protocol**
1. **Always keep `.proto` files in a shared schema repository or sub-module**: Guarantees contract alignment between services.
2. **Use HTTP/2 multiplexing**: A single TCP connection handles thousands of concurrent gRPC requests.
3. **Use streaming for large payloads**: Stream collections over `Observable<T>` rather than returning huge 50MB response arrays.
4. **Implement interceptors for gRPC metadata propagation**: Propagate auth headers and OpenTelemetry trace IDs across gRPC calls.

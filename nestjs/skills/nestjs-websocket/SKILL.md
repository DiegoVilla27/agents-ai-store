---
name: nestjs-websocket
description: The ultimate architectural standard for NestJS WebSockets: Socket.io, Redis Adapter for Horizontal Scaling, Handshake Authentication, and WsException filters.
author: Diego Villanueva
trigger: When configuring real-time communication, WebSockets, Socket.io gateways, or scaling stateful connections.
---

# NestJS WebSockets & Real-Time Architecture

WebSockets represent a paradigm shift. Unlike HTTP, which is stateless, WebSockets are **Stateful Persistent Connections**. This introduces massive complexities in Authentication, Error Handling, and Horizontal Scaling.

NestJS provides the `@nestjs/platform-socket.io` (and `ws`) packages to wrap this complexity in "Gateways".

## 1. Gateway Lifecycle & Configuration

A Gateway is the WebSocket equivalent of a Controller. You must strictly configure CORS and handle the connection lifecycle.

```typescript
// ✅ ALWAYS: Implement Lifecycle Interfaces and Strict CORS
import { 
  WebSocketGateway, 
  OnGatewayConnection, 
  OnGatewayDisconnect, 
  WebSocketServer 
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: process.env.NODE_ENV === 'production' ? 'https://acme.com' : '*',
    credentials: true,
  },
  namespace: '/notifications', // Always isolate domains via namespaces
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server; // The underlying Socket.io server instance

  handleConnection(client: Socket) {
    console.log(`Client Connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client Disconnected: ${client.id}`);
  }
}
```

## 2. Authentication (The Handshake Problem)

You CANNOT use a standard `@UseGuards(JwtAuthGuard)` on the `handleConnection` method. Standard HTTP guards throw HTTP exceptions, which crash the WebSocket server or simply close the connection silently without telling the client why.

You MUST authenticate during the WebSocket **Handshake** or via a dedicated Middleware.

```typescript
// ✅ ALWAYS: Authenticate via Handshake Auth token
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { WsException } from '@nestjs/websockets';
import { Socket } from 'socket.io';

@Injectable()
export class WsJwtGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const client: Socket = context.switchToWs().getClient();
    
    // Clients must connect via: const socket = io('url', { auth: { token: 'JWT...' } })
    const token = client.handshake.auth.token || client.handshake.headers['authorization'];
    
    if (!token) throw new WsException('Unauthorized');

    try {
      const payload = this.jwtService.verify(token);
      // Attach user to socket instance for future events
      client.data.user = payload; 
      return true;
    } catch (err) {
      throw new WsException('Invalid Token');
    }
  }
}

// Applying it to an event:
@UseGuards(WsJwtGuard)
@SubscribeMessage('send_message')
handleMessage(@MessageBody() data: any, @ConnectedSocket() client: Socket) {
  const user = client.data.user; // Securely retrieved!
}
```

## 3. Horizontal Scaling (The Redis Adapter)

**CRITICAL RULE**: The moment you deploy your NestJS app to Kubernetes with 2 or more replicas, your WebSockets will break. 
User A connects to Pod 1. User B connects to Pod 2. When Pod 1 does `server.emit('hello')`, User B will NEVER receive it because memory is not shared between pods.

You **MUST** use the `@nestjs/platform-socket.io` Redis Adapter to bridge the instances.

```typescript
// ✅ ALWAYS: Configure the Redis Adapter in main.ts for multi-instance deployments
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';

export class RedisIoAdapter extends IoAdapter {
  private adapterConstructor: ReturnType<typeof createAdapter>;

  async connectToRedis(): Promise<void> {
    const pubClient = createClient({ url: process.env.REDIS_URL });
    const subClient = pubClient.duplicate();

    await Promise.all([pubClient.connect(), subClient.connect()]);

    this.adapterConstructor = createAdapter(pubClient, subClient);
  }

  createIOServer(port: number, options?: any): any {
    const server = super.createIOServer(port, options);
    server.adapter(this.adapterConstructor); // Bind Redis to Socket.io
    return server;
  }
}

// In main.ts:
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const redisIoAdapter = new RedisIoAdapter(app);
  await redisIoAdapter.connectToRedis();
  app.useWebSocketAdapter(redisIoAdapter); // Overrides default adapter
  await app.listen(3000);
}
```

## 4. WebSockets Exception Filters

If a `BadRequestException` is thrown inside a `@SubscribeMessage()`, NestJS doesn't know how to send an HTTP 400 over a WebSocket. The connection will fail silently or crash.

You MUST define a custom `WsExceptionFilter`.

```typescript
// ✅ ALWAYS: Catch and format exceptions specifically for WebSockets
import { Catch, ArgumentsHost, HttpException } from '@nestjs/common';
import { BaseWsExceptionFilter, WsException } from '@nestjs/websockets';
import { Socket } from 'socket.io';

@Catch(WsException, HttpException)
export class CustomWsExceptionFilter extends BaseWsExceptionFilter {
  catch(exception: WsException | HttpException, host: ArgumentsHost) {
    const client = host.switchToWs().getClient<Socket>();
    
    const error = exception instanceof HttpException 
      ? exception.getResponse() 
      : exception.getError();

    // Emit a standard error event back to the client
    client.emit('exception', {
      status: 'error',
      message: error,
    });
  }
}

// Apply it:
@UseFilters(new CustomWsExceptionFilter())
@WebSocketGateway()
export class MyGateway {}
```

## 5. The "Rooms" Pattern (Targeted Broadcasting)

Never iterate over all connected clients to find a specific user. Use Socket.io "Rooms".

```typescript
// ✅ ALWAYS: Join a room on connection to identify the user
handleConnection(client: Socket) {
  const userId = this.extractUserId(client);
  // The room name is the User ID. Now we can target them easily!
  client.join(userId); 
}

// Somewhere else in the app:
sendNotificationToUser(userId: string, notification: any) {
  // Emits ONLY to the sockets connected by this specific user (e.g. phone + laptop)
  this.server.to(userId).emit('new_notification', notification);
}
```

---

**Execution Protocol**
1. **ValidationPipe**: Just like HTTP, you MUST use `ValidationPipe` for `@MessageBody()`. Set `app.useGlobalPipes(new ValidationPipe())` in `main.ts`, and make sure your DTOs validate incoming socket payloads.
2. **Ping/Pong**: Keep-alive is handled automatically by Socket.io, but if you put Nginx or AWS ALB in front of your app, you must configure their proxy read timeouts to be longer than the Socket.io ping interval, or connections will drop randomly.
3. **Stateless Business Logic**: The Gateway should only be responsible for receiving/sending messages. Move all core business logic (saving messages to DB, calculating stats) to standard `@Injectable()` Services.

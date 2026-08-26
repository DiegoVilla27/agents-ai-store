---
name: express-websocket-realtime
description: The ultimate architectural standard for Real-Time WebSockets in Express.js with Socket.io / ws, Authenticated Handshakes, Room Architecture, and Redis Adapter Horizontal Scaling.
author: Diego Villanueva
trigger: When building real-time features, chat systems, live notifications, collaborative editing, or scaling WebSockets with Redis in Express.
---

# Enterprise Express.js Real-Time WebSocket Architecture

Real-time capabilities (live chat, notifications, IoT telemetry, real-time dashboards) require a resilient WebSocket infrastructure that authenticates connections, organizes clients into channels/rooms, and scales horizontally across multiple Node.js instances using Redis Pub/Sub.

---

## 1. Socket.io Server Setup with Redis Adapter

```bash
npm install socket.io @socket.io/redis-adapter redis
```

```typescript
// src/common/websocket/socket.server.ts
import { Server as HttpServer } from 'http';
import { Server as SocketIOServer, Socket } from 'socket.io';
import { createClient } from 'redis';
import { createAdapter } from '@socket.io/redis-adapter';
import { JwtService } from '../security/jwt.service';
import { env } from '@/config/env';

export class WebSocketServer {
  private static io: SocketIOServer;

  static async initialize(httpServer: HttpServer): Promise<SocketIOServer> {
    this.io = new SocketIOServer(httpServer, {
      cors: {
        origin: env.CORS_ORIGINS,
        credentials: true,
      },
      pingInterval: 25000,
      pingTimeout: 20000,
    });

    // Configure Redis Adapter for Horizontal Multi-Server Scaling
    if (env.REDIS_URL) {
      const pubClient = createClient({ url: env.REDIS_URL });
      const subClient = pubClient.duplicate();

      await Promise.all([pubClient.connect(), subClient.connect()]);
      this.io.adapter(createAdapter(pubClient, subClient));
      console.log('📡 WebSocket Redis Adapter connected');
    }

    // Register Authentication Middleware
    this.io.use((socket, next) => this.authMiddleware(socket, next));

    // Register Connection Events
    this.io.on('connection', (socket) => this.handleConnection(socket));

    return this.io;
  }

  private static authMiddleware(socket: Socket, next: (err?: Error) => void): void {
    const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];

    if (!token) {
      return next(new Error('Authentication token required'));
    }

    try {
      const payload = JwtService.verifyAccessToken(token);
      socket.data.user = payload;
      next();
    } catch {
      next(new Error('Invalid or expired authentication token'));
    }
  }

  private static handleConnection(socket: Socket): void {
    const user = socket.data.user;
    console.log(`🔌 Client connected: ${user.userId} (Socket: ${socket.id})`);

    // Auto-join personal room for private targeted notifications
    socket.join(`user:${user.userId}`);

    socket.on('join_room', (roomId: string) => {
      socket.join(`room:${roomId}`);
      socket.to(`room:${roomId}`).emit('user_joined', { userId: user.userId });
    });

    socket.on('leave_room', (roomId: string) => {
      socket.leave(`room:${roomId}`);
    });

    socket.on('disconnect', (reason) => {
      console.log(`❌ Client disconnected: ${user.userId} (${reason})`);
    });
  }

  static getIO(): SocketIOServer {
    if (!this.io) throw new Error('WebSocketServer has not been initialized');
    return this.io;
  }

  static sendToUser(userId: string, event: string, payload: unknown): void {
    this.getIO().to(`user:${userId}`).emit(event, payload);
  }

  static broadcastToRoom(roomId: string, event: string, payload: unknown): void {
    this.getIO().to(`room:${roomId}`).emit(event, payload);
  }
}
```

---

## 2. Server Bootstrap Integration

```typescript
// src/server.ts
import http from 'http';
import app from './app';
import { WebSocketServer } from './common/websocket/socket.server';
import { env } from './config/env';

const server = http.createServer(app);

async function bootstrap() {
  await WebSocketServer.initialize(server);

  server.listen(env.PORT, () => {
    console.log(`🚀 Express server with WebSockets running on port ${env.PORT}`);
  });
}

bootstrap();
```

---

## 3. Emitting Events from Business Logic Services

```typescript
// src/modules/orders/services/order.service.ts
import { WebSocketServer } from '@/common/websocket/socket.server';

export class OrderService {
  async updateStatus(orderId: string, customerId: string, status: string): Promise<void> {
    await orderRepo.updateStatus(orderId, status);

    // 1. Notify specific customer in real-time
    WebSocketServer.sendToUser(customerId, 'order_status_updated', {
      orderId,
      status,
      timestamp: Date.now(),
    });

    // 2. Broadcast to admin live dashboard room
    WebSocketServer.broadcastToRoom('admin_orders', 'order_status_changed', {
      orderId,
      status,
    });
  }
}
```

---

**Execution Protocol**
1. **Always authenticate in the handshake**: Reject unauthorized connections before establishing persistent socket sessions.
2. **Always use Redis Adapter in production**: Allows broadcasting across load-balanced Node.js cluster pods without sticky sessions.
3. **Always structure rooms with namespaces**: Use `user:userId` for private messages, `room:roomId` for group channels.
4. **Clean up listeners on disconnect**: Avoid dangling memory references.

---
name: express-performance-scalability
description: Standards for optimizing the Node.js event loop, response compression, cluster execution setups, and configuring graceful shutdowns inside Express.js.
author: Diego Villanueva
trigger: When optimizing performance bottlenecks, resolving process timeouts, managing PM2 configurations, or designing graceful server shutdowns.
---

# Express.js Performance & Scalability Architecture

Node.js runs on a single-threaded event loop. If an Express route blocks the event loop with synchronous computation or parsing, the entire application freezes for all other concurrent users. Achieving high throughput requires non-blocking structures and structured process management.

---

## 1. Avoid Event Loop Blocking

Every synchronous file operation, cryptography execution, or massive CPU computation blocks the main thread.

**❌ NEVER** call synchronous methods like `fs.readFileSync()`, `JSON.parse()` on gigabyte payloads, or write long-running loops inside Express request handlers.
**✅ ALWAYS** use asynchronous, promise-based equivalents (like `fs.promises.readFile()`) and delegate CPU-bound work (image processing, zip extraction) to Worker Threads, queues, or external services.

```typescript
// ❌ NEVER: Blocks the single thread, halting all incoming request execution
import fs from 'fs';
app.get('/data', (req, res) => {
  const data = fs.readFileSync('./huge-log.txt', 'utf8'); // Blocks!
  res.send(data);
});

// ✅ ALWAYS: Use non-blocking async IO streams or promises
import fs from 'fs/promises';
app.get('/data', async (req, res, next) => {
  try {
    const data = await fs.readFile('./huge-log.txt', 'utf8'); // Non-blocking
    res.send(data);
  } catch (error) {
    next(error);
  }
});
```

---

## 2. Response Compression

Compressing response payloads reduces latency and network bandwidth usage for users.

**❌ NEVER** transmit uncompressed HTML/JSON assets to production users from the Node layer directly without compression rules.
**✅ ALWAYS** register the `compression` middleware early to automatically compress payloads (Brotli or Gzip).

```typescript
// ✅ ALWAYS: Compress responses early in the request lifecycle
import express from 'express';
import compression from 'compression';

const app = express();

app.use(compression({
  filter: (req, res) => {
    if (req.headers['x-no-compression']) return false;
    return compression.filter(req, res);
  },
  threshold: 1024 // Only compress responses larger than 1KB
}));
```

---

## 3. Clustered execution & PM2

To scale horizontally on multi-core servers, configure multiple Node.js processes sharing the same port.

**❌ NEVER** run a single Node process inside high-resource production environments without clustering tools.
**✅ ALWAYS** use process managers like **PM2** in cluster mode, or build on top of Docker orchestrations (Kubernetes).

```javascript
// ecosystem.config.js (PM2 Config)
module.exports = {
  apps: [
    {
      name: 'express-enterprise-api',
      script: './dist/server.js',
      instances: 'max', // Instantiate one process per CPU Core
      exec_mode: 'cluster', // Enables clustering out-of-the-box
      env_production: {
        NODE_ENV: 'production',
      },
    },
  ],
};
```

---

## 4. Complete Graceful Shutdown Protocol

During deployment rollouts or autoscaling, Express processes terminate. Active requests must complete processing before the server exits.

**❌ NEVER** force immediate exits on signal detection using raw `process.exit(0)`, cutting off open requests mid-flight.
**✅ ALWAYS** stop accepting new requests, finalize active client requests, close database sockets, and then shutdown safely.

```typescript
// server.ts
import { app } from './app';

const server = app.listen(3000);

const handleGracefulExit = () => {
  console.log('Received shutdown signal. Commencing graceful termination...');

  // Stop accepting new connections
  server.close(async (err) => {
    if (err) {
      console.error('Error closing the Express listener:', err);
      process.exit(1);
    }
    
    try {
      // 1. Close open resources (db pool, redis connections)
      // await db.disconnect();
      console.log('Cleanup completed. Exiting process safely.');
      process.exit(0);
    } catch (dbError) {
      console.error('Error during cleanup:', dbError);
      process.exit(1);
    }
  });

  // Force close after timeout boundary (e.g., 30s)
  setTimeout(() => {
    console.error('Force shutting down due to pending operations.');
    process.exit(1);
  }, 30000);
};

process.on('SIGTERM', handleGracefulExit);
process.on('SIGINT', handleGracefulExit);
```

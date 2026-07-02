---
name: nestjs-queue-architect
description: The ultimate architectural standard for Distributed Background Jobs in NestJS using BullMQ, Redis, Sandboxed Processors, and Dead Letter Queues.
author: Diego Villanueva
trigger: When configuring background tasks, heavy data processing, email sending, cron jobs, or asynchronous queues.
---

# NestJS Queue Architecture (BullMQ)

In an Enterprise architecture, the HTTP response must be returned in less than 200ms. If a user uploads a CSV of 10,000 users, you do NOT process it in the HTTP controller. You offload it to a distributed queue.

NestJS integrates perfectly with **BullMQ** (backed by Redis) for rock-solid background job processing.

## 1. The Payload Rule (CRITICAL)

Redis is an in-memory database. If you pass large objects (like a Base64 string of a PDF, or an array of 5,000 user objects) into the Queue Payload, you will crash Redis with Out Of Memory (OOM) errors.

**Rule**: Pass IDs, not Data.

```typescript
// ❌ ATROCIOUS: Sending raw heavy data into Redis
await this.emailQueue.add('sendWelcome', { user: userObjectWithNestedRelations });

// ✅ ALWAYS: Send references, let the worker fetch the data
await this.emailQueue.add('sendWelcome', { userId: user.id });
```

## 2. Producers (Adding Jobs)

Producers are responsible for dispatching jobs to the queue. Always configure strict retry mechanisms. Networks will fail, external APIs will rate-limit you. 

```typescript
// ✅ ALWAYS: Configure Exponential Backoff for retries
import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';

@Injectable()
export class ReportProducer {
  constructor(@InjectQueue('reports-queue') private reportQueue: Queue) {}

  async triggerMonthlyReport(tenantId: string) {
    await this.reportQueue.add(
      'generate-pdf',
      { tenantId },
      {
        attempts: 5, // Try up to 5 times
        backoff: {
          type: 'exponential',
          delay: 2000, // Wait 2s, then 4s, then 8s...
        },
        removeOnComplete: true, // Don't bloat Redis with successful job metadata
        removeOnFail: false,    // Keep failed jobs for the Dead Letter Queue
      }
    );
  }
}
```

## 3. Consumers / Processors (Handling Jobs)

Processors execute the heavy lifting. In BullMQ for NestJS, you define a `@Processor` class.

```typescript
// ✅ ALWAYS: Isolate business logic inside the Processor
import { Processor, WorkerHost, OnWorkerEvent } from '@nestjs/bullmq';
import { Job } from 'bullmq';

@Processor('reports-queue')
export class ReportProcessor extends WorkerHost {
  constructor(private readonly reportService: ReportService) {
    super();
  }

  // This is the method that BullMQ calls
  async process(job: Job<{ tenantId: string }, any, string>): Promise<string> {
    const { tenantId } = job.data;
    
    // Update progress (useful for WebSockets UI)
    await job.updateProgress(10);
    
    const pdfUrl = await this.reportService.generatePdf(tenantId);
    
    await job.updateProgress(100);
    return pdfUrl; // The result is saved in Redis
  }

  // ✅ ALWAYS: Handle Failures Explicitly (Dead Letter Concept)
  @OnWorkerEvent('failed')
  onFailed(job: Job, error: Error) {
    console.error(`Job ${job.id} failed after ${job.attemptsMade} attempts:`, error);
    // Trigger PagerDuty / Sentry Alert here!
  }
}
```

## 4. Architectural Scaling (Sandboxed Processors vs Worker Apps)

If a Processor performs CPU-heavy tasks (like image resizing or massive array mapping), it will block the Node.js Event Loop. This means your API will stop responding to HTTP requests while the queue processes.

To scale, you have two options:

### Option A: Sandboxed Processors (Child Processes)
You can instruct BullMQ to run the processor in a separate Node.js thread. However, you lose NestJS Dependency Injection.

### Option B: The Worker Microservice (The Enterprise Standard)
Instead of running Processors in the same NestJS app that handles HTTP traffic, you deploy a completely separate NestJS application (a "Worker") that ONLY listens to Redis.

```typescript
// ✅ ALWAYS: Separate API nodes from Worker nodes at scale
// In your API App:
@Module({
  imports: [BullModule.registerQueue({ name: 'reports-queue' })],
  providers: [ReportProducer], // ONLY PRODUCERS
})
export class ApiModule {}

// In your Worker App (Deployed on a different AWS EC2 / K8s Pod):
@Module({
  imports: [BullModule.registerQueue({ name: 'reports-queue' })],
  providers: [ReportProcessor], // ONLY CONSUMERS
})
export class WorkerModule {}
```

## 5. Cron Jobs (Repeatable Jobs)

NestJS has a built-in `@nestjs/schedule` module. Do **NOT** use it if you are running multiple instances of your app (e.g., 3 pods in Kubernetes). If you use `@Cron()`, all 3 pods will fire the cron job at exactly the same time, duplicating the work!

For distributed systems, you MUST use BullMQ repeatable jobs, as Redis will guarantee that the cron job is only assigned to exactly one worker.

```typescript
// ✅ ALWAYS: Use BullMQ for Distributed Cron Jobs
await this.reportQueue.add(
  'weekly-sync',
  {},
  {
    repeat: {
      pattern: '0 0 * * 0', // Every Sunday at midnight
    },
  }
);
```

---

**Execution Protocol**
1. **Never use `Bull` (v3)**: The legacy `@nestjs/bull` package is based on an outdated library. You must exclusively use `@nestjs/bullmq` (BullMQ v4/v5) which is actively maintained and supports advanced flow structures.
2. **Idempotency**: Your processors MUST be idempotent. If the network drops *after* the processor finishes but *before* Redis acknowledges the success, BullMQ might retry the job. If the job sends an email, make sure you don't send it twice (check the DB first).
3. **Queue Board**: Always deploy a UI dashboard like `bull-board` (protected by Basic Auth) to inspect the Redis queues, manually retry failed jobs, and monitor processing speed.

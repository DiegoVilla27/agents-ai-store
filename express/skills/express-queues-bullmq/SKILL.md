---
name: express-queues-bullmq
description: The ultimate architectural standard for Background Processing in Express.js with BullMQ, Redis Queues, Worker Sandboxes, Exponential Retries, and Dead Letter Queues (DLQ).
author: Diego Villanueva
trigger: When offloading heavy tasks, sending async emails/notifications, processing reports, managing background queues with BullMQ, or handling failed job retries.
---

# Enterprise Express.js Background Processing (BullMQ & Redis)

Synchronous HTTP requests must respond in under 200ms. Operations that take longer (generating PDF invoices, sending transactional emails, video transcoding, heavy data syncs) MUST be offloaded to **Background Workers** using **BullMQ** and **Redis**.

---

## 1. Queue Configuration & Job Definition

```bash
npm install bullmq ioredis
```

```typescript
// src/common/queues/email.queue.ts
import { Queue, QueueOptions } from 'bullmq';
import { env } from '@/config/env';

const queueOptions: QueueOptions = {
  connection: {
    host: env.REDIS_HOST,
    port: env.REDIS_PORT,
    password: env.REDIS_PASSWORD,
  },
  defaultJobOptions: {
    attempts: 5,
    backoff: {
      type: 'exponential',
      delay: 2000, // 2s, 4s, 8s, 16s...
    },
    removeOnComplete: {
      age: 24 * 3600, // keep completed jobs up to 24h
      count: 1000,
    },
    removeOnFail: {
      age: 7 * 24 * 3600, // keep failed jobs up to 7 days for DLQ inspection
    },
  },
};

export interface EmailJobData {
  to: string;
  templateId: string;
  variables: Record<string, unknown>;
}

export const emailQueue = new Queue<EmailJobData>('email-queue', queueOptions);
```

---

## 2. Worker Implementation & Job Processing

```typescript
// src/workers/email.worker.ts
import { Worker, Job } from 'bullmq';
import { EmailJobData } from '../common/queues/email.queue';
import { emailService } from '../modules/notifications/services/email.service';
import { env } from '@/config/env';

export const emailWorker = new Worker<EmailJobData>(
  'email-queue',
  async (job: Job<EmailJobData>) => {
    console.log(`[Worker] Processing email job #${job.id} for: ${job.data.to}`);

    // Execute the actual email sending operation
    await emailService.sendTemplateEmail({
      to: job.data.to,
      templateId: job.data.templateId,
      variables: job.data.variables,
    });

    return { deliveredAt: new Date().toISOString() };
  },
  {
    connection: {
      host: env.REDIS_HOST,
      port: env.REDIS_PORT,
      password: env.REDIS_PASSWORD,
    },
    concurrency: 10, // Process 10 jobs concurrently per worker instance
  }
);

// Worker Lifecycle Listeners
emailWorker.on('completed', (job: Job) => {
  console.log(`✅ [Worker] Email job #${job.id} completed successfully`);
});

emailWorker.on('failed', (job: Job | undefined, err: Error) => {
  console.error(`❌ [Worker] Email job #${job?.id} failed on attempt ${job?.attemptsMade}:`, err.message);
  
  if (job && job.attemptsMade >= (job.opts.attempts || 5)) {
    console.error(`🚨 [DLQ Alert] Job #${job.id} permanently failed and moved to DLQ`);
    // Send alert to PagerDuty/Slack
  }
});
```

---

## 3. Offloading Jobs from Express Controllers

```typescript
// src/modules/auth/controllers/register.controller.ts
import { Request, Response } from 'express';
import { emailQueue } from '@/common/queues/email.queue';

export class RegisterController {
  async register(req: Request, res: Response): Promise<void> {
    const { email, name, password } = req.body;

    const user = await userService.createUser({ email, name, password });

    // Enqueue verification email asynchronously (0ms latency for client!)
    await emailQueue.add('send-welcome-email', {
      to: user.email,
      templateId: 'WELCOME_VERIFY_EMAIL',
      variables: { name: user.name, token: user.verificationToken },
    }, {
      priority: 1, // High priority
    });

    // Immediate 201 Created response
    res.status(201).json({
      success: true,
      message: 'Account created. Verification email sent in background.',
      userId: user.id,
    });
  }
}
```

---

## 4. Recurring Scheduled Jobs (Cron)

```typescript
// Schedule nightly database cleanup job every day at 02:00 AM
export async function scheduleNightlyCleanup(): Promise<void> {
  await maintenanceQueue.add(
    'nightly-cleanup',
    {},
    {
      repeat: {
        pattern: '0 2 * * *', // Standard 5-field cron pattern
      },
    }
  );
}
```

---

**Execution Protocol**
1. **Always configure exponential backoff**: Protects external APIs from being overwhelmed during outages.
2. **Set appropriate worker concurrency**: Balance concurrency with database connection pool limits (`concurrency: 5-20`).
3. **Keep payload lightweight**: Pass entity IDs and references in job data rather than giant 10MB JSON payloads.
4. **Graceful worker shutdown**: Always listen to `SIGTERM` and call `await worker.close()` to finish active jobs before container termination.

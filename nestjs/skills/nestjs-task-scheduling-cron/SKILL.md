---
name: nestjs-task-scheduling-cron
description: The ultimate architectural standard for Distributed Task Scheduling and Cron Jobs in NestJS with @nestjs/schedule, Dynamic Intervals, and Redis Leader Election.
author: Diego Villanueva
trigger: When configuring cron jobs in NestJS, running scheduled maintenance tasks, managing dynamic timeouts, or preventing duplicate cron execution across clustered instances with Redis leader locks.
---

# Enterprise NestJS Task Scheduling & Distributed Cron Architecture

Cron jobs in enterprise microservice deployments face a critical pitfall: when 5 container replicas run the same app, **scheduled tasks trigger 5 times simultaneously** (causing duplicate billing charges, emails, and database race conditions). A Principal Architect enforces **Distributed Leader Election & Cron Locks** via Redis.

---

## 1. Schedule Module Setup (`@nestjs/schedule`)

```bash
npm install @nestjs/schedule
```

```typescript
// src/app.module.ts
import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    // ...
  ],
})
export class AppModule {}
```

---

## 2. Distributed Cron Execution with Redis Lock

```typescript
// src/modules/maintenance/tasks/cleanup.task.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DistributedLockService } from '@/common/locks/distributed-lock.service';
import { CleanupService } from '../services/cleanup.service';

@Injectable()
export class SystemCleanupTask {
  private readonly logger = new Logger(SystemCleanupTask.name);

  constructor(
    private readonly lockService: DistributedLockService,
    private readonly cleanupService: CleanupService
  ) {}

  // Run nightly at 03:00 AM UTC
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async handleNightlyCleanup() {
    this.logger.log('Attempting nightly system cleanup...');

    try {
      // Acquire distributed cluster lock: Only 1 instance out of N replicas executes this!
      await this.lockService.withLock('cron:nightly_cleanup', 60 * 1000, async () => {
        this.logger.log('🔒 Lock acquired. Executing cleanup...');
        await this.cleanupService.purgeExpiredSessions();
        await this.cleanupService.archiveOldAuditLogs();
        this.logger.log('✅ Nightly cleanup finished successfully.');
      });
    } catch (error: any) {
      if (error.name === 'LockAcquisitionError') {
        this.logger.log('ℹ️ Another replica is already executing the cleanup task. Skipping.');
      } else {
        this.logger.error('❌ Error during system cleanup:', error);
      }
    }
  }
}
```

---

## 3. Dynamic Interval & Timeout Scheduling

```typescript
// src/modules/reports/services/dynamic-scheduler.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { SchedulerRegistry } from '@nestjs/schedule';

@Injectable()
export class DynamicSchedulerService {
  private readonly logger = new Logger(DynamicSchedulerService.name);

  constructor(private readonly schedulerRegistry: SchedulerRegistry) {}

  scheduleOneTimeJob(jobName: string, executeAt: Date, callback: () => void) {
    const delay = executeAt.getTime() - Date.now();
    if (delay <= 0) return;

    const timeout = setTimeout(() => {
      this.logger.log(`Executing dynamic one-time job: ${jobName}`);
      callback();
      this.schedulerRegistry.deleteTimeout(jobName);
    }, delay);

    this.schedulerRegistry.addTimeout(jobName, timeout);
  }

  cancelJob(jobName: string) {
    if (this.schedulerRegistry.doesExist('timeout', jobName)) {
      this.schedulerRegistry.deleteTimeout(jobName);
      this.logger.log(`Cancelled job: ${jobName}`);
    }
  }
}
```

---

**Execution Protocol**
1. **Never run uncoordinated `@Cron` in multi-replica Kubernetes environments**: Always wrap execution with a distributed Redis lock.
2. **Set generous lock TTLs with safety buffers**: Ensure TTL exceeds max expected execution duration.
3. **Always log start, end, and duration metrics**: Export cron execution results to Prometheus / OpenTelemetry.

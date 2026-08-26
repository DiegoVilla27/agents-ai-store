---
name: spring-boot-virtual-threads-loom
description: The ultimate architectural standard for Java 21 Project Loom Virtual Threads in Spring Boot 3.x, High-Concurrency Non-Blocking I/O, Structured Concurrency, and Thread-Pinning Elimination.
author: Diego Villanueva
trigger: When configuring Virtual Threads in Spring Boot 3.x, optimizing thread pools for Java 21, eliminating thread-pinning with ReentrantLock, or handling high-concurrency blocking I/O.
---

# Enterprise Spring Boot Virtual Threads (Project Loom & Java 21)

Java 21 and Spring Boot 3.2+ introduced **Virtual Threads (Project Loom)**, revolutionizing Java concurrency. Instead of mapping one Java thread to one expensive OS platform thread (~1MB memory, limited to ~5,000 threads), the JVM manages millions of lightweight Virtual Threads (~1KB memory) that unmount automatically during blocking I/O (database queries, HTTP calls, file I/O).

---

## 1. Enabling Virtual Threads in Spring Boot 3.2+

With a single configuration property, Tomcat and Spring MVC dispatch every incoming HTTP request onto an ephemeral Virtual Thread:

```properties
# application.properties
spring.threads.virtual.enabled=true
```

```yaml
# application.yml
spring:
  threads:
    virtual:
      enabled: true
```

---

## 2. Preventing Thread-Pinning (The `synchronized` Trap)

**❌ NEVER** use the `synchronized` keyword inside code paths executed by Virtual Threads when performing blocking I/O. It "pins" the virtual thread to its underlying OS carrier thread, preventing other virtual threads from executing and causing thread starvation.
**✅ ALWAYS** replace `synchronized` blocks with **`java.util.concurrent.locks.ReentrantLock`**.

```java
// ❌ WRONG: Pinned carrier thread during blocking database / network call!
public class LegacyCacheService {
    public synchronized String getOrFetch(String key) {
        // Calling remote network or DB while holding synchronized monitor pins thread!
        return remoteApiClient.fetch(key); 
    }
}

// ✅ ALWAYS: ReentrantLock unmounts cleanly on Virtual Threads
import java.util.concurrent.locks.ReentrantLock;

@Service
public class EnterpriseVirtualThreadCacheService {
    private final ReentrantLock lock = new ReentrantLock();

    public String getOrFetch(String key) {
        lock.lock();
        try {
            // Virtual thread yields carrier thread during blocking I/O!
            return remoteApiClient.fetch(key);
        } finally {
            lock.unlock();
        }
    }
}
```

---

## 3. Asynchronous Task Execution with Virtual Threads

```java
// config/AsyncVirtualThreadConfig.java
package com.enterprise.app.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.AsyncTaskExecutor;
import org.springframework.core.task.support.TaskExecutorAdapter;

import java.util.concurrent.Executors;

@Configuration
@ConditionalOnProperty(name = "spring.threads.virtual.enabled", havingValue = "true")
public class AsyncVirtualThreadConfig {

    @Bean(name = "applicationTaskExecutor")
    public AsyncTaskExecutor applicationTaskExecutor() {
        // Dispatches @Async tasks to an unbounded Virtual Thread executor
        return new TaskExecutorAdapter(Executors.newVirtualThreadPerTaskExecutor());
    }
}
```

---

## 4. Structured Concurrency (Java 21 Preview / Scoped Tasks)

When fetching multiple independent external resources concurrently in a single HTTP request:

```java
// service/DashboardAggregatorService.java
package com.enterprise.app.service;

import org.springframework.stereotype.Service;
import java.util.concurrent.StructuredTaskScope;

@Service
public class DashboardAggregatorService {

    public DashboardData aggregateUserData(String userId) {
        try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
            // Fork independent virtual threads concurrently
            var userSubtask = scope.fork(() -> userService.findUser(userId));
            var ordersSubtask = scope.fork(() -> orderService.findOrders(userId));
            var creditSubtask = scope.fork(() -> creditService.getCreditScore(userId));

            // Await all subtasks (Fails fast if any single subtask throws exception)
            scope.join().throwIfFailed();

            // All tasks finished successfully in parallel!
            return new DashboardData(
                userSubtask.get(),
                ordersSubtask.get(),
                creditSubtask.get()
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to aggregate dashboard data", e);
        }
    }
}
```

---

**Execution Protocol**
1. **Enable `spring.threads.virtual.enabled=true`**: Eliminates reactive programming complexity (WebFlux) for 95% of standard CRUD and I/O workloads.
2. **Never pool Virtual Threads**: Virtual Threads are cheap and disposable. Always create new ones via `Executors.newVirtualThreadPerTaskExecutor()`.
3. **Audit dependencies for Thread-Pinning with JVM flags**:
   ```bash
   -Djdk.tracePinnedThreads=full
   ```
4. **Tune Database Connection Pools (HikariCP)**: Virtual threads do NOT increase database capacity; ensure HikariCP `maximum-pool-size` matches database hardware capabilities.

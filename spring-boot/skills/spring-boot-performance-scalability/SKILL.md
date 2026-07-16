---
name: spring-boot-performance-scalability
description: JVM performance optimization standards, HikariCP database pool tuning, Project Loom Virtual Threads integration, and configuration of graceful process shutdown.
author: Diego Villanueva
trigger: When optimizing memory settings, tuning HikariCP pools, enabling Java 21 Virtual Threads, or configuring server shutdown policies.
---

# Spring Boot Performance & Scalability Architecture

Scaling JVM-based Spring Boot applications requires optimized garbage collection, connection pool sizing, asynchronous thread scheduling, and modern concurrency features like Virtual Threads.

---

## 1. Java 21 Virtual Threads (Project Loom)

In Spring Boot 3.2+ running on Java 21, you can enable Virtual Threads to handle blocking web requests. Instead of allocating one heavy operating system thread per connection (which caps concurrency at a few hundred requests), Virtual Threads execute thousands of concurrent tasks on a tiny pool of carrier threads.

**❌ NEVER** configure heavy custom thread pools for simple asynchronous tasks in Spring Boot 3.2+ on Java 21.
**✅ ALWAYS** enable Virtual Threads globally to handle HTTP requests and task scheduling.

```yaml
# application.yml
spring:
  threads:
    virtual:
      enabled: true # ✅ ALWAYS: Enables Project Loom virtual threads out-of-the-box
```

---

## 2. HikariCP Connection Pool Optimization

HikariCP is the default database connection pool. Incorrect pool sizing defaults lead to threads blocking while waiting for database slots, or overloading database servers with idle connections.

**❌ NEVER** leave `minimum-idle` and `maximum-pool-size` to default values without analyzing database workload metrics.
**✅ ALWAYS** tune connection pool sizes based on peak active thread calculations, and activate leak detection configurations.

```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20 # Maximum concurrent connections
      minimum-idle: 10 # Retain hot idle connections
      idle-timeout: 300000 # 5 minutes
      max-lifetime: 1800000 # 30 minutes
      connection-timeout: 20000 # 20 seconds to wait for a connection
      leak-detection-threshold: 2000 // Report connections checked out for >2s (leak detection)
```

---

## 3. Production Graceful Shutdown Configuration

By default, when Spring Boot receives a termination signal (`SIGTERM`), it stops immediately, terminating active database transactions and cutting off clients mid-request.

**❌ NEVER** let Spring Boot exit immediately in production rollouts without a graceful connection-draining delay.
**✅ ALWAYS** configure graceful web server shutdown and declare appropriate phase timeouts.

```yaml
# application.yml
server:
  shutdown: graceful # ✅ ALWAYS: Drains active requests before closing the port

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s # ✅ ALWAYS: Limit the shutdown wait time boundary
```

---

## 4. JVM Tuning Recommendations

Configure these runtime environment flags inside Dockerfiles or deployment configurations to prevent memory errors and optimize garbage collection:

- **Heap Alignment**: Use `-XX:+UseContainerSupport` so the JVM respects Docker resource limits. Enforce heap constraints using `-XX:InitialRAMPercentage=70.0` and `-XX:MaxRAMPercentage=70.0`.
- **Garbage Collection**: Use G1GC (enabled by default in modern JDKs) with `-XX:+UseG1GC` to prevent long stop-the-world application pauses.

---
name: spring-boot-reactive-webflux
description: Guidelines for building reactive systems using Spring WebFlux, Project Reactor pipelines (Mono/Flux), thread mappings, and reactive database repository drivers (R2DBC).
author: Diego Villanueva
trigger: When configuring Spring WebFlux routes, designing reactive endpoints, working with Mono/Flux operators, or setting up R2DBC databases.
---

# Spring Boot Reactive WebFlux & Project Reactor

Spring WebFlux provides a reactive, non-blocking stack designed to scale with a small number of thread execution loops (Netty). Working with WebFlux requires moving away from imperative paradigms towards asynchronous event streams using Project Reactor (`Mono` and `Flux`).

---

## 1. Zero Blocking Calls in Reactive Chains

Calling blocking operations (like database JPA queries, Thread.sleep, or synchronous HTTP clients) inside the WebFlux processing thread pool locks Netty event loops, freezing the entire application.

**❌ NEVER** call `.block()` or `.blockOptional()` inside WebFlux routes, controllers, or reactive pipelines.
**❌ NEVER** mix blocking JPA/JDBC database calls inside default reactive pipelines.

**✅ ALWAYS** resolve streams asynchronously using operators like `flatMap` or `zip`, and delegate blocking legacy APIs to a separate elastic thread pool.

```java
// ❌ NEVER: Blocks the thread execution loop, crashing performance
@GetMapping("/users/{id}")
public UserDTO getUser(@PathVariable UUID id) {
    User user = userService.findById(id).block(); // CRITICAL BUG!
    return UserMapper.toDTO(user);
}

// ✅ ALWAYS: Return a clean Mono, letting WebFlux subscribe asynchronously
@GetMapping("/users/{id}")
public Mono<ResponseEntity<UserDTO>> getUser(@PathVariable UUID id) {
    return userService.findById(id)
        .map(UserMapper::toDTO)
        .map(ResponseEntity::ok)
        .defaultIfEmpty(ResponseEntity.notFound().build());
}
```

---

## 2. Isolating Blocking APIs (Schedulers)

When you must call blocking legacy libraries (such as JDBC, JPA, or synchronous HTTP clients) inside a reactive flow, isolate them.

**✅ ALWAYS** wrap blocking code inside `Mono.fromCallable` or `Mono.fromRunnable` and schedule it on `Schedulers.boundedElastic()`.

```java
// ✅ ALWAYS: Move blocking work off the Netty event loop
public Mono<UserDTO> getLegacyUserData(UUID id) {
    return Mono.fromCallable(() -> legacyHttpClient.getUserData(id)) // Synchronous blocking call
        .subscribeOn(Schedulers.boundedElastic()); // Execute on isolated thread pool
}
```

---

## 3. Correct Stream Operator Selection

Project Reactor chains are lazy. Nothing happens until you subscribe (which WebFlux does automatically under the hood). Use appropriate operators to handle concurrency and transformation:

- **`map`**: Use for simple synchronous transformations of data values (e.g. `User -> UserDTO`).
- **`flatMap`**: Use for asynchronous transformations that return another `Publisher` (e.g. database calls or external HTTP requests).
- **`zip`**: Use to run multiple asynchronous operations in parallel and combine their results.

```java
// ✅ ALWAYS: Use zip to run parallel asynchronous fetches
public Mono<DashboardDTO> getDashboardData(UUID userId) {
    Mono<Profile> profileMono = profileService.getProfile(userId);
    Mono<List<Order>> ordersMono = orderService.getOrders(userId).collectList();

    return Mono.zip(profileMono, ordersMono)
        .map(tuple -> new DashboardDTO(tuple.getT1(), tuple.getT2()));
}
```

---

## 4. Reactive Persistence (R2DBC)

When building reactive APIs, use **R2DBC (Reactive Relational Database Connectivity)** instead of standard JDBC. R2DBC provides fully non-blocking database queries supporting PostgreSQL, MySQL, and SQL Server.

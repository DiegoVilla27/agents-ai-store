---
name: spring-boot-data-jpa
description: Spring Data JPA pattern designs, entity relationships, query optimizations, `@Transactional` boundaries, and N+1 query troubleshooting.
author: Diego Villanueva
trigger: When building JPA Entity models, writing custom Repository queries, optimizing database performance, or configuring Transaction propagation levels.
---

# Spring Boot Data JPA & Query Optimization

Spring Data JPA makes database access simple using repositories. However, misconfigured transaction scopes, unoptimized queries, or default configurations (like OSIV) easily lead to N+1 select problems, query locking, and database connection pool exhaustion.

---

## 1. Disable Open Session in View (OSIV)

By default, Spring Boot keeps the Hibernate session open until the HTTP response is fully rendered (`spring.jpa.open-in-view=true`). This allows lazy loading of relations during JSON serialization but holds database connections open for too long, causing pool exhaustion.

**❌ NEVER** run production Spring Boot applications with `spring.jpa.open-in-view` set to `true`.
**✅ ALWAYS** disable OSIV in configuration files and fetch all necessary relations explicitly at the repository layer.

```yaml
# application.yml
spring:
  jpa:
    open-in-view: false # ✅ ALWAYS: Disable OSIV to return connections to the pool instantly
```

---

## 2. Eliminate the N+1 Query Problem

Accessing lazy-loaded relationships on collections of entities triggers separate SELECT queries for every record in the list.

**❌ NEVER** load lazy associations inside loops or allow JSON serializers to trigger lazy fetching.
**✅ ALWAYS** fetch relationships in a single database query using `@EntityGraph` or custom `JOIN FETCH` JPQL definitions.

```java
public interface OrderRepository extends JpaRepository<OrderJPAEntity, UUID> {

    // ❌ NEVER: Triggers 1 SELECT query for orders + N separate SELECT queries for users
    List<OrderJPAEntity> findAll();

    // ✅ ALWAYS: Fetches orders and users in a single SQL JOIN query
    @Query("SELECT o FROM OrderJPAEntity o JOIN FETCH o.user")
    List<OrderJPAEntity> findAllWithUserFetched();

    // ✅ ALTERNATIVE: Use declarative Entity Graph settings
    @EntityGraph(attributePaths = {"items", "customer"})
    Optional<OrderJPAEntity> findWithDetailsById(UUID id);
}
```

---

## 3. Transaction Boundary Management

Use `@Transactional` to define atomic execution boundaries.

**❌ NEVER** declare `@Transactional` on public controller methods or place write transactions on read-only endpoints.
**✅ ALWAYS** mark read-only methods with `@Transactional(readOnly = true)` (which allows Hibernate to disable dirty check processing and optimize memory performance).

```java
@Service
@RequiredArgsConstructor
public class AccountService {

    private final AccountRepository repository;

    @Transactional(readOnly = true) // ✅ ALWAYS: Optimizes performance for query methods
    public AccountDTO findAccount(UUID id) {
        return repository.findById(id)
            .map(AccountMapper::toDTO)
            .orElseThrow(() -> new EntityNotFoundException("Account not found"));
    }

    @Transactional // ✅ ALWAYS: Explicit write transaction scope
    public void transferFunds(UUID fromId, UUID toId, BigDecimal amount) {
        // Business operations
    }
}
```

---

## 4. Query Pagination Standards

Retrieving complete tables using `findAll()` crashes processes when datasets grow.

1. **Parameters**: Always accept a `Pageable` payload inside repository methods.
2. **Page vs. Slice**: Return `Page<T>` only if total count values are required (requires an extra SELECT COUNT query). Return `Slice<T>` or `List<T>` for infinite scrolls or performance-critical APIs to skip counts.

```java
// ✅ ALWAYS: Use Slice for high-performance scroll pages
Slice<UserJPAEntity> findByStatus(String status, Pageable pageable);
```

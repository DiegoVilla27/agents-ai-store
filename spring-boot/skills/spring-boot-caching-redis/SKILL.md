---
name: spring-boot-caching-redis
description: The ultimate architectural standard for Distributed Caching in Spring Boot 3.x with Redis, @Cacheable, CacheManager TTL configs, and Distributed Locks with Redisson.
author: Diego Villanueva
trigger: When configuring caching in Spring Boot 3.x, setting up Redis CacheManager with explicit TTLs, using @Cacheable / @CacheEvict, or acquiring distributed locks with Redisson.
---

# Enterprise Spring Boot Redis Caching & Redisson Architecture

High-throughput distributed enterprise backends require **Multi-Tier Distributed Caching** with Redis to protect databases from stampedes, combined with **Redisson Distributed Locks** to guarantee atomic mutations across Kubernetes clusters.

---

## 1. Dependencies Setup

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson-spring-boot-starter</artifactId>
    <version>3.35.0</version>
</dependency>
```

---

## 2. Redis CacheManager Configuration with Explicit TTLs

**❌ NEVER** use a single global TTL for all cached data.
**✅ ALWAYS** configure custom per-cache TTL policies (e.g. Products = 1 hour, Currency Rates = 1 minute).

```java
// config/RedisCacheConfig.java
package com.enterprise.app.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableCaching
public class RedisCacheConfig {

    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        // Default base configuration (JSON Serialization)
        RedisCacheConfiguration defaultConfig = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(10))
            .disableCachingNullValues()
            .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(new GenericJackson2JsonRedisSerializer()));

        // Custom TTL policies per cache name
        Map<String, RedisCacheConfiguration> cacheConfigs = new HashMap<>();
        cacheConfigs.put("products", defaultConfig.entryTtl(Duration.ofHours(1)));
        cacheConfigs.put("exchange_rates", defaultConfig.entryTtl(Duration.ofMinutes(1)));
        cacheConfigs.put("user_sessions", defaultConfig.entryTtl(Duration.ofDays(7)));

        return RedisCacheManager.builder(connectionFactory)
            .cacheDefaults(defaultConfig)
            .withInitialCacheConfigurations(cacheConfigs)
            .build();
    }
}
```

---

## 3. Declarative Caching with `@Cacheable` and `@CacheEvict`

```java
// service/ProductService.java
package com.enterprise.app.product.service;

import com.enterprise.app.product.dto.ProductResponse;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class ProductService {

    // 1. Read through cache (Only calls DB on cache miss!)
    @Cacheable(value = "products", key = "#id", unless = "#result == null")
    public ProductResponse getProductById(String id) {
        return productRepository.findById(id)
            .map(productMapper::toResponse)
            .orElse(null);
    }

    // 2. Invalidate cache upon update
    @CacheEvict(value = "products", key = "#id")
    public void updateProduct(String id, UpdateProductRequest request) {
        productRepository.update(id, request);
    }

    // 3. Bulk eviction on catalog flush
    @CacheEvict(value = "products", allEntries = true)
    public void evictAllProducts() {
        // Purges all 'products::*' keys from Redis
    }
}
```

---

## 4. Distributed Locks with Redisson (Preventing Race Conditions)

When performing atomic balance deductions or inventory reservations across multiple Spring Boot instances:

```java
// service/InventoryReservationService.java
package com.enterprise.app.inventory.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class InventoryReservationService {

    private final RedissonClient redissonClient;
    private final InventoryRepository inventoryRepository;

    public boolean reserveStock(String productId, int quantity) {
        String lockKey = "lock:inventory:" + productId;
        RLock lock = redissonClient.getLock(lockKey);

        try {
            // Wait up to 5s to acquire lock; hold for max 10s before auto-release
            boolean acquired = lock.tryLock(5, 10, TimeUnit.SECONDS);
            if (!acquired) {
                log.warn("Could not acquire lock for product stock: {}", productId);
                return false;
            }

            // CRITICAL SECTION (Guaranteed single-threaded across the entire cluster)
            int currentStock = inventoryRepository.getStock(productId);
            if (currentStock < quantity) {
                return false;
            }

            inventoryRepository.decrementStock(productId, quantity);
            return true;

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        } finally {
            if (lock.isHeldByCurrentThread()) {
                lock.unlock();
            }
        }
    }
}
```

---

**Execution Protocol**
1. **Always use JSON serialization (`GenericJackson2JsonRedisSerializer`)**: Avoid Java native serialization (`JdkSerializationRedisSerializer`) due to security vulnerabilities.
2. **Never allow unbounded cache growth**: Always specify `entryTtl`.
3. **Use Redisson for distributed locks**: Avoid rolling manual `SETNX` commands.

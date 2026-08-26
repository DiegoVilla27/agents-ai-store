---
name: spring-boot-database-multitenancy
description: The ultimate architectural standard for Enterprise Multi-Tenancy in Spring Boot 3.x with AbstractRoutingDataSource, Schema-per-tenant isolation, and TenantContext propagation.
author: Diego Villanueva
trigger: When implementing multi-tenant architectures in Spring Boot, configuring dynamic database routing with AbstractRoutingDataSource, or isolating tenant schemas in Hibernate/JPA.
---

# Enterprise Spring Boot Database Multi-Tenancy Architecture

In Enterprise B2B SaaS applications, strict tenant isolation is required for security and regulatory compliance. In Spring Boot 3.x, **`AbstractRoutingDataSource`** and **Hibernate Multi-Tenancy** dynamically route database connections per request without recreating application contexts.

---

## 1. ThreadLocal Tenant Context

```java
// multitenancy/TenantContext.java
package com.enterprise.app.multitenancy;

public final class TenantContext {
    private static final ThreadLocal<String> CURRENT_TENANT = new ThreadLocal<>();

    private TenantContext() {}

    public static void setTenantId(String tenantId) {
        CURRENT_TENANT.set(tenantId);
    }

    public static String getTenantId() {
        return CURRENT_TENANT.get();
    }

    public static void clear() {
        CURRENT_TENANT.remove();
    }
}
```

---

## 2. Dynamic Routing DataSource (`AbstractRoutingDataSource`)

```java
// multitenancy/TenantRoutingDataSource.java
package com.enterprise.app.multitenancy;

import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource;

public class TenantRoutingDataSource extends AbstractRoutingDataSource {

    @Override
    protected Object determineCurrentLookupKey() {
        // Return active tenant key from current HTTP thread context
        return TenantContext.getTenantId();
    }
}
```

---

## 3. Multi-Tenant DataSource Configuration

```java
// config/MultiTenantDataSourceConfig.java
package com.enterprise.app.config;

import com.enterprise.app.multitenancy.TenantRoutingDataSource;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class MultiTenantDataSourceConfig {

    @Bean
    @Primary
    public DataSource dynamicDataSource() {
        TenantRoutingDataSource routingDataSource = new TenantRoutingDataSource();

        // 1. Default Master DataSource
        HikariDataSource defaultDataSource = createHikariDataSource("public");

        // 2. Map of Tenant-specific DataSources
        Map<Object, Object> targetDataSources = new HashMap<>();
        targetDataSources.put("tenant_acme", createHikariDataSource("tenant_acme"));
        targetDataSources.put("tenant_globex", createHikariDataSource("tenant_globex"));

        routingDataSource.setDefaultTargetDataSource(defaultDataSource);
        routingDataSource.setTargetDataSources(targetDataSources);
        routingDataSource.afterPropertiesSet();

        return routingDataSource;
    }

    private HikariDataSource createHikariDataSource(String schema) {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl("jdbc:postgresql://localhost:5432/enterprise_db?currentSchema=" + schema);
        ds.setUsername("postgres");
        ds.setPassword("secret");
        ds.setMaximumPoolSize(10);
        return ds;
    }
}
```

---

## 4. Tenant Extraction Interceptor

```java
// multitenancy/TenantInterceptor.java
package com.enterprise.app.multitenancy;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class TenantInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String tenantId = request.getHeader("X-Tenant-ID");
        if (tenantId != null && !tenantId.isBlank()) {
            TenantContext.setTenantId(tenantId);
        } else {
            TenantContext.setTenantId("public"); // Default fallback
        }
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        // ALWAYS clean up ThreadLocal to prevent memory leaks and thread pollution in thread pools
        TenantContext.clear();
    }
}
```

---

**Execution Protocol**
1. **Always invoke `TenantContext.clear()` in `afterCompletion`**: Prevents tenant context leaking across recycled worker threads.
2. **Use Schema-per-Tenant for B2B applications**: Balances isolation with infrastructure costs.
3. **Validate tenant existence against a central Tenant Catalog**: Never route to unverified arbitrary schemas.

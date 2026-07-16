---
name: spring-boot-core-di
description: Core IoC container standards, Bean definitions, dependency scopes, configuration profiles, and type-safe properties configuration mapping.
author: Diego Villanueva
trigger: When configuring Spring Bean dependencies, building application properties bindings, setting profile-specific configurations, or defining custom config classes.
---

# Spring Boot Core & Dependency Injection (DI)

The Spring IoC (Inversion of Control) container manages Application context beans. Designing clean, decoupled beans that compile safely, initialize predictably, and prevent circular dependencies is crucial.

---

## 1. Type-Safe Configuration Properties

Scattering `@Value("${some.property}")` annotations across multiple classes makes properties difficult to validate at startup, lacks autocomplete support, and breaks encapsulation.

**❌ NEVER** inject environment configurations using scattered `@Value` annotations inside business logic.
**✅ ALWAYS** group properties into type-safe `@ConfigurationProperties` classes validated using Jakarta Validation rules.

```java
// ✅ ALWAYS: Map properties to a validated configuration bean
@ConfigurationProperties(prefix = "app.payment")
@Validated
@Data
public class PaymentProperties {
    @NotNull(message = "API key must not be null")
    private String apiKey;

    @Min(value = 1000, message = "Timeout must be at least 1000ms")
    private int timeoutMillis;
}

// Register inside a config class using: @EnableConfigurationProperties(PaymentProperties.class)
```

---

## 2. Constructor-Based Injection with Lombok

Field injection via `@Autowired` hides class dependency counts and forces dependencies to remain mutable (preventing `final` fields).

**❌ NEVER** inject beans using field-level `@Autowired` declarations.
**✅ ALWAYS** use constructor-based injection. Use Lombok's `@RequiredArgsConstructor` to generate constructors automatically for all `private final` fields.

```java
// ❌ NEVER: Hard to test without initializing Spring context or mock frameworks
@Component
public class NotificationHandler {
    @Autowired
    private MailSender mailSender;
}

// ✅ ALWAYS: final fields injected via automatic constructor injection
@Component
@RequiredArgsConstructor
public class NotificationHandler {
    private final MailSender mailSender; // Enforces immutability
}
```

---

## 3. Profile-Specific Configuration Isolation

Placing environment-specific configuration code blocks directly in global classes (using `if` statements or active profile string queries) pollutes production code.

**❌ NEVER** determine environment behaviors using active profile checks inside services.
**✅ ALWAYS** isolate profile-specific logic using `@Profile` class decorators or distinct application property files (`application-dev.yml`, `application-prod.yml`).

```java
// ✅ ALWAYS: Separate bean definitions using active profile annotations
@Configuration
@Profile("local")
public class LocalStorageConfig {
    @Bean
    public StorageService localStorageService() {
        return new LocalStorageServiceImpl();
    }
}

@Configuration
@Profile("prod")
public class S3StorageConfig {
    @Bean
    public StorageService s3StorageService() {
        return new S3StorageServiceImpl();
    }
}
```

---

## 4. Bean Scopes and Thread-Safety Warns

Spring Beans are **Singletons** by default. A single shared instance is managed by the IoC container.

1. **Keep Singletons Stateless**: Ensure singleton service classes have NO mutable instance variables. All state changes must pass through method arguments and return types.
2. **Prototype Scoping**: Use `@Scope("prototype")` for stateful beans that must be re-instantiated on every injection request.
3. **Request/Session Scopes**: When declaring Web Request or Session scopes, configure scoped proxies (`@Scope(value = WebApplicationContext.SCOPE_REQUEST, proxyMode = ScopedProxyMode.TARGET_CLASS)`) to avoid injecting stale scope values into singletons.

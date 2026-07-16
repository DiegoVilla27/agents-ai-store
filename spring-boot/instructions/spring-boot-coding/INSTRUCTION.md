---
description: 'Principal Spring Boot Architect - Hexagonal/Clean Architecture, Domain-Driven Design (DDD) & Observability'
applyTo: '**/*.java'
---

# Enterprise Spring Boot Coding Standard & Architecture Protocol

You are a **Principal Backend Architect**. Your prime directive is to build fault-tolerant, scalable, and highly secure microservices or modular monoliths using **Spring Boot 3.x** and **Java 17/21**. You strictly enforce **Clean Architecture**, **Domain-Driven Design (DDD)**, and **observability-driven engineering**.

---

## 🏛️ 1. ARCHITECTURAL PATTERN: Clean Architecture (Hexagonal)

The traditional 3-tier structure (Controller -> Service -> Entity/Repository) is strictly **BANNED** for core domain domains. It binds domain logic to Hibernate/JPA annotations and database-specific schemas, resulting in tight coupling.

Every bounded context must follow this package layout representing Hexagonal Architecture (Ports and Adapters):

```text
com.enterprise.app.[context]/
├── domain/                  # 🟢 CORE: Pure Java, No framework dependencies (No Spring annotations)
│   ├── model/               # Rich Entities, Aggregates, Value Objects (Immutable)
│   ├── exception/           # Bounded context specific domain exceptions
│   └── repository/          # Interface ports for database access
├── application/             # 🔵 USE CASES: Application core, transaction boundaries
│   ├── service/             # Use Case implementations orchestrating Domain models
│   ├── dto/                 # Request/Response data carriers (Java Records)
│   └── port/                # Incoming use case interfaces / outbound external ports
└── infrastructure/          # 🟡 ADAPTERS: Framework and database implementations
    ├── persistence/         # Spring Data JPA repositories, Entity Mappers, DB entities
    ├── messaging/           # Kafka producers/consumers, RabbitMQ bindings
    ├── config/              # Spring bean configuration, security settings
    └── controller/          # REST Controllers, validation adapters (@Valid)
```

### Dependency Inversion Principle (DIP) Rules:
- **Domain package** must never import classes from Spring Framework, Hibernate, Jakarta Persistence, or any external library. It is 100% pure Java.
- **Application package** imports only Domain.
- **Infrastructure package** binds everything together, providing concrete database configurations, security, and web interfaces.

---

## 🧠 2. DOMAIN-DRIVEN DESIGN (DDD) Rules

### A. Rich Domain Aggregates
**❌ NEVER** create JPA entity classes containing annotations like `@Entity`, `@Column`, `@Id` inside the `domain.model` package.
**✅ ALWAYS** keep domain model classes annotation-free. Map db entities (`UserJPAEntity`) to rich domain objects (`User`) using Mapper utilities at the infrastructure boundary.

```java
// 🟢 Domain Layer (Pure Java)
public class Account {
    private final UUID id;
    private BigDecimal balance;

    public Account(UUID id, BigDecimal initialBalance) {
        if (initialBalance.compareTo(BigDecimal.ZERO) < 0) {
            throw new InvalidBalanceException("Initial balance cannot be negative");
        }
        this.id = id;
        this.balance = initialBalance;
    }

    public void withdraw(BigDecimal amount) {
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Withdrawal amount must be positive");
        }
        if (balance.compareTo(amount) < 0) {
            throw new InsufficientFundsException("Insufficient funds for withdrawal");
        }
        this.balance = this.balance.subtract(amount);
    }
}
```

---

## ⚡ 3. STACK-SAFE DEPENDENCY INJECTION

Field injection makes classes tightly coupled to the Spring IoC container and makes unit testing difficult.

**❌ NEVER** use `@Autowired` on class fields.
**✅ ALWAYS** enforce constructor injection. Use Lombok's `@RequiredArgsConstructor` on the class, ensuring fields are declared as `private final`.

```java
// ❌ NEVER: Hard to unit test without reflection helpers
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;
}

// ✅ ALWAYS: Pure constructor injection (Highly testable)
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository; // Automatically injected via constructor
}
```

---

## 🛡️ 4. API BOUNDARY VALIDATION

Never trust client payloads. Unvalidated inputs cause SQL injects, stack overflows, or invalid data states.

**❌ NEVER** map raw client bodies directly into domain classes without validation.
**✅ ALWAYS** use Jakarta validation constraints on Java Records (DTOs) and annotate controller parameters with `@Valid`.

```java
// 🟡 Infrastructure Layer: DTO as Java Record
public record CreateUserRequest(
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    String username,

    @NotBlank(message = "Email is required")
    @Email(message = "Email must be a valid email address")
    String email
) {}

// 🟡 Infrastructure Layer: Controller
@RestController
@RequestMapping("/api/v1/users")
public class UserController {
    @PostMapping
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        // Validation executes automatically. Failed checks throw MethodArgumentNotValidException.
    }
}
```

---

## 🔌 5. GLOBAL EXCEPTION INTERCEPTION (ProblemDetail)

Never let raw stack traces leak to HTTP clients. It exposes system internals and leaks vulnerabilities.

**❌ NEVER** wrap every controller endpoint block with manual `try/catch` handlers returning custom error envelopes.
**✅ ALWAYS** configure a global `@RestControllerAdvice` class intercepting exceptions and returning standard **RFC 7807 ProblemDetail** specifications (native in Spring Boot 3.x).

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(DomainException.class)
    public ProblemDetail handleDomainException(DomainException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, 
            ex.getMessage()
        );
        problem.setTitle("Domain Invariant Violation");
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidationException(MethodArgumentNotValidException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.UNPROCESSABLE_ENTITY, 
            "Input validation failed"
        );
        problem.setTitle("Validation Failure");
        
        Map<String, String> errors = ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(FieldError::getField, FieldError::getDefaultMessage));
        problem.setProperty("invalid_fields", errors);
        
        return problem;
    }
}
```

---

## 🚀 6. SUMMARY OF BANNED PRACTICES

- **No Field Autowiring**: Enforce constructor injection for all Spring components.
- **No JPA/Hibernate Annotations in Domain**: Keep domain code strictly pure Java.
- **No Inline Config Values**: Declare configuration fields via `@ConfigurationProperties` class objects, never via inline `@Value("${...}")` scatter.
- **No System.out.println**: Always use SLF4J loggers (e.g. via Lombok's `@Slf4j`).
- **No Raw Thread Spawning**: Use Spring TaskExecutor abstractions or Project Loom Virtual Threads (`spring.threads.virtual.enabled=true`).

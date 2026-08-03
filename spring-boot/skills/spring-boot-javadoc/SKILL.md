---
name: spring-boot-javadoc
description: The definitive architectural standard for enterprise Javadoc documentation in Java 17/21 and Spring Boot applications.
author: Diego Villanueva
trigger: When documenting Java classes, interfaces, Spring components, REST controllers, DTO Records, JPA repositories, or domain exceptions.
---

# Enterprise Javadoc & Technical Documentation Protocol (Java 17/21 & Spring Boot 3.x)

You are the author of the system's architectural contract. Good Java code documents its intent through expressive naming, but professional **Javadoc** documents the *business invariants*, *preconditions*, *side effects*, *thread-safety guarantees*, and *exceptional failure modes*. In the era of AI-driven development and modern Java (17/21), clean Javadoc is the primary vector for context inheritance and IDE intellisense.

---

## 1. Core Principles of Enterprise Javadoc

1. **Do Not Repeat the Type System**: Never write `/** Sets the name string */ void setName(String name)`. The compiler already knows it's a `String`. Document *business constraints*, e.g., "Updates the customer's legal name. Must not exceed 100 characters and cannot contain special characters."
2. **The Triple-Contract Standard**: Every non-trivial public method Javadoc must specify:
   - **Summary & Purpose**: What the method does and *why*.
   - **Inputs & Preconditions (`@param`)**: Valid ranges, non-null guarantees, or format constraints.
   - **Outputs & Postconditions (`@return`)**: Guaranteed state of the return object (or Optional behavior).
   - **Exceptions & Boundary Failures (`@throws`)**: Both checked exceptions and domain runtime exceptions (`EntityNotFoundException`, `DomainInvariantViolation`).
3. **Modern Java Syntax**: Use Java 18+ `{@snippet ...}` blocks for code examples instead of pre-formatted HTML tags (`<pre>{@code ...}</pre>`).

---

## 2. Javadoc Tag Reference & Usage

| Tag | Placement | Usage |
|:---|:---|:---|
| `@param <name> <description>` | Method / Record | Documents input parameters or Record components. |
| `@return <description>` | Method | Documents the return value. Omit for `void` methods. |
| `@throws <ExceptionClass> <condition>` | Method | Documents exceptions thrown under specific failure states. |
| `{@link <package.Class#member>}` | Inline | Creates a navigable hyper-link to another class or method. |
| `{@code <text>}` | Inline | Formats inline code fragments without XML escaping issues. |
| `{@snippet : ...}` | Block | Formats multi-line code examples with IDE validation support. |
| `@see <reference>` | Class / Method | References related classes, specs (e.g. RFC 7807), or documentation. |
| `@deprecated <explanation>` | Class / Method | Marks API as obsolete. **MUST** reference replacement via `{@link}`. |

---

## 3. Spring Boot Architectural Component Standards

### A. Record DTOs (Java 14/17+)
Document Record components directly in the class-level Javadoc using `@param`.

```java
/**
 * Request payload for creating a new high-yield savings account.
 *
 * @param customerId Unique UUID of the primary account holder. Must correspond to an active customer.
 * @param initialDeposit Initial funding amount. Must be greater than or equal to $100.00.
 * @param currency ISO-4217 3-letter currency code (e.g., "USD", "EUR").
 */
public record CreateAccountRequest(
    @NotNull UUID customerId,
    @NotNull @DecimalMin("100.00") BigDecimal initialDeposit,
    @NotBlank @Size(min = 3, max = 3) String currency
) {}
```

### B. REST Controllers (`@RestController`)
Combine Javadoc with OpenAPI/Swagger annotations to document HTTP status codes, security authorizations, and API contracts.

```java
/**
 * REST controller for managing enterprise account lifecycles.
 * All endpoints require an authenticated OAuth2 bearer token with 'ROLE_BANK_OFFICER'.
 *
 * @see com.enterprise.bank.account.service.AccountService
 */
@RestController
@RequestMapping("/api/v1/accounts")
@RequiredArgsConstructor
public class AccountController {

    private final AccountService accountService;

    /**
     * Opens a new bank account for an existing customer.
     *
     * @param request The account creation parameters.
     * @return {@link ResponseEntity} containing the created {@link AccountResponse} and HTTP 201 URI header.
     * @throws CustomerNotFoundException If the provided {@code customerId} does not match an existing record.
     * @throws InsufficientInitialDepositException If {@code initialDeposit} is below currency minimums.
     */
    @PostMapping
    public ResponseEntity<AccountResponse> createAccount(@Valid @RequestBody CreateAccountRequest request) {
        AccountResponse response = accountService.createAccount(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(response.id())
            .toUri();
        return ResponseEntity.created(location).body(response);
    }
}
```

### C. Service Layer Use Cases & Transactions (`@Service`)
Document transactional behavior, concurrency locks, and side-effects.

```java
/**
 * Service implementation for processing atomic monetary transfers between accounts.
 * Enforces pessimistic locking to prevent race conditions during balance mutation.
 */
@Service
@RequiredArgsConstructor
public class TransferService {

    private final AccountRepository accountRepository;

    /**
     * Executes an immediate funds transfer between two internal accounts within a single transaction.
     *
     * <p><b>Side Effects:</b> Emits a {@code TransferCompletedEvent} to Kafka upon successful commit.</p>

     * {@snippet :
     *   TransferResult result = transferService.executeTransfer(
     *       sourceId, targetId, new BigDecimal("250.00")
     *   );
     * }
     *
     * @param sourceAccountId The UUID of the account to debit. Must have sufficient funds.
     * @param targetAccountId The UUID of the account to credit. Must be in ACTIVE status.
     * @param amount The transfer amount. Must be strictly positive.
     * @return The resulting {@link TransferResult} summary including transaction reference code.
     * @throws AccountLockedException If either account is currently being processed by another thread.
     * @throws InsufficientFundsException If the source account balance is less than {@code amount}.
     */
    @Transactional
    public TransferResult executeTransfer(UUID sourceAccountId, UUID targetAccountId, BigDecimal amount) {
        // Implementation
    }
}
```

### D. JPA Repositories (`@Repository`)
Document custom JPQL/Native queries and locking modes.

```java
/**
 * Data access repository for {@link AccountEntity} persistence.
 */
@Repository
public interface AccountRepository extends JpaRepository<AccountEntity, UUID> {

    /**
     * Retrieves an account entity by its unique ID while acquiring a PESSIMISTIC_WRITE lock.
     *
     * @param id The account unique identifier.
     * @return An {@link Optional} containing the locked entity if found, or empty if absent.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT a FROM AccountEntity a WHERE a.id = :id")
    Optional<AccountEntity> findByIdForUpdate(@Param("id") UUID id);
}
```

---

## 4. Summary of Banned Practices

- **No Redundant Getter/Setter Javadoc**: Avoid writing `/** Gets the ID */` for standard bean getters. Only document if there is non-obvious logic.
- **No Legacy HTML Formatting**: Do not use `<tt>`, `<font>`, or `<b>` tags. Use `{@code ...}`, `{@link ...}`, or CSS tags (`<em>`, `<strong>`).
- **No Raw Exception Type Names without {@link} or @throws**: Always use `@throws` and `{@link ExceptionClass}` so documentation stays linked to actual code types.
- **No Missing Deprecation Guidance**: Never use `@deprecated` without an accompanying explanation and `{@link ReplacementClass}` link.

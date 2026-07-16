---
name: spring-boot-testing-expert
description: Advanced testing guidelines covering unit tests with Mockito, slice testing (MockMvc, `@WebMvcTest`, `@DataJpaTest`), and integration tests with Testcontainers.
author: Diego Villanueva
trigger: When writing JUnit tests, mocking services, testing REST controllers, verifying JPA entity repositories, or integrating Testcontainers.
---

# Spring Boot Testing Engineering Protocol

Testing is essential for backend stability. You must enforce the test pyramid: fast unit tests for business logic, isolated slice tests for integration ports (Web/JPA), and Testcontainers-driven integration tests for verification against real environments.

---

## 1. Fast Unit Testing without Spring Boot Context

Initializing the entire Spring IoC container (`@SpringBootTest`) to test simple business logic is a performance anti-pattern that slows down builds.

**❌ NEVER** annotate pure business services or domain unit tests with `@SpringBootTest`.
**✅ ALWAYS** use JUnit 5 and **Mockito** (`@ExtendWith(MockitoExtension.class)`) to mock dependencies.

```java
// ✅ ALWAYS: Test services using mock dependencies without booting Spring
@ExtendWith(MockitoExtension.class)
class RegisterUserUseCaseTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private RegisterUserUseCase registerUserUseCase;

    @Test
    void execute_ShouldSaveUser_WhenUsernameIsUnique() {
        when(userRepository.existsByEmail("test@domain.com")).thenReturn(false);

        registerUserUseCase.execute(new RegisterUserCommand("test@domain.com", "pass"));

        verify(userRepository, times(1)).save(any());
    }
}
```

---

## 2. API Slice Testing with WebMvcTest

Verify controller routing, parameters mapping, DTO validations, and exception responses without spinning up server ports or persistence layers.

**❌ NEVER** test web controller mappings using full integration tests (`@SpringBootTest`) if Web slice tests can cover it.
**✅ ALWAYS** use `@WebMvcTest` in combination with **MockMvc** and `@MockBean`.

```java
// ✅ ALWAYS: Slice test controllers in isolation
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService; // Mocked service dependency

    @Test
    void createUser_ShouldReturnBadRequest_WhenEmailIsInvalid() throws Exception {
        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"john\",\"email\":\"invalid-email\"}"))
                .andExpect(status().isUnprocessableEntity()) // ProblemDetail handler captures it
                .andExpect(jsonPath("$.title").value("Validation Failure"));
    }
}
```

---

## 3. Integration Testing with Testcontainers

Using in-memory H2 databases for testing PostgreSQL-specific or MySQL-specific code leads to hidden syntax and dialect bugs in production.

**❌ NEVER** use H2 or database mocks to run database integration test flows in production-grade environments.
**✅ ALWAYS** use **Testcontainers** to boot up real Postgres, MySQL, Kafka, or Redis instances inside Docker.

```java
// ✅ ALWAYS: Use Testcontainers for real database assertions
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class UserIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void testCreateUserFlow() {
        // Run HTTP assertions against the running testcontainer database
    }
}
```

---

## 4. JPA Repository Slice Testing

If you only need to verify custom JPQL queries, mappings, or schema interactions:

**❌ NEVER** initialize controllers or services.
**✅ ALWAYS** use `@DataJpaTest`. It configures an in-memory database or test database, configures Hibernate, and runs each test inside an auto-rollback transaction.

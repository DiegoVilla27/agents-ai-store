---
name: spring-boot-springdoc-openapi
description: The ultimate architectural standard for OpenAPI 3.0 & Swagger UI in Spring Boot 3.x with springdoc-openapi, Java Records DTO schemas, and Security Scheme Bearer configs.
author: Diego Villanueva
trigger: When generating OpenAPI 3.0 / Swagger documentation in Spring Boot 3.x, annotating Java Records with Schema definitions, or securing Swagger UI.
---

# Enterprise Spring Boot OpenAPI & Swagger Architecture (springdoc-openapi)

Automated, accurate API contracts prevent communication breakdowns between backend and frontend teams. In Spring Boot 3.x, **`springdoc-openapi`** generates interactive OpenAPI 3.0 specifications and Swagger UI interfaces directly from Java code and Record DTOs.

---

## 1. Maven / Gradle Dependency Setup

```xml
<!-- pom.xml (Spring Boot 3.x) -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.6.0</version>
</dependency>
```

---

## 2. OpenAPI Bean Configuration with JWT Security Scheme

```java
// config/OpenApiConfig.java
package com.enterprise.app.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    private static final String SECURITY_SCHEME_NAME = "BearerAuth";

    @Bean
    public OpenAPI enterpriseOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Enterprise Banking & Core API")
                .description("Production-grade RESTful API built with Spring Boot 3.x and Java 21.")
                .version("v1.0.0")
                .contact(new Contact().name("Diego Villanueva").email("architect@enterprise.com"))
                .license(new License().name("Proprietary").url("https://enterprise.com/terms")))
            .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
            .components(new Components()
                .addSecuritySchemes(SECURITY_SCHEME_NAME, new SecurityScheme()
                    .name(SECURITY_SCHEME_NAME)
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")));
    }
}
```

---

## 3. Annotating Java Records with `@Schema`

```java
// dto/CreateCustomerRequest.java
package com.enterprise.app.customer.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Payload for creating a new enterprise customer account")
public record CreateCustomerRequest(
    @Schema(description = "Customer legal full name", example = "Diego Villanueva")
    @NotBlank(message = "Full name is required")
    @Size(min = 2, max = 100)
    String fullName,

    @Schema(description = "Primary verified email address", example = "diego@enterprise.com")
    @NotBlank(message = "Email is required")
    @Email(message = "Must be a valid email format")
    String email,

    @Schema(description = "Initial deposit amount in USD", example = "5000.00")
    java.math.BigDecimal initialDeposit
) {}
```

---

## 4. Documenting REST Controllers with `@Operation` and `@ApiResponses`

```java
// controller/CustomerController.java
package com.enterprise.app.customer.controller;

import com.enterprise.app.customer.dto.CreateCustomerRequest;
import com.enterprise.app.customer.dto.CustomerResponse;
import com.enterprise.app.customer.service.CustomerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/customers")
@RequiredArgsConstructor
@Tag(name = "Customer Management", description = "Operations for onboarding and managing enterprise customers")
public class CustomerController {

    private final CustomerService customerService;

    @PostMapping
    @Operation(summary = "Register customer", description = "Creates a new customer record and triggers verification onboarding")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "Customer registered successfully",
            content = @Content(schema = @Schema(implementation = CustomerResponse.class))),
        @ApiResponse(responseCode = "400", description = "Invalid payload or validation failure",
            content = @Content(schema = @Schema(implementation = ProblemDetail.class))),
        @ApiResponse(responseCode = "409", description = "Customer email already exists",
            content = @Content(schema = @Schema(implementation = ProblemDetail.class)))
    })
    public ResponseEntity<CustomerResponse> createCustomer(@Valid @RequestBody CreateCustomerRequest request) {
        CustomerResponse response = customerService.createCustomer(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
```

---

## 5. Swagger Configuration in `application.yml`

```yaml
springdoc:
  api-docs:
    path: /api-docs
    enabled: true
  swagger-ui:
    path: /swagger-ui.html
    operationsSorter: method
    tagsSorter: alpha
    tryItOutEnabled: true
    displayRequestDuration: true
```

---

**Execution Protocol**
1. **Always use Java Records for DTO schemas**: Automatically maps cleanly to OpenAPI schema representations.
2. **Always document error responses using `ProblemDetail`**: Maintains RFC 7807 compliance in API documentation.
3. **Secure Swagger UI in Production**: Restrict access to `/swagger-ui/**` via Spring Security IP allowlisting or Role guards (`hasRole('ADMIN')`).

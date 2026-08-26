---
name: spring-boot-security-oauth2-resource-server
description: The ultimate architectural standard for Enterprise SSO & OAuth2 Resource Server in Spring Boot 3.x with Spring Security, Keycloak / Auth0 OIDC, and JWT JWKS validation.
author: Diego Villanueva
trigger: When configuring Spring Security OAuth2 Resource Server, validating JWT tokens with JWKS in Spring Boot 3.x, integrating Keycloak or Auth0, or protecting methods with @PreAuthorize.
---

# Enterprise Spring Boot OAuth2 Resource Server Architecture (Keycloak & OIDC)

In modern enterprise architectures, identity management is federated to an OpenID Connect (OIDC) Identity Provider (**Keycloak**, **Auth0**, **Okta**, **Azure AD**). Spring Boot applications act as stateless **OAuth2 Resource Servers** that decode and validate asymmetric RS256 JWT tokens via dynamic **JWKS endpoints**.

---

## 1. Dependencies Setup

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

---

## 2. Resource Server Configuration (`application.yml`)

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://auth.enterprise.com/realms/production # Auto-discovers JWKS URI
          audiences: enterprise-api
```

---

## 3. Spring Security Filter Chain with Role Mapping

```java
// config/SecurityConfig.java
package com.enterprise.app.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.security.web.SecurityFilterChain;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity // Enables @PreAuthorize("hasRole('ADMIN')")
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health/**", "/swagger-ui/**", "/api-docs/**").permitAll()
                .anyRequest().authenticated())
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter())));

        return http.build();
    }

    private Converter<Jwt, ? extends AbstractAuthenticationToken> jwtAuthenticationConverter() {
        return jwt -> {
            // Extract Keycloak realm_access.roles
            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
            Collection<GrantedAuthority> authorities = List.of();

            if (realmAccess != null && realmAccess.containsKey("roles")) {
                List<String> roles = (List<String>) realmAccess.get("roles");
                authorities = roles.stream()
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                    .collect(Collectors.toList());
            }

            return new JwtAuthenticationToken(jwt, authorities);
        };
    }
}
```

---

## 4. Granular Method Security with `@PreAuthorize`

```java
// controller/AdminPayrollController.java
package com.enterprise.app.payroll.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/payroll")
public class AdminPayrollController {

    @GetMapping("/executive-salaries")
    @PreAuthorize("hasRole('EXECUTIVE') and hasAuthority('SCOPE_payroll:read')")
    public PayrollReport getExecutivePayroll() {
        return payrollService.generateExecutiveReport();
    }
}
```

---

**Execution Protocol**
1. **Always use dynamic `issuer-uri`**: Allows Spring Security to automatically discover the JWKS keys and rotate certificates without restarts.
2. **Stateless Sessions**: Always mandate `SessionCreationPolicy.STATELESS` for Resource Servers.
3. **Map Claims to `ROLE_` Authorities**: Allows idiomatic Spring `@PreAuthorize("hasRole('...')")` expression evaluation.

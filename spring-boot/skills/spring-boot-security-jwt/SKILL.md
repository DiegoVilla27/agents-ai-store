---
name: spring-boot-security-jwt
description: Security implementation guidelines for Spring Security configuration, stateless JWT authentication filters, security context validation, and method-level access authorization.
author: Diego Villanueva
trigger: When configuring Spring Security filters, creating custom JWT validation filters, managing security properties, or securing API endpoints with access controls.
---

# Spring Boot Security & Stateless JWT Authentication

Spring Security is a powerful, customizable authentication and access-control framework. For enterprise REST APIs, you must implement stateless security, custom request filtering, and declarative method authorization.

---

## 1. Stateless Security Filter Chain

Traditional server-side sessions (JSESSIONID) consume memory and prevent horizontal scaling.

**❌ NEVER** allow Spring Security to default to stateful cookie-based session tracking (`HttpSession`).
**✅ ALWAYS** enforce `SessionCreationPolicy.STATELESS` and build a clean `SecurityFilterChain` bean.

```java
// ✅ ALWAYS: Configure a stateless security filter chain in Spring Boot 3.x
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // Safe to disable ONLY in stateless REST APIs
            .cors(Customizer.withDefaults())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**", "/v3/api-docs/**", "/swagger-ui/**").permitAll()
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

---

## 2. JWT Extraction and Security Context Binding

A custom filter must intercept HTTP calls, validate incoming authentication tokens, and bind validated client contexts to the security context.

**❌ NEVER** query database repositories on every single incoming API call inside the JWT filter (it causes severe performance degradation).
**✅ ALWAYS** extract claims directly from the cryptographically signed JWT token body and bind them directly to the `SecurityContext`.

```java
// ✅ ALWAYS: Extract claims and build the Authentication token safely
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    @Override
    protected void doFilterInternal(
        @NonNull HttpServletRequest request,
        @NonNull HttpServletResponse response,
        @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        final String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String jwt = authHeader.substring(7);
        try {
            if (jwtService.isTokenValid(jwt)) {
                Claims claims = jwtService.extractAllClaims(jwt);
                List<SimpleGrantedAuthority> authorities = jwtService.extractAuthorities(claims);

                UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                    claims.getSubject(),
                    null,
                    authorities
                );
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        } catch (Exception ex) {
            SecurityContextHolder.clearContext(); // Ensure clean rejection on validation crash
        }

        filterChain.doFilter(request, response);
    }
}
```

---

## 3. Declarative Method-Level Authorization

Configuring all route permissions inside the global `SecurityFilterChain` makes files large and difficult to maintain.

**❌ NEVER** write manual role checks inside controllers or service logic.
**✅ ALWAYS** declare access rules directly on methods using `@PreAuthorize` assertions.

```java
// ✅ ALWAYS: Protect methods declaratively
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {

    @DeleteMapping("/users/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUser(@PathVariable UUID id) {
        // Enforces role verification before method entry
        return ResponseEntity.noContent().build();
    }
}
```

---

## 4. Custom Authentication Entry Point

When a user provides missing or invalid credentials, Spring Security returns default HTML login pages or blank 401 statuses.

**❌ NEVER** let raw authentication exceptions escape to clients as HTML error documents.
**✅ ALWAYS** configure a custom `AuthenticationEntryPoint` mapping exceptions into clean JSON response structures.

---
name: web-security-owasp
description: The ultimate architectural standard for Web Security (OWASP Top 10), Content Security Policy (CSP), XSS/CSRF Mitigation, Subresource Integrity (SRI), and Secure Cookie Flags.
author: Diego Villanueva
trigger: When auditing web security, configuring Content Security Policy (CSP) headers, preventing XSS/CSRF attacks, or hardening web applications against OWASP vulnerabilities.
---

# Enterprise Web Security Architecture (OWASP Top 10 & Defense-in-Depth)

Web vulnerabilities lead to data breaches, session hijacking, and defacement. An Enterprise Staff Engineer designs web applications with **Defense-in-Depth**, enforcing strict **Content Security Policies (CSP)**, **XSS sanitization**, **CSRF tokens**, and **Secure Cookie flags**.

---

## 1. Content Security Policy (CSP) Header Hardening

A strict CSP prevents Cross-Site Scripting (XSS) by restricting the domains from which scripts, styles, and media can load, and disabling inline script execution without cryptographic nonces or hashes.

```http
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-rAnd0m123' https://trusted-cdn.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https://*.enterprise.com; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://api.enterprise.com wss://api.enterprise.com; frame-ancestors 'none'; form-action 'self'; base-uri 'self'; object-src 'none';
```

---

## 2. Essential Security Response Headers (HTTP Hardening)

Every production HTTP response MUST include these defense headers:

```typescript
// middleware/security-headers.ts
export const SECURITY_HEADERS = {
  // 1. Prevent Clickjacking
  'X-Frame-Options': 'DENY',
  // 2. Prevent MIME-type sniffing
  'X-Content-Type-Options': 'nosniff',
  // 3. Enforce HTTPS for 2 years with preloading
  'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
  // 4. Restrict Referrer leakage
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  // 5. Restrict device hardware permissions
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=()',
};
```

---

## 3. Cross-Site Scripting (XSS) Prevention & DOM Sanitization

**❌ NEVER** inject untrusted user input using `dangerouslySetInnerHTML`, `innerHTML`, or `document.write`.
**✅ ALWAYS** sanitize HTML using **DOMPurify** before rendering:

```typescript
import DOMPurify from 'isomorphic-dompurify';

export function renderSafeHtml(untrustedInput: string): string {
  return DOMPurify.sanitize(untrustedInput, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'ul', 'li'],
    ALLOWED_ATTR: ['href', 'target', 'rel'],
  });
}
```

---

## 4. Secure Cookie Configuration for Authentication Tokens

Never store sensitive JWTs or session tokens in `localStorage` (vulnerable to XSS extraction). Always issue **HTTP-Only, Secure, SameSite** cookies from the server:

```typescript
res.cookie('session_token', token, {
  httpOnly: true,                // Inaccessible to client-side JavaScript (document.cookie)
  secure: true,                  // Transmitted only over HTTPS
  sameSite: 'strict',            // Prevents Cross-Site Request Forgery (CSRF)
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
  path: '/',
});
```

---

## 5. Subresource Integrity (SRI) for Third-Party CDNs

When loading external scripts from CDNs, ensure tampering cannot inject malicious code by specifying cryptographic SRI hashes:

```html
<script
  src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"
  integrity="sha384-geWF76RCwLtnZ8qwWowPQNguL3RmwHVBC9FhGdlKrxdiJJigb/j/68SIy3Te4Bkz"
  crossorigin="anonymous"
></script>
```

---

**Execution Protocol**
1. **Never store authentication tokens in `localStorage`**: Always use `HttpOnly; Secure; SameSite=Strict` cookies.
2. **Always configure a strict Content Security Policy (CSP)**: Ban `unsafe-eval` completely.
3. **Validate and sanitize inputs on both Client AND Server**: Client validation is UX; server validation is Security.
4. **Use Subresource Integrity (SRI) for all external CDN assets**.

---
name: angular-security
description: The ultimate architectural standard for Enterprise Angular Security XSS Prevention, CSRF tokens, DomSanitizer, Token Storage (HttpOnly), and CSP.
author: Diego Villanueva
trigger: When handling authentication, storing tokens, rendering dynamic HTML, or protecting against XSS/CSRF.
---

# Enterprise Angular Security Architecture

The absolute golden rule of frontend security is: **The Client is inherently compromised.** 
An attacker can always open the DevTools, modify the DOM, change JavaScript variables, and bypass your UI guards.

True security (Authorization, Validation) MUST happen on the Backend. The Frontend's job is to protect the user from XSS (Cross-Site Scripting), CSRF (Cross-Site Request Forgery), and Token Theft.

## 1. Token Storage (The `localStorage` Vulnerability)

If you store a JWT (JSON Web Token) in `localStorage` or `sessionStorage`, any third-party JavaScript running on your site (e.g., Google Analytics, a compromised NPM package, or an XSS attack) can read that token and hijack the user's account.

**❌ NEVER** store Authentication Tokens in `localStorage`.
**✅ ALWAYS** rely on the Backend to set an `HttpOnly`, `Secure`, `SameSite=Strict` Cookie. 

If you absolutely must handle the token in JavaScript (e.g., third-party OAuth where cookies aren't an option), store it **In Memory** inside an Angular Service.

```typescript
// ✅ ALWAYS: Store tokens in-memory if HttpOnly cookies are impossible
import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class TokenService {
  // Stored in RAM. Destroyed when the tab is closed or refreshed.
  // Immune to basic XSS scraping of localStorage.
  private readonly jwtToken = signal<string | null>(null);

  setToken(token: string) {
    this.jwtToken.set(token);
  }

  getToken(): string | null {
    return this.jwtToken();
  }
}
```
*(Note: If you use In-Memory storage, you must implement a Silent Refresh mechanism via an invisible iframe or refresh token endpoint to keep the user logged in across tab refreshes).*

## 2. XSS (Cross-Site Scripting) & The DomSanitizer

Angular is extremely secure by default. If you bind a string containing `<script>alert('hack')</script>` using interpolation `{{ userInput }}`, Angular will safely render it as text, not HTML.

However, if you explicitly tell Angular to render HTML using `[innerHTML]`, you open the door to XSS.

**❌ NEVER** bypass security unless the HTML comes from a strictly trusted, heavily sanitized backend source.

```html
<!-- ✅ ALWAYS: Angular sanitizes [innerHTML] automatically by stripping <script> tags -->
<div [innerHTML]="blogPostHtml"></div>

<!-- ❌ NEVER: Do not bind directly to href with untrusted data (javascript: URIs) -->
<a [href]="untrustedUrl">Click Me</a>
```

If you absolutely must bypass Angular's security (e.g., embedding a trusted iframe video), you MUST use the `DomSanitizer`.

```typescript
import { Component, inject } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';

export class VideoComponent {
  private readonly sanitizer = inject(DomSanitizer);
  safeUrl: SafeResourceUrl;

  constructor() {
    // ⚠️ DANGER: Only do this if you 100% control the URL string.
    // Never pass user input into bypassSecurityTrust* methods.
    this.safeUrl = this.sanitizer.bypassSecurityTrustResourceUrl('https://youtube.com/embed/123');
  }
}
```

## 3. CSRF (Cross-Site Request Forgery)

CSRF occurs when a malicious website tricks a user's browser into making an authenticated request to your API.

If your backend uses Cookies for authentication, CSRF protection is **MANDATORY**. 
Angular has built-in support for CSRF/XSRF tokens. It looks for a cookie named `XSRF-TOKEN` and attaches its value to a header named `X-XSRF-TOKEN` on every mutating request (POST/PUT/DELETE).

```typescript
// ✅ ALWAYS: Enable CSRF Protection in app.config.ts if using Cookies
import { provideHttpClient, withXsrfConfiguration } from '@angular/common/http';

export const appConfig = {
  providers: [
    provideHttpClient(
      withXsrfConfiguration({
        cookieName: 'XSRF-TOKEN', // The cookie set by the backend
        headerName: 'X-XSRF-TOKEN' // The header Angular will send
      })
    )
  ]
};
```

## 4. UI Authorization (The Structural Directive)

You should hide buttons that a user doesn't have permission to click. However, remember that **this is for UX, not security**. An attacker can easily remove the `display: none` in DevTools. The backend MUST still validate the action.

**✅ ALWAYS** build a Structural Directive (like `*ngIf`) to conditionally render elements based on roles. This removes the DOM node entirely, making it harder (though not impossible) to bypass.

```typescript
// ✅ ALWAYS: Use a Structural Directive for Role-Based UI
import { Directive, Input, TemplateRef, ViewContainerRef, inject, effect } from '@angular/core';
import { AuthService } from './auth.service';

@Directive({
  selector: '[appHasRole]',
  standalone: true
})
export class HasRoleDirective {
  private readonly templateRef = inject(TemplateRef);
  private readonly vcr = inject(ViewContainerRef);
  private readonly auth = inject(AuthService);

  @Input({ required: true, alias: 'appHasRole' }) requiredRoles!: string[];

  constructor() {
    // Re-evaluate whenever the user's roles change
    effect(() => {
      const userRoles = this.auth.roles();
      const hasAccess = this.requiredRoles.some(r => userRoles.includes(r));

      if (hasAccess) {
        // Render the element
        if (this.vcr.length === 0) {
          this.vcr.createEmbeddedView(this.templateRef);
        }
      } else {
        // Destroy the element from the DOM
        this.vcr.clear();
      }
    });
  }
}
```
*(Usage: `<button *appHasRole="['ADMIN', 'MANAGER']">Delete System</button>`)*

## 5. CSP (Content Security Policy)

Angular cannot set CSP headers; they must be set by the server hosting the Angular app (Nginx, Node, S3). However, your Angular code must be CSP-compliant.

1. **No Inline Scripts**: Angular's AOT compiler guarantees no `eval()` or inline scripts are used in the framework itself.
2. **Inline Styles**: Angular uses inline `<style>` tags for component styles. To comply with strict CSP `style-src`, you must configure your server to send a unique cryptographic **Nonce** in the CSP header.
3. **Nonce Injection**: Angular can automatically attach this Nonce to its style tags.

```typescript
// ✅ ALWAYS: Provide the CSP Nonce token in app.config.ts for strict environments
import { CSP_NONCE } from '@angular/core';

export const appConfig = {
  providers: [
    {
      provide: CSP_NONCE,
      // Read the nonce generated by your server and injected into index.html
      useValue: globalThis['__CSP_NONCE__'] 
    }
  ]
};
```

---

**Execution Protocol**
1. **Third-Party Libraries**: Never install random NPM packages without auditing them. A compromised package can steal variables from RAM. Use `npm audit`.
2. **Route Guards**: As detailed in `angular-routing`, use `CanMatch` to prevent unauthorized users from even downloading the JS bundles for admin sections.
3. **Environment Files**: `environment.ts` is compiled into plain text in the browser. **NEVER** put API keys, passwords, or secrets in `environment.ts`. Only put public identifiers (e.g., Stripe Publishable Key, Firebase App ID).

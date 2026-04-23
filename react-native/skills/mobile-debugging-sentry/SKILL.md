---
description: 'Error Tracking and Performance Monitoring for Mobile'
author: 'Diego Villanueva'
trigger: 'When implementing error boundaries, crash reporting, or performance tracing.'
---

# Mobile Observability (Sentry)

Mastery of error tracking and performance monitoring in production mobile apps.

## ✅ ALWAYS
- Initialize Sentry as early as possible in the app lifecycle.
- Use `Sentry.wrap` to protect the root component.
- Upload **Source Maps** during the build process for readable stack traces.
- Use `Sentry.captureException` for manual error reporting in catch blocks.
- Tag events with useful context (user ID, app version, device info).
- Implement **Performance Tracing** to identify slow screens or API calls.

## ❌ NEVER
- Log sensitive PII (passwords, private data) to Sentry.
- Ignore the "Noise"; use sampling and filtering to focus on critical errors.

## 🛠 Patterns
- **Error Boundaries**: Using Sentry's ErrorBoundary component to provide fallback UIs.
- **Breadcrumbs**: Adding custom breadcrumbs to trace the user's path before a crash.

---
name: mobile-debugging-sentry
description: The definitive architectural standard for mobile observability, error tracking, and performance monitoring using Sentry in React Native.
author: Diego Villanueva
trigger: When configuring crash reporting, performance tracing, implementing Error Boundaries, or analyzing production anomalies in React Native.
---

# Mobile Observability Mastery (Sentry)

You are the architect of the application's central nervous system. In mobile development, you do not have the luxury of asking the user to "open the dev tools console." When a crash happens in the wild, your observability setup is your only eyes and ears. Sentry must be configured aggressively for detail, but defensively for privacy and performance.

## 1. Initialization & The Root Wrapper

Sentry must be the first thing initialized in your application, before any other logic or third-party SDKs.

- **Early Initialization**: Initialize `Sentry.init` at the very top of your entry file (e.g., `index.js` or `App.tsx`).
- **Root Wrapping**: Always wrap your root component with `Sentry.wrap`. This automatically instruments React rendering performance and catches unhandled exceptions in the React tree.

```typescript
// ✅ ALWAYS: Initialize before anything else
import * as Sentry from '@sentry/react-native';

Sentry.init({
  dsn: 'YOUR_DSN',
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0, // Adjust in production!
});

function App() {
  return <RootNavigator />;
}

export default Sentry.wrap(App);
```

## 2. Source Maps & Native Symbolication (CRITICAL)

Without Source Maps, your React Native stack traces will look like `app:///main.jsbundle:1:1234`, rendering them useless.

- **JS Source Maps**: Ensure the Sentry Metro plugin or Webpack plugin is correctly configured to upload source maps on every production build.
- **OTA Updates (CodePush)**: If using OTA updates, the release version in Sentry MUST match the exact OTA release bundle.
- **Native Crashes (dSYMs & ProGuard)**: React Native apps crash on the native side too. You must upload iOS `dSYM` files (via Bitcode/Xcode build phases) and Android ProGuard mapping files to Sentry.

## 3. Privacy, PII, and Data Scrubbing

You are legally and ethically bound to protect user privacy. Never send Personally Identifiable Information (PII) to Sentry unless explicitly required and legally cleared (like a User ID).

- **Data Scrubbing**: Use the `beforeSend` hook to strip out passwords, credit cards, auth tokens, or health data before the event leaves the device.

```typescript
// ✅ ALWAYS: Sanitize payloads
Sentry.init({
  dsn: 'YOUR_DSN',
  beforeSend(event) {
    if (event.request?.headers) {
      delete event.request.headers['Authorization'];
    }
    // Scrub sensitive state
    if (event.extra?.reduxState?.auth?.password) {
      event.extra.reduxState.auth.password = '***';
    }
    return event;
  },
});
```

## 4. Context, Tags, and Users

Errors without context are mysteries. You must attach metadata so you can filter and triage effectively.

- **User Context**: Set the user ID as soon as they log in. This allows you to track how many *unique users* are affected by a bug.
- **Tags**: Use tags for indexable, filterable dimensions (e.g., A/B test variants, payment gateways, network types).
- **Extra Context**: Use `setExtra` for deep, non-indexable JSON payloads (e.g., the last API response, local database state).

```typescript
// ✅ ALWAYS: Attach context upon login
Sentry.setUser({ id: user.id, email: user.email });
Sentry.setTag('experiment.checkout_v2', 'active');
Sentry.setExtra('cart_state', currentCart);
```

## 5. Breadcrumbs (The Trail of Breadcrumbs)

Breadcrumbs tell you exactly what the user did right before the crash. 

- **Automatic Breadcrumbs**: Sentry tracks touches, XHR/Fetch requests, and console logs automatically.
- **Navigation Tracking**: Integrate Sentry with React Navigation to automatically log breadcrumbs every time the user changes screens.
- **Manual Breadcrumbs**: Log critical business logic milestones manually.

```typescript
// ✅ ALWAYS: Track critical user flows
Sentry.addBreadcrumb({
  category: 'payment',
  message: 'User tapped submit payment',
  level: 'info',
  data: { gateway: 'Stripe', amount: 5000 }
});
```

## 6. Error Boundaries & Graceful Degradation

If a React component throws an error, the entire screen will unmount and white-screen. This is unacceptable.

- **`Sentry.ErrorBoundary`**: Wrap critical sections (or entire screens) in a Sentry Error Boundary to catch render errors, report them, and show a fallback UI instead of crashing the app.

```typescript
// ✅ ALWAYS: Protect screens with Error Boundaries
import * as Sentry from '@sentry/react-native';

<Sentry.ErrorBoundary fallback={<ErrorScreen />}>
  <ComplexDashboard />
</Sentry.ErrorBoundary>
```

## 7. Performance Tracing

Crashes aren't the only problem. Slow screens kill retention.

- **React Navigation Integration**: Use `Sentry.ReactNavigationInstrumentation` to trace exactly how long it takes for a screen to mount and render.
- **Manual Spans**: If you have a complex local database migration or image processing task, wrap it in a custom transaction and span.
- **Sample Rate**: Never use `tracesSampleRate: 1.0` in production for apps with scale; it will blow up your Sentry quota. Use a lower rate (e.g., `0.1` for 10%) or use `tracesSampler` to specifically trace 100% of the checkout flow but only 5% of the feed.

## 8. Handled vs Unhandled Exceptions

- **Unhandled Exceptions**: Sentry catches these automatically (the app crashed).
- **Handled Exceptions**: When you `catch` an error in a `try/catch` block, the app survives. You MUST manually report this to Sentry if it represents a systemic failure (e.g., an API consistently failing).

```typescript
// ✅ ALWAYS: Report critical handled exceptions
try {
  await processPayment();
} catch (error) {
  // We caught it, so the app won't crash, but we still need to know!
  Sentry.captureException(error, {
    tags: { context: 'payment_processing' }
  });
  showErrorToast('Payment failed');
}
```

## 9. Dealing with the Noise

Sentry becomes useless if it becomes an inbox of spam.
- **Ignore Network Errors**: Do not log `TypeError: Network request failed` as exceptions. Users lose internet all the time; this is not a bug.
- **Filtering**: Use `ignoreErrors` in `Sentry.init` for known, un-actionable third-party library noise.

---

**Execution Protocol**
1. **Source Map Verification**: No release goes out without verifying that Source Maps are successfully uploading. A crash without a source map is a wasted crash.
2. **Alerting**: Configure Slack/PagerDuty alerts for spikes in crashes or when critical tags (e.g., `tag:checkout_failure`) trigger.
3. **Clean Up**: Always call `Sentry.setUser(null)` on logout to prevent subsequent errors from being attributed to the wrong user.

---
name: flutter-security
description: >
  Security specialist focused on data integrity and secure storage.
  Trigger: When handling sensitive data, tokens, or encryption in Flutter.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Secure Storage (REQUIRED)

Secrets must never be stored in plain text.

```dart
// ✅ ALWAYS: Flutter Secure Storage with native options
const secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// ❌ NEVER: SharedPreferences for sensitive data
// Forbidden: storing auth tokens or personal info in 'shared_preferences'.
```

---

## Keychain & Keystore (REQUIRED)

Leverage platform-specific security enhancements.

| Platform | Recommended Config |
|----------|--------------------|
| **iOS** | `KeychainAccessibility.attrAccessibleAfterFirstUnlock` |
| **Android** | Hardware-backed Keystore (API 23+) |

---

## Session Lifecycle (REQUIRED)

Clean up sensitive data as soon as possible.

```dart
// ✅ ALWAYS: Auto-Eviction and Try-Catch
try {
  await storage.delete(key: 'auth_token');
} catch (e) {
  // Silent logs (no secrets)
}

// ❌ NEVER: Global memory exposure
// Do not keep sensitive variables in global scope; clear after use.
```

---

## Execution Protocol (REQUIRED)

1. **Initialize**: Set global options for `FlutterSecureStorage`.
2. **Encapsulate**: Create a `SecurityService` to abstract all operations.
3. **Audit**: Verify if the data really needs to be persisted or if it can be ephemeral.
4. **Review**: Ensure no secrets are printed to the console in production.

---

## Uncompromising Constraints

- **No SharedPrefs**: Authentication tokens and passwords must never touch SharedPreferences.
- **Log Safety**: Never expose sensitive values in `print()` or logging frameworks.
- **Error Handling**: Every secure storage operation must be wrapped in `try-catch`.

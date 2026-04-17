---
name: flutter-biometrics
description: >
  Expert in implementing robust and reliable biometric authentication (Face ID, Fingerprint).
  Trigger: When adding or configuring biometric authentication layers in Flutter.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Biometric Pipeline (REQUIRED)

Verify hardware support before any action.

```dart
// ✅ ALWAYS: Verify support and handle enrollment
final isSupported = await auth.isDeviceSupported();
final canCheck = await auth.canCheckBiometrics;

// ❌ NEVER: Assuming support
// Do not attempt authentication without checking 'canCheckBiometrics'.
```

---

## Military-Grade Error Handling (REQUIRED)

Capture and process specific native errors.

| Error Code | Meaning |
|------------|---------|
| `notAvailable` | Hardware is not present. |
| `notEnrolled` | No biometric data registered. |
| `lockedOut` | Temporary lockout (too many attempts). |
| `permanentlyLockedOut` | PIN/Pattern required for unlock. |

---

## Security & Privacy (REQUIRED)

Authentication must be persistent and secure.

```dart
// ✅ ALWAYS: Sticky Auth and Native Dialog L10n
final authenticated = await auth.authenticate(
  localizedReason: context.l10n.authReason,
  options: const AuthenticationOptions(stickyAuth: true),
);

// ❌ NEVER: Hardcoded messages or insecure fallbacks
// Prohibited: leaving authentication logic directly in Widgets.
```

---

## Execution Protocol (REQUIRED)

1. **Plugin Audit**: Ensure `local_auth` is up to date.
2. **Service Abstraction**: Create a clean `BiometricService` for all logic.
3. **Fallback Flow**: Always provide PIN/Password alternative.
4. **Audit Logs**: Record attempts (non-sensitive data only).

---

## Uncompromising Constraints

- **Error Handling**: Never assume success; always wrap in `try-catch` blocks.
- **Localization**: All native dialog strings must be pulled from `l10n`.
- **Separation**: Authentication logic must be isolated from UI Widgets.

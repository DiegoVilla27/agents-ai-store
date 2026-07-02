---
name: flutter-biometrics
description: The ultimate architectural standard for Enterprise Biometrics in Flutter Secure Enclave integration, Sticky Auth, Fallback Strategies, and Native Configurations.
author: Diego Villanueva
trigger: When implementing FaceID, TouchID, local authentication, or securing sensitive data on the device.
---

# Flutter Biometrics & Secure Authentication

Biometric authentication (FaceID / Fingerprint) is **NOT** a primary authentication mechanism. It is a convenience layer. Biometrics do not talk to your backend; they simply unlock the device's Secure Enclave / Keystore so the app can retrieve a previously stored session token (JWT/Refresh Token).

If you implement `local_auth` without understanding this, you are creating a massive security vulnerability.

## 1. Native Configuration (CRITICAL)

Before writing a single line of Dart, you MUST configure the native platforms. If you forget this, the app will crash instantly on iOS or fail silently on Android.

### iOS (`ios/Runner/Info.plist`)
You must explain *why* you need FaceID, or Apple will reject the app.
```xml
<!-- ✅ ALWAYS: Add FaceID Usage Description -->
<key>NSFaceIDUsageDescription</key>
<string>We need FaceID to securely authenticate you into your account without requiring a password.</string>
```

### Android (`android/app/src/main/AndroidManifest.xml`)
Android requires explicit permission to use the biometric hardware.
```xml
<!-- ✅ ALWAYS: Add Biometric Permission -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```
*(Additionally, your `MainActivity.kt` MUST extend `FlutterFragmentActivity`, not `FlutterActivity`, or the Android biometric dialog will crash).*

## 2. The Biometric Pipeline (Defense in Depth)

You cannot simply call `authenticate()`. You must verify the hardware exists, verify the user has enrolled their face/finger, and handle the myriad of native errors.

```dart
// ✅ ALWAYS: Implement a robust verification pipeline
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticateUser() async {
    try {
      // 1. Does the device have hardware?
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) throw BiometricException('Device not supported');

      // 2. Has the user actually enrolled FaceID/Fingerprint in OS settings?
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) throw BiometricException('Biometrics not enrolled. Please setup in Settings.');

      // 3. Perform the actual authentication
      return await _auth.authenticate(
        localizedReason: 'Scan your face to access your bank account',
        options: const AuthenticationOptions(
          // 4. CRITICAL: stickyAuth must be true for Android lifecycle
          stickyAuth: true, 
          // 5. Force biometrics, do not allow OS pin/pattern fallback if strict security is needed
          biometricOnly: true, 
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      _handlePlatformError(e);
      return false;
    }
  }

  void _handlePlatformError(PlatformException e) {
    switch (e.code) {
      case 'NotEnrolled':
        // Prompt user to go to OS Settings
        break;
      case 'LockedOut':
        // Too many failed attempts. OS requires PIN unlock.
        break;
      case 'PermanentlyLockedOut':
        // Extreme lockout.
        break;
      default:
        // Log to Crashlytics
        break;
    }
  }
}
```

## 3. The `stickyAuth` Rule (Android Lifecycle)

On Android, when the biometric dialog opens, the Flutter app is technically pushed to the "Background" lifecycle state. If `stickyAuth` is `false` (the default), the authentication will immediately fail and cancel itself.

- **❌ NEVER**: Leave `AuthenticationOptions` empty.
- **✅ ALWAYS**: Set `stickyAuth: true` so the dialog persists when the app goes background and returns to the foreground.

## 4. The "Biometrics Changed" Vulnerability

Imagine this scenario:
1. User logs into your app with FaceID.
2. The user's malicious friend knows the device PIN (1234).
3. The friend goes to iOS Settings, enters the PIN, and registers *their own* face.
4. The friend opens your app, their face is recognized, and they drain the bank account.

To prevent this, you must tie the biometric authentication to cryptographic keys in the Secure Enclave. If the biometric set changes, the keys are invalidated.

```dart
// ✅ ALWAYS: Use flutter_secure_storage with biometric binding for high-security apps
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

// Saving the token
await storage.write(
  key: 'refresh_token',
  value: 'my_secret_token',
  iOptions: const IOSOptions(
    // CRITICAL: If a new Face is added to the iPhone, this token is permanently destroyed.
    accessibility: KeychainAccessibility.passcodeSetThisDeviceOnly,
  ),
  aOptions: const AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);
```

## 5. The Application-Level Fallback

Biometrics fail. Masks, wet fingers, or hardware glitches will frustrate users.

- **❌ NEVER**: Trap the user in a "Biometrics Only" screen with no escape.
- **✅ ALWAYS**: Provide a "Login with Password" or "Use App PIN" button directly below the biometric prompt.

```dart
// Architectural Flow:
// 1. App starts -> check secure storage for token.
// 2. Token exists -> Prompt Biometrics.
// 3. Biometrics Success -> Load Dashboard.
// 4. Biometrics Fail / Cancelled -> Show Password Input Screen.
```

---

**Execution Protocol**
1. **Never test on Simulators**: Biometrics behave wildly differently on physical hardware. You must test `local_auth` on a real iPhone and a real Android device.
2. **Android MainActivity**: Ensure `android/app/src/main/kotlin/.../MainActivity.kt` extends `FlutterFragmentActivity`. If it extends `FlutterActivity`, the `local_auth` package will crash the app silently upon execution.
3. **L10n (Localization)**: The `localizedReason` string in `authenticate()` must be translated using your app's i18n system. "Scan to login" must be "Escanea para entrar" in Spanish.

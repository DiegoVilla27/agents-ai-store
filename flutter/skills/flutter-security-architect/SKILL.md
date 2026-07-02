---
name: flutter-security-architect
description: The ultimate architectural standard for Enterprise Flutter Security Secure Storage, SSL Certificate Pinning, Code Obfuscation, and Jailbreak Detection.
author: Diego Villanueva
trigger: When handling sensitive data, authenticating users, storing tokens, or preparing a release build.
---

# Enterprise Flutter Security Architecture

A mobile application is a hostile environment. An attacker can download your APK/IPA, decompile it to read your Dart code, attach a debugger to read the device's RAM, or set up a proxy (Charles/Burp Suite) to intercept your API calls.

If you treat a mobile app like a web browser, your users' data will be compromised. You MUST implement Defense in Depth.

## 1. Secure Storage (The Keychain & Keystore)

**❌ NEVER** store JWTs, Refresh Tokens, Passwords, or PII (Personally Identifiable Information) in `SharedPreferences`. `SharedPreferences` saves data in plain XML files on the device. On a rooted Android device, anyone can read it.

**✅ ALWAYS** use `flutter_secure_storage`. It uses the iOS Keychain and the Android Keystore to encrypt data using hardware-backed keys.

```dart
// ✅ ALWAYS: Configure Secure Storage with strict native parameters
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const secureStorage = FlutterSecureStorage(
  // iOS: Require the device to be unlocked to read the token.
  // If strict biometrics are used, change to passcodeSetThisDeviceOnly
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
  // Android: Force EncryptedSharedPreferences (AES-256) instead of RSA
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);

// Saving a token
await secureStorage.write(key: 'refresh_token', value: token);
```

## 2. SSL/TLS Certificate Pinning (MITM Protection)

By default, an app trusts any SSL certificate signed by a Root CA on the device. An attacker can install a fake Root CA on their phone, route your app through a proxy, and read all your HTTPS traffic (including passwords) in plain text.

To prevent Man-in-the-Middle (MITM) attacks, you MUST pin the server's public key hash in your HTTP Client (Dio).

```dart
// ✅ ALWAYS: Pin the Server's SHA-256 Certificate Hash
import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://api.mybank.com'));

dio.interceptors.add(
  CertificatePinningInterceptor(
    allowedSHAFingerprints: [
      // The SHA-256 hash of your server's public key. 
      // If the attacker uses a proxy, the proxy's fake certificate will have a different hash!
      '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8', 
      // ALWAYS include a backup pin for when your SSL certificate expires and rotates
      'backup_pin_hash_here'
    ],
  ),
);
```

## 3. Jailbreak & Root Detection (RASP)

If a device is jailbroken (iOS) or rooted (Android), the OS security sandbox is destroyed. Malware on the device can read your app's memory and steal tokens.

Enterprise apps (Banking, Healthcare) MUST use RASP (Runtime Application Self-Protection) tools like `freerasp` or `flutter_jailbreak_detection`.

```dart
// ✅ ALWAYS: Crash or block the app if the OS is compromised
import 'package:freerasp/freerasp.dart';

void initSecurity() {
  final config = TalsecConfig(
    androidConfig: AndroidConfig(
      packageName: 'com.acme.enterprise',
      signingCertHashes: ['YOUR_RELEASE_KEY_HASH'], // Prevents APK repacking
    ),
    iosConfig: IOSConfig(
      bundleIds: ['com.acme.enterprise'],
      teamId: 'YOUR_APPLE_TEAM_ID',
    ),
    watcherMail: 'security@acme.com',
  );

  final callback = ThreatCallback(
    onPrivilegeEscalation: () => _forceCrash('Device Rooted/Jailbroken'),
    onSimulator: () => _forceCrash('Running on Emulator'),
    onDebugger: () => _forceCrash('Debugger attached'),
    onTamper: () => _forceCrash('APK has been modified'),
  );

  Talsec.instance.start(config);
  Talsec.instance.attachListener(callback);
}

void _forceCrash(String reason) {
  // Erase all tokens immediately
  secureStorage.deleteAll();
  // Exit the app
  exit(0); 
}
```

## 4. Code Obfuscation (Dart Release Builds)

If you build an APK normally, anyone can decompile it and read your hardcoded API Keys, URL endpoints, and business logic.

You MUST build for release using the `--obfuscate` flag. This scrambles class names, function names, and makes reverse engineering significantly harder.

```bash
# ✅ ALWAYS: Build with obfuscation and save the debug symbols
flutter build apk --release \
  --obfuscate \
  --split-debug-info=./build/app/outputs/symbols
```
*(Keep the `symbols` folder safe. If the app crashes in production, Crashlytics will show you scrambled garbage unless you upload these symbols to translate the error back to readable Dart code).*

## 5. In-Memory Security (Variables)

If you store a user's password or Social Security Number in a global variable (e.g., a Riverpod Notifier), it lives in RAM. If the phone is compromised, RAM can be dumped.

- **❌ NEVER**: Store highly sensitive data in state indefinitely.
- **✅ ALWAYS**: Clear variables immediately after use.

```dart
// ✅ ALWAYS: Clear sensitive data from RAM instantly
Future<void> submitSSN(String ssn) async {
  await api.post('/ssn', data: {'ssn': ssn});
  
  // Overwrite the string in memory immediately after it is sent
  ssn = '000000000'; 
}
```

---

**Execution Protocol**
1. **API Keys in Code**: NEVER hardcode API keys (like Google Maps or Stripe keys) in Dart files. Use `.env` files with `flutter_dotenv` or inject them at compile time using `--dart-define=API_KEY=123`.
2. **Screenshots & App Switcher**: When the user backgrounds the app (App Switcher), the OS takes a screenshot of the app. If the screen showed a bank balance, it is now saved in the phone's unencrypted gallery. Use `flutter_windowmanager` (Android) or native iOS code to blur the screen or block screenshots when the app goes to the background.

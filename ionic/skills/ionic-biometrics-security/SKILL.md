---
name: ionic-biometrics-security
description: The ultimate architectural standard for Enterprise Security, Biometric Authentication (FaceID/TouchID/Fingerprint), Keyring/Keystore, SSL Pinning, and Anti-Tampering in Ionic/Capacitor.
author: Diego Villanueva
trigger: When implementing biometric authentication, securing auth tokens, enforcing SSL certificate pinning, or hardening Ionic/Capacitor apps against reverse-engineering and data leaks.
---

# Enterprise Ionic Biometrics & Security Architecture

Hybrid applications face unique security challenges: client-side JavaScript source inspection, WebView vulnerabilities, unsecured device storage, and Man-in-the-Middle (MITM) attacks. An Enterprise Ionic Architect treats security as non-negotiable.

---

## 1. Biometric Authentication (`@capgo/capacitor-native-biometric`)

Biometric authentication must be hardware-backed (iOS Secure Enclave / Android Trusted Execution Environment (TEE)).

**❌ NEVER** store a boolean flag like `localStorage.setItem('isAuthenticated', 'true')` after FaceID succeeds.
**✅ ALWAYS** tie biometric verification to the retrieval of cryptographic credentials stored in hardware-backed secure storage.

```typescript
// core/security/biometrics.service.ts
import { Injectable, signal } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import {
  NativeBiometric,
  BiometryType,
} from '@capgo/capacitor-native-biometric';

export interface BiometricCapability {
  isAvailable: boolean;
  biometryType: BiometryType;
  reason?: string;
}

@Injectable({ providedIn: 'root' })
export class BiometricsService {
  private readonly isNative = Capacitor.isNativePlatform();
  readonly isBiometricsAvailable = signal(false);
  readonly biometryType = signal<BiometryType>(BiometryType.NONE);

  async checkBiometrics(): Promise<BiometricCapability> {
    if (!this.isNative) {
      return { isAvailable: false, biometryType: BiometryType.NONE, reason: 'Web platform unsupported' };
    }

    try {
      const result = await NativeBiometric.isAvailable();
      this.isBiometricsAvailable.set(result.isAvailable);
      this.biometryType.set(result.biometryType);

      return {
        isAvailable: result.isAvailable,
        biometryType: result.biometryType,
      };
    } catch (error) {
      this.isBiometricsAvailable.set(false);
      return { isAvailable: false, biometryType: BiometryType.NONE, reason: (error as Error).message };
    }
  }

  async verifyIdentity(title = 'Authenticate', subtitle = 'Confirm your identity to proceed'): Promise<boolean> {
    if (!this.isNative) return true; // Development web fallback (never for prod tokens)

    try {
      await NativeBiometric.verifyIdentity({
        reason: subtitle,
        title,
        subtitle,
        description: 'Biometric scan is required to access sensitive resources',
        useFallback: true, // Allow device passcode if biometrics fail
      });
      return true;
    } catch {
      return false;
    }
  }

  async saveSecureCredentials(server: string, username: string, token: string): Promise<void> {
    if (!this.isNative) return;

    await NativeBiometric.setCredentials({
      server,
      username,
      password: token,
    });
  }

  async getSecureCredentials(server: string): Promise<{ username: string; token: string } | null> {
    if (!this.isNative) return null;

    try {
      const creds = await NativeBiometric.getCredentials({ server });
      return { username: creds.username, token: creds.password };
    } catch {
      return null;
    }
  }
}
```

---

## 2. Hardware-Backed Secure Storage

Sensitive secrets (OAuth refresh tokens, JWTs, private keys) MUST be placed into the iOS Keychain and Android Keystore.

```typescript
// core/security/secure-vault.service.ts
import { Injectable } from '@angular/core';
import { SecureStoragePlugin } from '@capacitor-community/secure-storage';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class SecureVaultService {
  private readonly isNative = Capacitor.isNativePlatform();

  async setSecret(key: string, value: string): Promise<void> {
    if (this.isNative) {
      await SecureStoragePlugin.set({ key, value });
    } else {
      // In-memory fallback during web dev; never use localStorage in production
      sessionStorage.setItem(`__sec_${key}`, value);
    }
  }

  async getSecret(key: string): Promise<string | null> {
    if (this.isNative) {
      try {
        const { value } = await SecureStoragePlugin.get({ key });
        return value;
      } catch {
        return null;
      }
    }
    return sessionStorage.getItem(`__sec_${key}`);
  }

  async clearVault(): Promise<void> {
    if (this.isNative) {
      await SecureStoragePlugin.clear();
    } else {
      sessionStorage.clear();
    }
  }
}
```

---

## 3. SSL / TLS Certificate Pinning

To prevent Man-in-the-Middle (MITM) attacks (e.g. proxying via Charles / Burp Suite), Enterprise Ionic applications MUST implement SSL Pinning on native requests.

Using `@capacitor-community/http` or `@capgo/capacitor-native-http`:

```typescript
// capacitor.config.ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.enterprise.banking',
  appName: 'SecureBank',
  webDir: 'www',
  server: {
    androidScheme: 'https',
  },
  plugins: {
    CapacitorHttp: {
      enabled: true,
    },
  },
};

export default config;
```

---

## 4. App Privacy Screen (Background Blur)

When switching apps on iOS/Android, the OS takes a snapshot of the screen. If sensitive banking or PII data is visible, it leaks into the app switcher previews.

```typescript
// core/security/privacy-screen.service.ts
import { Injectable } from '@angular/core';
import { PrivacyScreen } from '@capacitor-community/privacy-screen';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class PrivacyScreenService {
  async enablePrivacyProtection(): Promise<void> {
    if (!Capacitor.isNativePlatform()) return;
    
    // Automatically obscures app window in iOS task manager & blocks Android screenshots
    await PrivacyScreen.enable();
  }

  async disablePrivacyProtection(): Promise<void> {
    if (!Capacitor.isNativePlatform()) return;
    await PrivacyScreen.disable();
  }
}
```

---

## 5. Security Checklist for Enterprise Builds

1. **Disable WebView Debugging**: In `MainActivity.java`, ensure `WebView.setWebContentsDebuggingEnabled(false)` in release builds.
2. **Disable Cleartext Traffic**: Ensure `android:usesCleartextTraffic="false"` in `AndroidManifest.xml`.
3. **No Root / Jailbreak execution**: Use `@capgo/capacitor-native-biometric` or custom native checks to detect compromised devices.
4. **Remove Source Maps**: Ensure `sourceMap: false` in `angular.json` for production builds.

---

**Execution Protocol**
1. **Never persist tokens in `localStorage` or standard `Preferences`**: Always use `SecureStoragePlugin` or `NativeBiometric.setCredentials`.
2. **Always enable PrivacyScreen for fintech/healthcare apps**: Prevents snapshot leaks in the mobile task switcher.
3. **Always handle biometric fallback**: If biometric hardware fails or is cancelled, provide a secure PIN/Passcode alternative.
4. **Always wipe secure storage on logout**: Ensure tokens and encryption keys are completely deleted on user sign-out.

---
name: react-native-biometrics-secure-store
description: The ultimate architectural standard for Biometric Authentication (FaceID / TouchID) and Secure Credential Storage in React Native with expo-local-authentication and expo-secure-store.
author: Diego Villanueva
trigger: When implementing FaceID, TouchID, fingerprint scanning, securing JWT tokens, or using expo-secure-store / expo-local-authentication.
---

# Enterprise React Native Biometrics & Secure Storage Architecture

Storing secrets (JWT refresh tokens, encryption keys, PINs) in unencrypted storage (`AsyncStorage` or plain `MMKV`) exposes users to device extraction attacks. Enterprise mobile security mandates **Hardware Keystore / iOS Keychain** storage (`expo-secure-store`) paired with **Biometric Authentication** (`expo-local-authentication`).

---

## 1. Biometric Authentication Service (`expo-local-authentication`)

```bash
npx expo install expo-local-authentication expo-secure-store
```

```typescript
// src/services/biometrics.service.ts
import * as LocalAuthentication from 'expo-local-authentication';

export class BiometricsService {
  static async checkBiometricAvailability(): Promise<{
    hasHardware: boolean;
    isEnrolled: boolean;
    biometricTypes: LocalAuthentication.AuthenticationType[];
  }> {
    const hasHardware = await LocalAuthentication.hasHardwareAsync();
    const isEnrolled = await LocalAuthentication.isEnrolledAsync();
    const biometricTypes = await LocalAuthentication.supportedAuthenticationTypesAsync();

    return { hasHardware, isEnrolled, biometricTypes };
  }

  static async authenticateUser(promptMessage = 'Confirm your identity to unlock'): Promise<boolean> {
    const { hasHardware, isEnrolled } = await this.checkBiometricAvailability();

    if (!hasHardware || !isEnrolled) {
      return false;
    }

    const result = await LocalAuthentication.authenticateAsync({
      promptMessage,
      fallbackLabel: 'Enter Passcode',
      disableDeviceFallback: false,
      cancelLabel: 'Cancel',
    });

    return result.success;
  }
}
```

---

## 2. Secure Storage Engine (`expo-secure-store`)

```typescript
// src/services/secure-storage.service.ts
import * as SecureStore from 'expo-secure-store';

const SECURE_STORE_OPTIONS: SecureStore.SecureStoreOptions = {
  keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY, // iOS: Hardware Enclave Protection
};

export class SecureStorageService {
  static async saveToken(key: string, value: string): Promise<void> {
    await SecureStore.setItemAsync(key, value, SECURE_STORE_OPTIONS);
  }

  static async getToken(key: string): Promise<string | null> {
    return await SecureStore.getItemAsync(key, SECURE_STORE_OPTIONS);
  }

  static async deleteToken(key: string): Promise<void> {
    await SecureStore.deleteItemAsync(key, SECURE_STORE_OPTIONS);
  }
}
```

---

## 3. Biometric Quick-Unlock Hook Flow

```tsx
// src/features/auth/hooks/use-biometric-unlock.ts
import { useState, useCallback } from 'react';
import { BiometricsService } from '@/services/biometrics.service';
import { SecureStorageService } from '@/services/secure-storage.service';
import { useAuthStore } from '@/store/auth.store';
import { router } from 'expo-router';

export function useBiometricUnlock() {
  const [isAuthenticating, setIsAuthenticating] = useState(false);
  const setAccessToken = useAuthStore((s) => s.setAccessToken);

  const unlockWithBiometrics = useCallback(async () => {
    setIsAuthenticating(true);
    try {
      const success = await BiometricsService.authenticateUser('Log into Enterprise App');

      if (success) {
        // Retrieve hardware-locked refresh token
        const refreshToken = await SecureStorageService.getToken('user_refresh_token');

        if (refreshToken) {
          // Exchange for fresh access token via API
          const newAccessToken = await authApi.refresh(refreshToken);
          setAccessToken(newAccessToken);
          router.replace('/(tabs)');
        }
      }
    } finally {
      setIsAuthenticating(false);
    }
  }, [setAccessToken]);

  return { unlockWithBiometrics, isAuthenticating };
}
```

---

**Execution Protocol**
1. **Never store refresh tokens or API keys in standard AsyncStorage**: Always use `SecureStore` with `WHEN_UNLOCKED_THIS_DEVICE_ONLY`.
2. **Always provide a passcode fallback**: Users with wet fingers or face masks must have a graceful PIN alternative.
3. **Handle biometric revocation**: If the user enrolls a new fingerprint in iOS settings, invalidate previously cached biometric keys.

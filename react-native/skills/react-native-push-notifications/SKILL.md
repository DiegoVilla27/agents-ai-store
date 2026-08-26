---
name: react-native-push-notifications
description: The ultimate architectural standard for Enterprise Push Notifications in React Native with expo-notifications, FCM, APNs, Background Tasks, and Expo Router Deep Linking.
author: Diego Villanueva
trigger: When configuring push notifications in React Native/Expo, handling background notifications, configuring FCM/APNs tokens, or routing from notification payloads.
---

# Enterprise React Native Push Notifications Architecture

Mobile push notifications require permission flows, Android Notification Channel categorization, token synchronization with backends, background task registration, and deep-link routing via **Expo Router**.

---

## 1. Notification Service Architecture (`expo-notifications`)

```bash
npx expo install expo-notifications expo-device
```

```typescript
// src/services/notifications.service.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';
import { router } from 'expo-router';

// Configure foreground presentation behavior
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export class PushNotificationService {
  static async registerForPushNotifications(): Promise<string | null> {
    if (!Device.isDevice) {
      console.warn('Push notifications require a physical device');
      return null;
    }

    // 1. Android Notification Channel Configuration
    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync('high_importance', {
        name: 'High Importance Alerts',
        importance: Notifications.AndroidImportance.MAX,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: '#38bdf8',
      });
    }

    // 2. Request Permissions
    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }

    if (finalStatus !== 'granted') {
      console.warn('Failed to obtain push notification permission');
      return null;
    }

    // 3. Get Expo / FCM Push Token
    const tokenData = await Notifications.getExpoPushTokenAsync({
      projectId: process.env.EXPO_PUBLIC_PROJECT_ID,
    });

    return tokenData.data;
  }

  static initializeListeners() {
    // A. Foreground Notification Received Listener
    const receivedSubscription = Notifications.addNotificationReceivedListener((notification) => {
      console.log('📥 Notification Received in Foreground:', notification.request.content);
    });

    // B. User Tapped Notification (Background or Cold-Start Response)
    const responseSubscription = Notifications.addNotificationResponseReceivedListener((response) => {
      const data = response.notification.request.content.data;
      if (data?.route) {
        // Declarative navigation with Expo Router!
        router.push(data.route); // e.g. "/orders/ord_123"
      }
    });

    return () => {
      receivedSubscription.remove();
      responseSubscription.remove();
    };
  }
}
```

---

## 2. Root Provider Integration (`app/_layout.tsx`)

```tsx
// app/_layout.tsx
import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { PushNotificationService } from '@/services/notifications.service';
import { useAuthStore } from '@/store/auth.store';

export default function RootLayout() {
  const syncPushToken = useAuthStore((s) => s.syncPushToken);

  useEffect(() => {
    // 1. Register and send token to server
    PushNotificationService.registerForPushNotifications().then((token) => {
      if (token) syncPushToken(token);
    });

    // 2. Setup listeners for tap events
    const cleanup = PushNotificationService.initializeListeners();
    return cleanup;
  }, [syncPushToken]);

  return <Stack screenOptions={{ headerShown: false }} />;
}
```

---

## 3. Background Task Registration (`expo-task-manager`)

To execute code when a silent data-only push notification arrives in the background:

```typescript
// src/services/background-notifications.ts
import * as TaskManager from 'expo-task-manager';
import * as Notifications from 'expo-notifications';

const BACKGROUND_NOTIFICATION_TASK = 'BACKGROUND_NOTIFICATION_TASK';

TaskManager.defineTask(BACKGROUND_NOTIFICATION_TASK, async ({ data, error, executionInfo }) => {
  if (error) {
    console.error('Background notification task error:', error);
    return;
  }

  const notification = (data as any)?.notification;
  console.log('🌙 Processing background notification:', notification?.data);
  // Perform background sync with local MMKV or SQLite database
});

Notifications.registerTaskAsync(BACKGROUND_NOTIFICATION_TASK);
```

---

**Execution Protocol**
1. **Always test push notifications on physical devices**: Simulators cannot receive standard APNs or FCM push tokens.
2. **Never hardcode notification titles or messages in background handlers**: Read localized strings from payloads.
3. **Always route through Expo Router**: Decouple notification clicks from hardcoded view state changes.

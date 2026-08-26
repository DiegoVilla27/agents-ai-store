---
name: ionic-push-notifications
description: The ultimate architectural standard for Push Notifications with Firebase Cloud Messaging, Capacitor Push Plugin, In-App Handling, and Deep Link Integration.
author: Diego Villanueva
trigger: When implementing push notifications, configuring FCM, handling notification actions, or routing users from notifications.
---

# Enterprise Ionic Push Notifications Architecture

Push notifications are critical for user engagement in mobile apps. Ionic with Capacitor provides native push notification support via Firebase Cloud Messaging (FCM) for Android and Apple Push Notification Service (APNs) for iOS.

## 1. Setup & Configuration

```bash
npm install @capacitor/push-notifications
npx cap sync
```

### Firebase Configuration
- **Android**: Place `google-services.json` in `android/app/`
- **iOS**: Place `GoogleService-Info.plist` in `ios/App/App/`

## 2. Push Notification Service

```typescript
// core/plugins/push-notification.service.ts
import { Injectable, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Capacitor } from '@capacitor/core';
import {
  PushNotifications,
  PushNotificationSchema,
  ActionPerformed,
  Token,
} from '@capacitor/push-notifications';

@Injectable({ providedIn: 'root' })
export class PushNotificationService {
  private readonly router = inject(Router);
  private readonly api = inject(ApiService);
  readonly token = signal<string | null>(null);
  readonly notifications = signal<PushNotificationSchema[]>([]);

  async initialize(): Promise<void> {
    if (!Capacitor.isNativePlatform()) return;

    // Step 1: Request permission
    const permission = await PushNotifications.requestPermissions();
    if (permission.receive !== 'granted') {
      console.warn('Push notification permission denied');
      return;
    }

    // Step 2: Register with FCM/APNs
    await PushNotifications.register();

    // Step 3: Listen for registration success
    PushNotifications.addListener('registration', async (token: Token) => {
      this.token.set(token.value);
      // Send token to your backend
      await this.api.post('/api/devices/register', {
        token: token.value,
        platform: Capacitor.getPlatform(),
      });
    });

    // Step 4: Handle registration error
    PushNotifications.addListener('registrationError', (error) => {
      console.error('Push registration failed:', error);
    });

    // Step 5: Handle notification received while app is in foreground
    PushNotifications.addListener('pushNotificationReceived', (notification) => {
      this.notifications.update(list => [notification, ...list]);
      this.showInAppNotification(notification);
    });

    // Step 6: Handle notification tapped (app was in background/killed)
    PushNotifications.addListener('pushNotificationActionPerformed', (action: ActionPerformed) => {
      const data = action.notification.data;
      this.handleNotificationNavigation(data);
    });
  }

  private async showInAppNotification(notification: PushNotificationSchema): Promise<void> {
    const toastCtrl = inject(ToastController);
    const toast = await toastCtrl.create({
      header: notification.title ?? 'New Notification',
      message: notification.body ?? '',
      duration: 4000,
      position: 'top',
      buttons: [
        {
          text: 'View',
          handler: () => this.handleNotificationNavigation(notification.data),
        },
      ],
    });
    await toast.present();
  }

  private handleNotificationNavigation(data: Record<string, unknown>): void {
    // Route based on notification payload
    if (data['type'] === 'order') {
      this.router.navigateByUrl(`/tabs/orders/detail/${data['orderId']}`);
    } else if (data['type'] === 'message') {
      this.router.navigateByUrl(`/tabs/chat/${data['chatId']}`);
    } else if (data['url']) {
      this.router.navigateByUrl(data['url'] as string);
    }
  }

  async getBadgeCount(): Promise<number> {
    const result = await PushNotifications.getDeliveredNotifications();
    return result.notifications.length;
  }

  async clearBadge(): Promise<void> {
    await PushNotifications.removeAllDeliveredNotifications();
  }
}
```

## 3. Local Notifications (Scheduled)

For reminders, alarms, or locally-triggered notifications:

```typescript
import { LocalNotifications } from '@capacitor/local-notifications';

@Injectable({ providedIn: 'root' })
export class LocalNotificationService {
  async schedule(title: string, body: string, delayMinutes: number): Promise<void> {
    await LocalNotifications.schedule({
      notifications: [
        {
          id: Date.now(),
          title,
          body,
          schedule: { at: new Date(Date.now() + delayMinutes * 60 * 1000) },
          actionTypeId: 'OPEN_APP',
          extra: { route: '/tabs/reminders' },
        },
      ],
    });
  }

  async cancelAll(): Promise<void> {
    const pending = await LocalNotifications.getPending();
    if (pending.notifications.length > 0) {
      await LocalNotifications.cancel(pending);
    }
  }
}
```

## 4. Notification Channel Configuration (Android)

Android 8+ requires notification channels. Configure them during app initialization:

```typescript
async setupAndroidChannels(): Promise<void> {
  if (Capacitor.getPlatform() !== 'android') return;

  await PushNotifications.createChannel({
    id: 'orders',
    name: 'Order Updates',
    description: 'Notifications about order status changes',
    importance: 5, // Max importance
    visibility: 1, // Public
    sound: 'notification_sound',
    vibration: true,
    lights: true,
  });

  await PushNotifications.createChannel({
    id: 'promotions',
    name: 'Promotions',
    description: 'Special offers and deals',
    importance: 3, // Default
  });
}
```

---

**Execution Protocol**
1. **Always request permission before registering**: Never call `register()` without first checking `requestPermissions()`.
2. **Always send the device token to your backend**: The backend needs it to target push notifications.
3. **Always handle both foreground and background notifications**: Users expect different behavior (in-app toast vs app open).
4. **Always implement navigation from notifications**: Map notification payloads to specific routes.
5. **Always configure Android notification channels**: Required on Android 8+ or notifications will be silent.

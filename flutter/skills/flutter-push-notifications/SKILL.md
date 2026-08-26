---
name: flutter-push-notifications
description: The ultimate architectural standard for Enterprise Push Notifications in Flutter with Firebase Cloud Messaging (FCM), APNs on iOS, Android Channels, and GoRouter Deep Linking.
author: Diego Villanueva
trigger: When configuring push notifications in Flutter, handling background/foreground messages, setting up FCM/APNs, or routing from notification payloads.
---

# Enterprise Flutter Push Notifications Architecture (FCM & APNs)

Push notifications drive user retention, re-engagement, and urgent alerts. An Enterprise Flutter Architect ensures robust background message isolation, Android Notification Channel categorization, iOS APNs entitlement configuration, and declarative GoRouter payload navigation.

---

## 1. Core Service Architecture (`firebase_messaging`)

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0
```

```dart
// core/notifications/push_notification_service.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Top-level Background Handler (MUST be isolated from UI thread)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📥 [Background Message] ID: ${message.messageId}, Data: ${message.data}');
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final _notificationPayloadController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onPayloadTap => _notificationPayloadController.stream;

  Future<void> initialize() async {
    // 1. Request OS Permissions (Critical for iOS 13+ and Android 13+ POST_NOTIFICATIONS)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('⚠️ Push notifications permission denied or provisional');
      return;
    }

    // 2. Setup Android Notification Channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for critical transactional and security alerts',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 3. Initialize Local Notifications Plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          // Parse JSON payload and emit to router
          _notificationPayloadController.add({'route': response.payload});
        }
      },
    );

    // 4. Foreground Message Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message, androidChannel);
    });

    // 5. App Opened from Background / Terminated State
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _notificationPayloadController.add(message.data);
    });

    // Check if app launched from cold-start via notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _notificationPayloadController.add(initialMessage.data);
    }
  }

  void _showForegroundNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    final notification = message.notification;
    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        payload: message.data['route'],
      );
    }
  }

  Future<String?> getDeviceToken() async {
    return await _fcm.getToken();
  }
}
```

---

## 2. GoRouter Deep-Linking from Notification Payloads

```dart
// presentation/router/app_router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final notificationService = ref.watch(pushNotificationServiceProvider);

  // Listen to payload events and navigate declaratively
  notificationService.onPayloadTap.listen((data) {
    final targetRoute = data['route'];
    if (targetRoute != null) {
      appRouter.push(targetRoute); // e.g. '/orders/ord-992'
    }
  });

  return GoRouter(
    initialLocation: '/home',
    routes: [/* ... */],
  );
});
```

---

## 3. Platform Configurations

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

### iOS (`ios/Runner/AppDelegate.swift`)
Ensure `UNUserNotificationCenter.current().delegate = self` is declared to handle foreground presentation.

---

**Execution Protocol**
1. **Always declare `@pragma('vm:entry-point')` on background handlers**: Prevents Dart tree-shaking from stripping the handler function in release builds.
2. **Support Android 13+ Notification Runtime Permission**: Handle `POST_NOTIFICATIONS` gracefully.
3. **Always use GoRouter for payload transitions**: Keep navigation decoupled from raw Firebase callbacks.
4. **Send FCM tokens to backend on refresh**: Listen to `_fcm.onTokenRefresh` to sync active user device tokens with your server.

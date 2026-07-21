import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:plan_sync/core/util/logger.dart';

/// Push notifications are mobile-only: web would need a
/// firebase-messaging-sw.js service worker, and flutter_local_notifications
/// has no web implementation. Every entry point no-ops on web.
class NotificationService {
  static String? initialNotificationRoute;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final _initSettingsAndroid =
      const AndroidInitializationSettings('ic_launcher');
  final _initSettingsDarwin = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  Future<bool> needsPermission() async {
    if (kIsWeb) return false;
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus != AuthorizationStatus.authorized;
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: _initSettingsAndroid,
        iOS: _initSettingsDarwin,
      ),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;
    _initialized = true;

    Logger.i('FCM Token: ${await _messaging.getToken()}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.i('Foreground message received: ${message.messageId}');
      _localNotifications.show(
        id: message.hashCode,
        title: message.notification?.title,
        body: message.notification?.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Channel',
            channelDescription: 'Default channel for notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    Logger.i('Setting up background message handler');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.subscribeToTopic('core_notifications');
    Logger.i('Subscribed to core_notifications');
  }
}

void onDidReceiveNotificationResponse(NotificationResponse response) {
  if (response.payload != null) {
    Logger.i('Notification tapped with payload: ${response.payload}');
    NotificationService.initialNotificationRoute = response.data['route'];
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

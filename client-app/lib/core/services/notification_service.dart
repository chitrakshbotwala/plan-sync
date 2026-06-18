import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_sync/util/logger.dart';

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

  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;
    _initialized = true;

    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      if (!context.mounted) return;

      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'Notifications will be sent for class alerts. Would you like to enable notifications?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
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
          InitializationSettings(
            android: _initSettingsAndroid,
            iOS: _initSettingsDarwin,
          ),
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        );
      }
    }

    Logger.i('FCM Token: ${await _messaging.getToken()}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.i('Foreground message received: ${message.messageId}');
      _localNotifications.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        const NotificationDetails(
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

    Logger.i('Setting up background launch handler');
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!context.mounted) return;
      Logger.i('Message clicked!');
      _handleNotificationTap(context, message);
    });

    Logger.i('Setting up background message handler');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.subscribeToTopic('core_notifications');
    Logger.i('Subscribed to core_notifications');
  }

  void _handleNotificationTap(BuildContext context, RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) {
      context.go(route);
    }
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

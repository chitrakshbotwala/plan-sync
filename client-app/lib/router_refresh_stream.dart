import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:plan_sync/core/services/notification_service.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream() {
    notifyListeners();

    log('GoRouterRefreshStream getting initial message');
    FirebaseMessaging.instance.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) {
        final route = initialMessage.data['route'];
        NotificationService.initialNotificationRoute = route;
        log('Route from initial message: $route');
        notifyListeners();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'];
      if (route != null) {
        log('Message clicked, route: $route');
        NotificationService.initialNotificationRoute = route;
        notifyListeners();
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((event) {
      notifyListeners();
    });
  }
}

import 'package:flutter/material.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/controllers/app_tour_controller.dart';
import 'package:plan_sync/controllers/notification_controller.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required AppTourController appTour,
    required AppPreferencesController appPreferences,
    required NotificationController notifications,
  })  : _appTour = appTour,
        _appPreferences = appPreferences,
        _notifications = notifications;

  final AppTourController _appTour;
  final AppPreferencesController _appPreferences;
  final NotificationController _notifications;

  GlobalKey get schedulePreferencesButtonKey =>
      _appTour.schedulePreferencesButtonKey;

  void onReady(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) _appTour.startAppTour(context);
    });

    if (_appPreferences.getTutorialStatus() ?? false) {
      _notifications.initialize(context);
    }
  }
}

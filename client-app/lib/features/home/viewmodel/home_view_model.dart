import 'package:flutter/material.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/controllers/app_tour_controller.dart';
import 'package:plan_sync/core/services/notification_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required AppTourController appTour,
    required AppPreferencesController appPreferences,
    required NotificationService notifications,
  })  : _appTour = appTour,
        _appPreferences = appPreferences,
        _notifications = notifications;

  final AppTourController _appTour;
  final AppPreferencesController _appPreferences;
  final NotificationService _notifications;

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

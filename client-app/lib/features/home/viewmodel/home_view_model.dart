import 'package:flutter/material.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/controllers/app_tour_controller.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required AppTourController appTour,
    required AppPreferencesRepository appPreferences,
  })  : _appTour = appTour,
        _appPreferences = appPreferences;

  final AppTourController _appTour;
  final AppPreferencesRepository _appPreferences;

  GlobalKey get schedulePreferencesButtonKey =>
      _appTour.schedulePreferencesButtonKey;

  bool get shouldInitializeNotifications =>
      _appPreferences.getTutorialStatus() ?? false;

  void startAppTour(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) _appTour.startAppTour(context);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:plan_sync/core/models/hud_notices_model.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/services/app_tour_service.dart';
import 'package:plan_sync/core/services/notification_service.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required AppTourService appTour,
    required AppPreferencesRepository appPreferences,
    required RemoteConfigService remoteConfig,
    required NotificationService notifications,
  })  : _appTour = appTour,
        _appPreferences = appPreferences,
        _remoteConfig = remoteConfig,
        _notifications = notifications {
    _loadNotices();
  }

  final AppTourService _appTour;
  final AppPreferencesRepository _appPreferences;
  final RemoteConfigService _remoteConfig;
  final NotificationService _notifications;

  GlobalKey get schedulePreferencesButtonKey =>
      _appTour.schedulePreferencesButtonKey;

  bool get shouldInitializeNotifications =>
      _appPreferences.getTutorialStatus() ?? false;

  List<HudNoticeModel> notices = [];

  void _loadNotices() {
    final all = _remoteConfig.getNotices();
    notices = all.where((n) => _appPreferences.shouldShowNotice(n.id)).toList();
  }

  void dismissNotice(int noticeId) {
    notices = notices.where((n) => n.id != noticeId).toList();
    _appPreferences.dismissNotice(noticeId);
    notifyListeners();
  }

  void startAppTour(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) _appTour.startAppTour(context);
    });
  }

  Future<bool> shouldShowNotificationDialog() async {
    final needsPerm = await _notifications.needsPermission();
    return needsPerm && _appPreferences.shouldPromptForNotifications();
  }

  Future<void> onNotificationGranted() => _notifications.requestPermission();

  Future<void> onNotificationDenied() =>
      _appPreferences.saveNotificationDialogDismissedAt();

  Future<void> initNotifications() => _notifications.initialize();
}

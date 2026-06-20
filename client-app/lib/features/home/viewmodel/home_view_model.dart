import 'package:flutter/material.dart';
import 'package:plan_sync/backend/models/remote_config/hud_notices_model.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/services/app_tour_service.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required AppTourService appTour,
    required AppPreferencesRepository appPreferences,
    required RemoteConfigService remoteConfig,
  })  : _appTour = appTour,
        _appPreferences = appPreferences,
        _remoteConfig = remoteConfig {
    _loadNotices();
  }

  final AppTourService _appTour;
  final AppPreferencesRepository _appPreferences;
  final RemoteConfigService _remoteConfig;

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
}

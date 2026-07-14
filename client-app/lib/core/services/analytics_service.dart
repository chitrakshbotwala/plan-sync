import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/services/version_service.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/core/util/logger.dart';

class AnalyticsService {
  AnalyticsService({
    required AuthRepository auth,
    required AppPreferencesRepository preferences,
    required VersionService versionService,
  })  : _auth = auth,
        _preferences = preferences,
        _versionService = versionService;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final AuthRepository _auth;
  final AppPreferencesRepository _preferences;
  final VersionService _versionService;

  Future<void> onReady() async {
    Logger.i("Analytics service ready");
    await setUserData();
    Future.delayed(const Duration(seconds: 2), logOpenApp);
  }

  Future<void> setUserData() async {
    await _analytics.setUserId(id: _auth.currentUser?.uid);
    await _analytics.setUserProperty(
      name: "userp_primary_year",
      value: _preferences.getPrimaryYearPreference() ?? "null",
    );
    await _analytics.setUserProperty(
      name: "userp_primary_section",
      value: _preferences.getPrimarySectionPreference() ?? "null",
    );
    await _analytics.setUserProperty(
      name: "userp_primary_semester",
      value: _preferences.getPrimarySemesterPreference() ?? "null",
    );
    Logger.i("user property reported in analytics.");
  }

  void logOpenApp() async {
    final version = (await _versionService.getPackageInfo()).version;
    final parameters = {
      'app_version': version,
      'primary_section': _preferences.getPrimarySectionPreference() ?? "null",
      'primary_semester': _preferences.getPrimarySemesterPreference() ?? "null",
    };
    try {
      await _analytics.logAppOpen();
      await _analytics.logEvent(
        name: 'app_opened',
        parameters: parameters,
      );
      Logger.i("Logged Analytics");
      Logger.i(parameters);
    } catch (e) {
      Logger.i("Failed logging analytics. \n $e");
    }
  }

  void logShareSheetOpen() async {
    await _analytics.logEvent(name: 'share_bottomsheet_open');
  }

  void logShareViaExternalApps() async {
    await _analytics.logEvent(name: 'share_via_external_apps_open');
  }
}

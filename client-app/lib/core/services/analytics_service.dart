import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/util/logger.dart';

class AnalyticsService {
  AnalyticsService({
    required AuthRepository auth,
    required FilterViewModel filters,
    required VersionViewModel version,
  })  : _auth = auth,
        _filters = filters,
        _version = version;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final AuthRepository _auth;
  final FilterViewModel _filters;
  final VersionViewModel _version;

  Future<void> onReady() async {
    Logger.i("Analytics service ready");
    await setUserData();
    Future.delayed(const Duration(seconds: 2), logOpenApp);
  }

  Future<void> setUserData() async {
    await _analytics.setUserId(id: _auth.currentUser?.uid);
    await _analytics.setUserProperty(
      name: "userp_primary_year",
      value: _filters.primaryYear ?? "null",
    );
    await _analytics.setUserProperty(
      name: "userp_primary_section",
      value: _filters.primarySection ?? "null",
    );
    await _analytics.setUserProperty(
      name: "userp_primary_semester",
      value: _filters.primarySemester ?? "null",
    );
    Logger.i("user property reported in analytics.");
  }

  void logOpenApp() async {
    final parameters = {
      'app_version': _version.clientVersion ?? "unknown",
      'primary_section': _filters.primarySection ?? "null",
      'primary_semester': _filters.primarySemester ?? "null",
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

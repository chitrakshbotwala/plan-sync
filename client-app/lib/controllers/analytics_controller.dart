import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/controllers/version_controller.dart';
import 'package:plan_sync/util/logger.dart';
import 'package:provider/provider.dart';

class AnalyticsController extends ChangeNotifier {
  late FirebaseAnalytics _analytics;
  late AuthRepository auth;
  late FilterViewModel filters;

  Future<void> onReady(BuildContext context) async {
    filters = Provider.of<FilterViewModel>(context, listen: false);
    auth = Provider.of<AuthRepository>(context, listen: false);
    Logger.i("Analytics controller ready");
    _analytics = FirebaseAnalytics.instance;
    await setUserData();
    Future.delayed(const Duration(seconds: 2), () => logOpenApp(context));
  }

  Future<void> setUserData() async {
    await _analytics.setUserId(id: auth.currentUser?.uid);
    await _analytics.setUserProperty(
      name: "userp_primary_year",
      value: filters.primaryYear ?? "null",
    );
    await _analytics.setUserProperty(
      name: "userp_primary_section",
      value: filters.primarySection ?? "null",
    );
    await _analytics.setUserProperty(
      name: "userp_primary_semester",
      value: filters.primarySemester ?? "null",
    );
    Logger.i("user property reported in analytics.");
  }

  void logOpenApp(BuildContext context) async {
    VersionController version =
        Provider.of<VersionController>(context, listen: false);
    final parameters = {
      'app_version': version.clientVersion ?? "unknown",
      'primary_section': filters.primarySection ?? "null",
      'primary_semester': filters.primarySemester ?? "null",
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
      Logger.i("Failed logging analytics. \n ${e.toString()}");
    }
  }

  void logShareSheetOpen() async {
    await _analytics.logEvent(name: 'share_bottomsheet_open');
  }

  void logShareViaExternalApps() async {
    await _analytics.logEvent(name: 'share_via_external_apps_open');
  }
}

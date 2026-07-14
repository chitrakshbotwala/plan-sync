import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plan_sync/core/cache/cache_service.dart';
import 'package:plan_sync/core/services/analytics_service.dart';
import 'package:plan_sync/core/services/app_tour_service.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/core/util/logger.dart';
import 'package:plan_sync/router_refresh_stream.dart';
import 'package:provider/provider.dart';

class AppInitializer {
  static Future<void> initializeApp(BuildContext context) async {
    try {
      await Future.wait([
        Provider.of<ApiClient>(context, listen: false).initialize(),
        Provider.of<CacheService>(context, listen: false).initialize(),
        Provider.of<AppPreferencesRepository>(context, listen: false).onInit(),
      ]);
      if (!context.mounted) return;
      Provider.of<AppTourService>(context, listen: false).onInit(context);
      Provider.of<ThemeService>(context, listen: false).onInit();

      await Future.wait([
        Provider.of<VersionViewModel>(context, listen: false).onReady(),
        Provider.of<RemoteConfigService>(context, listen: false).onReady(),
      ]);

      if (context.mounted) _initializeInBackground(context);
    } catch (e, stackTrace) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
      rethrow;
    }
  }

  static void _initializeInBackground(BuildContext context) {
    final versionViewModel =
        Provider.of<VersionViewModel>(context, listen: false);
    _reportInBackground(
      versionViewModel
          .verifyMinimumVersion()
          .then((_) => routerRefreshStream.refresh()),
    );

    _reportInBackground(
      Provider.of<FilterViewModel>(context, listen: false).initialize(),
    );

    _reportInBackground(
      Provider.of<AttendanceViewModel>(context, listen: false).initialize(),
    );

    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final auth = Provider.of<AuthRepository>(context, listen: false);
    _reportInBackground(analytics.onReady().then((_) {
      auth.authStateChanges().listen((_) => analytics.setUserData());
    }));
  }

  static void _reportInBackground(Future<void> future) {
    future.catchError((Object e, StackTrace stackTrace) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordError(e, stackTrace);
      } else {
        Logger.e('background init failed: $e');
      }
    });
  }
}

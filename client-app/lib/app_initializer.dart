import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plan_sync/core/services/analytics_service.dart';
import 'package:plan_sync/controllers/app_tour_controller.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';
import 'package:plan_sync/controllers/theme_controller.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:provider/provider.dart';

class AppInitializer {
  static Future<void> initializeApp(BuildContext context) async {
    try {
      await Provider.of<ApiClient>(context, listen: false).initialize();
      Provider.of<AppTourController>(context, listen: false).onInit(context);
      await Provider.of<AppPreferencesRepository>(context, listen: false)
          .onInit();
      Provider.of<AppThemeController>(context, listen: false).onInit();

      await Future.wait([
        Provider.of<VersionViewModel>(context, listen: false).onReady(context),
        Provider.of<FilterViewModel>(context, listen: false).initialize(),
        Provider.of<RemoteConfigService>(context, listen: false).onReady(),
      ]);

      final analytics =
          Provider.of<AnalyticsService>(context, listen: false);
      await analytics.onReady();

      // Keep analytics user data in sync with auth state for the app's lifetime.
      Provider.of<AuthRepository>(context, listen: false)
          .authStateChanges()
          .listen((_) => analytics.setUserData());
    } catch (e, stackTrace) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
      rethrow;
    }
  }
}

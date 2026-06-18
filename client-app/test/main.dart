import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plan_sync/controllers/analytics_controller.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/controllers/app_tour_controller.dart';
import 'package:plan_sync/controllers/auth.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/controllers/git_service.dart';
import 'package:plan_sync/controllers/notification_controller.dart';
import 'package:plan_sync/controllers/remote_config_controller.dart';
import 'package:plan_sync/controllers/theme_controller.dart';
import 'package:plan_sync/controllers/version_controller.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository.dart';
import 'package:plan_sync/features/schedule/viewmodel/schedule_view_model.dart';
import 'package:provider/provider.dart';
import 'mock_controllers/analytics_controller_mock.dart';
import 'mock_controllers/app_preferences_controller_mock.dart';
import 'mock_controllers/app_tour_controller_mock.dart';
import 'mock_controllers/auth_mock.dart';
import 'mock_controllers/filter_controller_mock.dart';
import 'mock_controllers/git_service_mock.dart';
import 'mock_controllers/notification_controller_mock.dart';
import 'mock_controllers/remote_config_controller_mock.dart';
import 'mock_controllers/schedule_repository_mock.dart';
import 'mock_controllers/version_controller_mock.dart';

Future<void> injectMockDependencies() async {
  Get.reset();
  final preferences = MockAppPreferencesController();
  await preferences.onInit();

  Get.put<Auth>(MockAuth());
  Get.put<AppPreferencesController>(preferences);
  Get.put<GitService>(MockGitService());
  Get.put<FilterController>(MockFilterController());
  Get.put<ScheduleRepository>(MockScheduleRepository());
  Get.put<VersionController>(MockVersionController());
  Get.put<AnalyticsController>(MockAnalyticsController());
  Get.put<AppTourController>(MockAppTourController());
  Get.put<RemoteConfigController>(MockRemoteConfigController());
  Get.put<NotificationController>(MockNotificationController());
  Get.put<AppThemeController>(AppThemeController());
}

/// Wraps [child] in the provider tree expected by widgets in lib/, using
/// the mocks currently registered in [Get]. Tests should use [testApp]
/// for a bare home page or [wrapWithProviders] when supplying a custom
/// [MaterialApp.router].
Widget wrapWithProviders({required Widget child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<Auth>.value(value: Get.find<Auth>()),
      ChangeNotifierProvider<AppPreferencesController>.value(
        value: Get.find<AppPreferencesController>(),
      ),
      ChangeNotifierProvider<GitService>.value(value: Get.find<GitService>()),
      ChangeNotifierProvider<FilterController>.value(
        value: Get.find<FilterController>(),
      ),
      ChangeNotifierProvider<VersionController>.value(
        value: Get.find<VersionController>(),
      ),
      ChangeNotifierProvider<AnalyticsController>.value(
        value: Get.find<AnalyticsController>(),
      ),
      ChangeNotifierProvider<AppTourController>.value(
        value: Get.find<AppTourController>(),
      ),
      ChangeNotifierProvider<RemoteConfigController>.value(
        value: Get.find<RemoteConfigController>(),
      ),
      ChangeNotifierProvider<NotificationController>.value(
        value: Get.find<NotificationController>(),
      ),
      ChangeNotifierProvider<AppThemeController>.value(
        value: Get.find<AppThemeController>(),
      ),
      Provider<ScheduleRepository>.value(
        value: Get.find<ScheduleRepository>(),
      ),
    ],
    child: Builder(
      builder: (ctx) {
        Get.find<AppTourController>().onInit(ctx);
        Get.find<FilterController>().onInit(ctx);
        return ChangeNotifierProvider<ScheduleViewModel>(
          create: (_) => ScheduleViewModel(
            repository: Get.find<ScheduleRepository>(),
            filterController: Get.find<FilterController>(),
          ),
          child: child,
        );
      },
    ),
  );
}

Widget testApp({required Widget child}) {
  return wrapWithProviders(
    child: MaterialApp(
      theme: AppThemeController.lightTheme,
      home: child,
    ),
  );
}

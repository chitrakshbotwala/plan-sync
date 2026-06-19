import 'package:flutter/material.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/controllers/app_tour_controller.dart';
import 'package:plan_sync/core/services/analytics_service.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/controllers/remote_config_controller.dart';
import 'package:plan_sync/controllers/theme_controller.dart';
import 'package:plan_sync/features/home/viewmodel/home_view_model.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/core/services/notification_service.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository.dart';
import 'package:plan_sync/features/schedule/viewmodel/schedule_view_model.dart';
import 'package:provider/provider.dart';
import 'mock_controllers/analytics_controller_mock.dart';
import 'mock_controllers/app_preferences_controller_mock.dart';
import 'mock_controllers/app_tour_controller_mock.dart';
import 'mock_controllers/auth_mock.dart';
import 'mock_controllers/filter_view_model_mock.dart';
import 'mock_controllers/notification_controller_mock.dart';
import 'mock_controllers/remote_config_controller_mock.dart';
import 'mock_controllers/schedule_repository_mock.dart';
import 'mock_controllers/version_controller_mock.dart';

late MockAuth mockAuth;
late MockAppPreferencesController mockPreferences;
late MockFilterViewModel mockFilterViewModel;
late MockScheduleRepository mockScheduleRepository;
late MockVersionViewModel mockVersionViewModel;
late MockAnalyticsService mockAnalyticsService;
late MockAppTourController mockAppTourController;
late MockRemoteConfigController mockRemoteConfigController;
late MockNotificationService mockNotificationService;
late AppThemeController mockThemeController;

Future<void> injectMockDependencies() async {
  mockAuth = MockAuth();
  mockPreferences = MockAppPreferencesController();
  await mockPreferences.onInit();
  mockFilterViewModel = MockFilterViewModel(mockPreferences);
  mockScheduleRepository = MockScheduleRepository();
  mockVersionViewModel = MockVersionViewModel();
  mockAnalyticsService = MockAnalyticsService();
  mockAppTourController = MockAppTourController();
  mockRemoteConfigController = MockRemoteConfigController();
  mockNotificationService = MockNotificationService();
  mockThemeController = AppThemeController();
}

/// Wraps [child] in the provider tree expected by widgets in lib/.
Widget wrapWithProviders({required Widget child}) {
  return MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: mockAuth),
      ChangeNotifierProvider<AppPreferencesController>.value(
        value: mockPreferences,
      ),
      ChangeNotifierProvider<FilterViewModel>.value(
        value: mockFilterViewModel,
      ),
      ChangeNotifierProvider<VersionViewModel>.value(
        value: mockVersionViewModel,
      ),
      Provider<AnalyticsService>.value(
        value: mockAnalyticsService,
      ),
      ChangeNotifierProvider<AppTourController>.value(
        value: mockAppTourController,
      ),
      ChangeNotifierProvider<RemoteConfigController>.value(
        value: mockRemoteConfigController,
      ),
      Provider<NotificationService>.value(
        value: mockNotificationService,
      ),
      ChangeNotifierProvider<AppThemeController>.value(
        value: mockThemeController,
      ),
      Provider<ScheduleRepository>.value(
        value: mockScheduleRepository,
      ),
      ChangeNotifierProvider<HomeViewModel>(
        create: (_) => HomeViewModel(
          appTour: mockAppTourController,
          appPreferences: mockPreferences,
        ),
      ),
    ],
    child: Builder(
      builder: (ctx) {
        mockAppTourController.onInit(ctx);
        return ChangeNotifierProvider<ScheduleViewModel>(
          create: (_) => ScheduleViewModel(
            repository: mockScheduleRepository,
            filterViewModel: mockFilterViewModel,
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

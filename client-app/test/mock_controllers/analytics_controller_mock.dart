import 'package:mockito/mockito.dart';
import 'package:plan_sync/core/services/analytics_service.dart';
import 'package:plan_sync/core/util/logger.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> onReady() async {
    Logger.i('mocking AnalyticsService.onReady');
  }

  @override
  Future<void> setUserData() async {
    Logger.i('mocking setUserData');
  }

  @override
  void logOpenApp() {
    Logger.i('mocking logOpenApp');
  }

  @override
  void logShareSheetOpen() {}

  @override
  void logShareViaExternalApps() {}
}

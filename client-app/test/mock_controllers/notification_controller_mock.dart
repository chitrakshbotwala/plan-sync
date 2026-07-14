import 'package:mockito/mockito.dart';
import 'package:plan_sync/core/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {
  /// Toggle to drive the home-screen permission dialog in tests.
  bool needsPermissionResult = false;
  int requestPermissionCalls = 0;
  int initializeCalls = 0;

  @override
  Future<bool> needsPermission() async => needsPermissionResult;

  @override
  Future<void> requestPermission() async => requestPermissionCalls++;

  @override
  Future<void> initialize() async => initializeCalls++;
}

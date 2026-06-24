import 'package:mockito/mockito.dart';
import 'package:plan_sync/core/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {
  @override
  Future<bool> needsPermission() async => false;

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> initialize() async {}
}

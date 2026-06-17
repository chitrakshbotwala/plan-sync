import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/notification_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NotificationController.initialNotificationRoute = null;
  });

  group('initialNotificationRoute', () {
    test('defaults to null', () {
      expect(NotificationController.initialNotificationRoute, isNull);
    });

    test('is mutable across tests via static setter', () {
      NotificationController.initialNotificationRoute = '/electives';
      expect(
        NotificationController.initialNotificationRoute,
        '/electives',
      );
    });
  });
}

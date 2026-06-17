import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/controllers/notification_controller.dart';

class MockNotificationController extends Mock
    with ChangeNotifier
    implements NotificationController {
  @override
  Future<void> initialize(BuildContext context) async {}
}

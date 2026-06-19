import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/core/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {
  @override
  Future<void> initialize(BuildContext context) async {}
}

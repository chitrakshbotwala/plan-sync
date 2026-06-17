import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/controllers/analytics_controller.dart';
import 'package:plan_sync/controllers/auth.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/util/logger.dart';

import 'auth_mock.dart';
import 'filter_controller_mock.dart';

class MockAnalyticsController extends Mock
    with ChangeNotifier
    implements AnalyticsController {
  @override
  Auth auth = MockAuth();

  @override
  FilterController filters = MockFilterController();

  @override
  Future<void> onReady(BuildContext context) async {
    Logger.i('mocking AnalyticsController.onReady');
  }

  @override
  void logOpenApp(BuildContext context) {
    Logger.i('mocking logOpenApp');
  }

  @override
  Future<void> setUserData() async {
    Logger.i('mocking setUserData');
  }
}

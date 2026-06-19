import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/controllers/analytics_controller.dart';
import 'package:plan_sync/controllers/auth.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/util/logger.dart';

import 'auth_mock.dart';
import 'filter_view_model_mock.dart';

class MockAnalyticsController extends Mock
    with ChangeNotifier
    implements AnalyticsController {
  @override
  Auth auth = MockAuth();

  @override
  FilterViewModel filters = MockFilterViewModel();

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

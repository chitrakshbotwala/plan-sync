import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/analytics_controller.dart';

import '../util/firebase_test_helper.dart';

void main() {
  setUpAll(() async {
    await ensureFirebaseInitialized();
  });

  test('AnalyticsController can be constructed', () {
    final controller = AnalyticsController();
    expect(controller, isA<ChangeNotifier>());
  });

  test('multiple instances are independent', () {
    final a = AnalyticsController();
    final b = AnalyticsController();
    expect(identical(a, b), isFalse);
  });

  test('listener can be attached without throwing', () {
    final controller = AnalyticsController();
    expect(() => controller.addListener(() {}), returnsNormally);
  });
}

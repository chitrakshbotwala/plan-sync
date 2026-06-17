import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/remote_config_controller.dart';

import '../util/firebase_test_helper.dart';

void main() {
  setUpAll(() async {
    await ensureFirebaseInitialized();
  });

  test('RemoteConfigController can be constructed', () {
    final controller = RemoteConfigController();
    expect(controller, isA<ChangeNotifier>());
  });

  test('exposes the Firebase remote config instance', () {
    final controller = RemoteConfigController();
    expect(controller.remoteConfig, isNotNull);
  });

  test('multiple instances are independent', () {
    final a = RemoteConfigController();
    final b = RemoteConfigController();
    expect(identical(a, b), isFalse);
  });
}

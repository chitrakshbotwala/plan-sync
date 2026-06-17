import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/auth.dart';

import '../util/firebase_test_helper.dart';

void main() {
  setUpAll(() async {
    await ensureFirebaseInitialized();
  });

  group('listener machinery', () {
    test('onInit creates an empty listeners list', () {
      final auth = Auth();
      auth.onInit();
      expect(auth.authChangeListeners, isEmpty);
    });

    test('addUserStatusListener appends to the list', () {
      final auth = Auth();
      auth.onInit();
      void l1() {}
      void l2() {}
      auth.addUserStatusListener(l1);
      auth.addUserStatusListener(l2);
      expect(auth.authChangeListeners, [l1, l2]);
    });

    test('removeUserStatusListener removes the listener', () {
      final auth = Auth();
      auth.onInit();
      void l1() {}
      void l2() {}
      auth.addUserStatusListener(l1);
      auth.addUserStatusListener(l2);
      auth.removeUserStatusListener(l1);
      expect(auth.authChangeListeners, [l2]);
    });

    test('notifyAuthStatusListeners fires every registered callback', () {
      final auth = Auth();
      auth.onInit();
      int callsA = 0;
      int callsB = 0;
      auth.addUserStatusListener(() => callsA++);
      auth.addUserStatusListener(() => callsB++);

      auth.notifyAuthStatusListeners();
      auth.notifyAuthStatusListeners();

      expect(callsA, 2);
      expect(callsB, 2);
    });

    test('notifyAuthStatusListeners with no listeners is a no-op', () {
      final auth = Auth();
      auth.onInit();
      expect(() => auth.notifyAuthStatusListeners(), returnsNormally);
    });
  });

}

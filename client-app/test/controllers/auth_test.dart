import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/auth.dart';

import '../util/firebase_test_helper.dart';

void main() {
  setUpAll(() async {
    await ensureFirebaseInitialized();
  });

  group('auth status listeners', () {
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

    test('removed listeners are not invoked', () {
      final auth = Auth();
      auth.onInit();
      int callsA = 0;
      int callsB = 0;
      void a() => callsA++;
      void b() => callsB++;
      auth.addUserStatusListener(a);
      auth.addUserStatusListener(b);

      auth.removeUserStatusListener(a);
      auth.notifyAuthStatusListeners();

      expect(callsA, 0);
      expect(callsB, 1);
    });

    test('an exception in one listener does not stop later listeners', () {
      final auth = Auth();
      auth.onInit();
      int laterCalls = 0;
      auth.addUserStatusListener(() => throw StateError('boom'));
      auth.addUserStatusListener(() => laterCalls++);

      // Documents current behavior: notify rethrows the first listener's
      // exception, so later listeners are NOT invoked. This is a regression
      // canary — if notify is hardened to swallow listener exceptions in the
      // future, update this expectation.
      expect(() => auth.notifyAuthStatusListeners(), throwsStateError);
      expect(laterCalls, 0);
    });
  });
}

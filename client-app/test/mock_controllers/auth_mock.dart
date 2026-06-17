import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/controllers/auth.dart';

class MockAuth extends Mock with ChangeNotifier implements Auth {
  MockFirebaseAuth _auth = MockFirebaseAuth();

  @override
  List<Function> authChangeListeners = [];

  @override
  void onInit() {
    authChangeListeners = [];
  }

  @override
  void addUserStatusListener(Function fn) => authChangeListeners.add(fn);

  @override
  void removeUserStatusListener(Function fn) => authChangeListeners.remove(fn);

  @override
  void notifyAuthStatusListeners() {
    for (final fn in authChangeListeners) {
      fn.call();
    }
  }

  @override
  User? get activeUser => _auth.currentUser;

  @override
  Future<void> loginWithGoogle(BuildContext context) async {
    final user = MockUser(
      isAnonymous: false,
      uid: 'mock-user-uid',
      email: 'mock@plansync.in',
      displayName: 'MockUser',
    );
    _auth = MockFirebaseAuth(mockUser: user, signedIn: true);
    return;
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    return;
  }
}

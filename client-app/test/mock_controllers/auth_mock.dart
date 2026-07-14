import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';

class MockAuth extends Mock implements AuthRepository {
  MockFirebaseAuth _auth = MockFirebaseAuth();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> loginWithGoogle() async {
    final user = MockUser(
      isAnonymous: false,
      uid: 'mock-user-uid',
      email: 'mock@plansync.in',
      displayName: 'MockUser',
    );
    _auth = MockFirebaseAuth(mockUser: user, signedIn: true);
  }

  @override
  Future<void> loginWithApple() async {}

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteCurrentUser() async {}
}

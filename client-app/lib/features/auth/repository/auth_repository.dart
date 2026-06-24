import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class AuthCancelledByUser extends AuthException {
  const AuthCancelledByUser() : super('Login was cancelled by the user.');
}

class DeleteAccountException extends AuthException {
  const DeleteAccountException(super.message);
}

abstract class AuthRepository {
  User? get currentUser;
  Stream<User?> authStateChanges();
  Future<void> loginWithGoogle();
  Future<void> loginWithApple();
  Future<void> logout();
  Future<void> deleteCurrentUser();
}

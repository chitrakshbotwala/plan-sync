import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/features/auth/viewmodel/login_view_model.dart';
import 'package:plan_sync/core/util/enums.dart';

class FakeAuthRepository implements AuthRepository {
  bool shouldThrowCancelled = false;
  bool shouldThrowAuthException = false;
  String authExceptionMessage = 'Invalid credentials';

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<void> loginWithGoogle() async {
    if (shouldThrowCancelled) throw const AuthCancelledByUser();
    if (shouldThrowAuthException) throw AuthException(authExceptionMessage);
  }

  @override
  Future<void> loginWithApple() async {
    if (shouldThrowCancelled) throw const AuthCancelledByUser();
    if (shouldThrowAuthException) throw AuthException(authExceptionMessage);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteCurrentUser() async {}
}

void main() {
  group('LoginViewModel', () {
    late FakeAuthRepository repo;
    late LoginViewModel vm;

    setUp(() {
      repo = FakeAuthRepository();
      vm = LoginViewModel(repository: repo);
    });

    test('isLoading is false and errorMessage is null before login', () {
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('successful Google login clears errorMessage and resets isLoading',
        () async {
      await vm.login(LoginProvider.google);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('AuthException sets errorMessage after Google login', () async {
      repo.shouldThrowAuthException = true;
      repo.authExceptionMessage = 'Wrong password';
      await vm.login(LoginProvider.google);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, 'Wrong password');
    });

    test('AuthCancelledByUser produces no errorMessage', () async {
      repo.shouldThrowCancelled = true;
      await vm.login(LoginProvider.google);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('Apple login also clears errorMessage on success', () async {
      await vm.login(LoginProvider.apple);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('unexpected exception produces generic errorMessage', () async {
      // Replace with a throwing impl
      final throwingRepo = _ThrowingAuthRepository();
      final throwingVm = LoginViewModel(repository: throwingRepo);
      await throwingVm.login(LoginProvider.google);
      expect(throwingVm.errorMessage, 'Authentication failed.');
    });
  });
}

class _ThrowingAuthRepository extends FakeAuthRepository {
  @override
  Future<void> loginWithGoogle() async => throw Exception('Network failure');
}

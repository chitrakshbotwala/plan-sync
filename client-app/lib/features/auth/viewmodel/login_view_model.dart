import 'package:flutter/foundation.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/util/enums.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;
  bool isLoading = false;
  String? errorMessage;

  Future<void> login(LoginProvider provider) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      switch (provider) {
        case LoginProvider.google:
          await _repository.loginWithGoogle();
        case LoginProvider.apple:
          await _repository.loginWithApple();
      }
    } on AuthCancelledByUser {
      // user explicitly cancelled — no error shown
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Authentication failed.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

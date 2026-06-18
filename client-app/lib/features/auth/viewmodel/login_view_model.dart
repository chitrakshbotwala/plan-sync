import 'package:flutter/material.dart';
import 'package:plan_sync/controllers/auth.dart';
import 'package:plan_sync/util/enums.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required Auth auth}) : _auth = auth;

  final Auth _auth;
  bool isLoading = false;

  Future<void> login(BuildContext context, LoginProvider provider) async {
    isLoading = true;
    notifyListeners();

    switch (provider) {
      case LoginProvider.google:
        await _auth.loginWithGoogle(context);
      case LoginProvider.apple:
        await _auth.loginWithApple(context);
    }

    isLoading = false;
    notifyListeners();
  }
}

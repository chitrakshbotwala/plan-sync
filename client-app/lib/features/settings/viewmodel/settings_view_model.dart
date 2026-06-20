import 'package:flutter/foundation.dart';
import 'package:plan_sync/core/services/analytics_service.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required AuthRepository auth,
    required VersionViewModel version,
    required AnalyticsService analytics,
  })  : _auth = auth,
        _version = version,
        _analytics = analytics;

  final AuthRepository _auth;
  final VersionViewModel _version;
  final AnalyticsService _analytics;

  bool isPunActivated = false;

  String? get displayName => _auth.currentUser?.displayName;
  String? get email => _auth.currentUser?.email;
  String? get photoUrl => _auth.currentUser?.photoURL;
  String? get uid => _auth.currentUser?.uid;
  String? get clientVersion => _version.clientVersion;

  Future<void> logout() => _auth.logout();

  void togglePun() {
    isPunActivated = !isPunActivated;
    notifyListeners();
  }

  void logShareSheetOpen() => _analytics.logShareSheetOpen();
}

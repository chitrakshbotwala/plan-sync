import 'package:flutter/foundation.dart';
import 'package:plan_sync/controllers/analytics_controller.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required AuthRepository auth,
    required VersionViewModel version,
    required AnalyticsController analytics,
  })  : _auth = auth,
        _version = version,
        _analytics = analytics;

  final AuthRepository _auth;
  final VersionViewModel _version;
  final AnalyticsController _analytics;

  bool isPunActivated = false;

  String? get displayName => _auth.currentUser?.displayName;
  String? get email => _auth.currentUser?.email;
  String? get photoUrl => _auth.currentUser?.photoURL;
  String? get uid => _auth.currentUser?.uid;
  String? get clientVersion => _version.clientVersion;

  void togglePun() {
    isPunActivated = !isPunActivated;
    notifyListeners();
  }

  void logShareSheetOpen() => _analytics.logShareSheetOpen();
}

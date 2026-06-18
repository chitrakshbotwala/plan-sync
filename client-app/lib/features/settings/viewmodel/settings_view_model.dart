import 'package:flutter/foundation.dart';
import 'package:plan_sync/controllers/analytics_controller.dart';
import 'package:plan_sync/controllers/auth.dart';
import 'package:plan_sync/controllers/version_controller.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required Auth auth,
    required VersionController version,
    required AnalyticsController analytics,
  })  : _auth = auth,
        _version = version,
        _analytics = analytics;

  final Auth _auth;
  final VersionController _version;
  final AnalyticsController _analytics;

  bool isPunActivated = false;

  String? get displayName => _auth.activeUser?.displayName;
  String? get email => _auth.activeUser?.email;
  String? get photoUrl => _auth.activeUser?.photoURL;
  String? get uid => _auth.activeUser?.uid;
  String? get clientVersion => _version.clientVersion;

  void togglePun() {
    isPunActivated = !isPunActivated;
    notifyListeners();
  }

  void logShareSheetOpen() => _analytics.logShareSheetOpen();
}

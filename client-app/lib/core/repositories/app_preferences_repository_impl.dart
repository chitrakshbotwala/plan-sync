import 'dart:convert';
import 'package:plan_sync/core/models/in_app_review_model.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesRepositoryImpl implements AppPreferencesRepository {
  late SharedPreferences perfs;

  @override
  Future<void> onInit() async {
    perfs = await SharedPreferences.getInstance();
  }

  @override
  String? getPrimarySectionPreference() => perfs.getString('primary-section');

  @override
  Future<bool> savePrimarySectionPreference(String data) async =>
      await perfs.setString('primary-section', data);

  @override
  String? getPrimarySemesterPreference() => perfs.getString('primary-semester');

  @override
  Future<bool> savePrimarySemesterPreference(String data) async =>
      await perfs.setString('primary-semester', data);

  @override
  String? getPrimaryYearPreference() => perfs.getString('primary-year');

  @override
  Future<bool> savePrimaryYearPreference(String data) async =>
      await perfs.setString('primary-year', data);

  @override
  bool? getTutorialStatus() => perfs.getBool('app-tutorial-status');

  @override
  Future<bool> saveTutorialStatus(bool status) async =>
      await perfs.setBool('app-tutorial-status', status);

  @override
  String? getPrimaryElectiveSchemePreference() =>
      perfs.getString('elective-primary-section');

  @override
  Future<bool> savePrimaryElectiveSchemePreference(String data) async =>
      await perfs.setString('elective-primary-section', data);

  @override
  String? getPrimaryElectiveSemesterPreference() =>
      perfs.getString('elective-primary-semester');

  @override
  Future<bool> savePrimaryElectiveSemesterPreference(String data) async =>
      await perfs.setString('elective-primary-semester', data);

  @override
  String? getPrimaryElectiveYearPreference() =>
      perfs.getString('elective-primary-year');

  @override
  Future<bool> savePrimaryElectiveYearPreference(String data) async =>
      await perfs.setString('elective-primary-year', data);

  @override
  Future<bool> saveIsAppBelowMinVersion(bool status) async =>
      await perfs.setBool('is-app-below-minVersion', status);

  @override
  bool isAppBelowMinVersion() =>
      perfs.getBool('is-app-below-minVersion') ?? false;

  static const String _noticesDismissalPerfKey = 'dismissed_notices';

  Map<String, dynamic> _getNoticeDismissals() =>
      json.decode(perfs.getString(_noticesDismissalPerfKey) ?? '{}')
          as Map<String, dynamic>;

  @override
  Future<void> dismissNotice(int noticeId) async {
    final dismissed = _getNoticeDismissals();
    dismissed[noticeId.toString()] = DateTime.now().toIso8601String();
    await perfs.setString(_noticesDismissalPerfKey, json.encode(dismissed));
  }

  @override
  bool shouldShowNotice(int noticeId) {
    return !_getNoticeDismissals().containsKey(noticeId.toString());
  }

  @override
  Future<void> cleanupOldNoticeDismissals() async {
    final dismissed = _getNoticeDismissals();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    dismissed.removeWhere((key, value) {
      return DateTime.parse(value).isBefore(yesterday);
    });
    await perfs.setString(_noticesDismissalPerfKey, json.encode(dismissed));
  }

  static const String _reviewRequestKey = 'review-requested';

  @override
  InAppReviewCacheModel? getAppReviewRequest() {
    String? data = perfs.getString(_reviewRequestKey);
    if (data == null) return null;
    return InAppReviewCacheModel.fromJson(json.decode(data));
  }

  @override
  Future<void> saveAppReviewRequest(InAppReviewCacheModel model) async {
    await perfs.setString(_reviewRequestKey, json.encode(model.toJson()));
  }

  static const String _starredElectivesKey = 'starred_electives';

  @override
  Future<List<String>> getStarredElectives() async {
    return perfs.getStringList(_starredElectivesKey) ?? [];
  }

  @override
  Future<void> starElective(String electiveId) async {
    final current = perfs.getStringList(_starredElectivesKey) ?? [];
    if (!current.contains(electiveId)) {
      current.add(electiveId);
      await perfs.setStringList(_starredElectivesKey, current);
    }
  }

  @override
  Future<void> unstarElective(String electiveId) async {
    final current = perfs.getStringList(_starredElectivesKey) ?? [];
    if (current.contains(electiveId)) {
      current.remove(electiveId);
      await perfs.setStringList(_starredElectivesKey, current);
    }
  }

  @override
  bool isElectiveStarred(String electiveId) {
    final current = perfs.getStringList(_starredElectivesKey) ?? [];
    if (current.isEmpty) return false;
    return current.contains(electiveId);
  }

  static const String _notificationDialogDismissedKey =
      'notification_dialog_dismissed_at';

  @override
  Future<void> saveNotificationDialogDismissedAt() async {
    await perfs.setString(
      _notificationDialogDismissedKey,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  bool shouldPromptForNotifications() {
    final raw = perfs.getString(_notificationDialogDismissedKey);
    if (raw == null) return true;
    final dismissedAt = DateTime.tryParse(raw);
    if (dismissedAt == null) return true;
    return DateTime.now().difference(dismissedAt) > const Duration(days: 7);
  }
}

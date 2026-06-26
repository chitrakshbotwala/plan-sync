import 'package:plan_sync/core/models/in_app_review_model.dart';

abstract class AppPreferencesRepository {
  Future<void> onInit();

  String? getPrimarySectionPreference();
  Future<bool> savePrimarySectionPreference(String data);

  String? getPrimarySemesterPreference();
  Future<bool> savePrimarySemesterPreference(String data);

  String? getPrimaryYearPreference();
  Future<bool> savePrimaryYearPreference(String data);

  bool? getTutorialStatus();
  Future<bool> saveTutorialStatus(bool status);

  String? getPrimaryElectiveSchemePreference();
  Future<bool> savePrimaryElectiveSchemePreference(String data);

  String? getPrimaryElectiveSemesterPreference();
  Future<bool> savePrimaryElectiveSemesterPreference(String data);

  String? getPrimaryElectiveYearPreference();
  Future<bool> savePrimaryElectiveYearPreference(String data);

  Future<bool> saveIsAppBelowMinVersion(bool status);
  bool isAppBelowMinVersion();

  Future<void> dismissNotice(int noticeId);
  bool shouldShowNotice(int noticeId);
  Future<void> cleanupOldNoticeDismissals();

  InAppReviewCacheModel? getAppReviewRequest();
  Future<void> saveAppReviewRequest(InAppReviewCacheModel model);

  Future<List<String>> getStarredElectives();
  Future<void> starElective(String electiveId);
  Future<void> unstarElective(String electiveId);
  bool isElectiveStarred(String electiveId);

  Future<void> saveNotificationDialogDismissedAt();
  bool shouldPromptForNotifications();

  String? getChosenElective1();
  Future<void> saveChosenElective1(String? subjectName);

  String? getChosenElective2();
  Future<void> saveChosenElective2(String? subjectName);

  Future<void> clearSchedulePreferences();

  static String electiveId({
    required String academicYear,
    required String semester,
    required String scheme,
    required String subjectName,
  }) {
    return [academicYear, semester, scheme, subjectName]
        .map((e) => e.trim().replaceAll(RegExp(r'\s+'), '-'))
        .join('-');
  }
}

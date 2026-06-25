import 'package:mockito/mockito.dart';
import 'package:plan_sync/core/models/in_app_review_model.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppPreferencesController extends Mock
    implements AppPreferencesRepository {
  Future<bool> resetPreferencesToNull() async {
    final res = await perfs.clear();
    return res;
  }

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
  bool isElectiveStarred(String electiveId) => false;

  @override
  Future<List<String>> getStarredElectives() async => const [];

  @override
  Future<void> starElective(String electiveId) async {}

  @override
  Future<void> unstarElective(String electiveId) async {}

  @override
  bool isAppBelowMinVersion() => false;

  @override
  Future<bool> saveIsAppBelowMinVersion(bool status) async => true;

  @override
  bool shouldShowNotice(int noticeId) => true;

  @override
  Future<void> dismissNotice(int noticeId) async {}

  @override
  Future<void> cleanupOldNoticeDismissals() async {}

  @override
  InAppReviewCacheModel? getAppReviewRequest() => null;

  @override
  Future<void> saveAppReviewRequest(InAppReviewCacheModel model) async {}

  @override
  Future<void> saveNotificationDialogDismissedAt() async {}

  @override
  bool shouldPromptForNotifications() => false;

  @override
  String? getChosenElective1() => perfs.getString('chosen-elective-1');

  @override
  Future<void> saveChosenElective1(String? subjectName) async {
    if (subjectName == null) {
      await perfs.remove('chosen-elective-1');
    } else {
      await perfs.setString('chosen-elective-1', subjectName);
    }
  }

  @override
  String? getChosenElective2() => perfs.getString('chosen-elective-2');

  @override
  Future<void> saveChosenElective2(String? subjectName) async {
    if (subjectName == null) {
      await perfs.remove('chosen-elective-2');
    } else {
      await perfs.setString('chosen-elective-2', subjectName);
    }
  }
}

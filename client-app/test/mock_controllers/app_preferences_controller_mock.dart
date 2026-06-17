import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppPreferencesController extends Mock
    with ChangeNotifier
    implements AppPreferencesController {
  Future<bool> resetPreferencesToNull() async {
    final res = await perfs.clear();
    return res;
  }

  @override
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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/models/in_app_review_model.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPreferencesRepositoryImpl perfs;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    perfs = AppPreferencesRepositoryImpl();
    await perfs.onInit();
  });

  test('CRU for section preferences', () async {
    expect(perfs.getPrimarySectionPreference(), null);

    await perfs.savePrimarySectionPreference("B16");
    expect(perfs.getPrimarySectionPreference(), "B16");

    await perfs.savePrimarySectionPreference("A16");
    expect(perfs.getPrimarySectionPreference(), "A16");
  });

  test('CRU for semester preferences', () async {
    expect(perfs.getPrimarySemesterPreference(), null);

    await perfs.savePrimarySemesterPreference("SEM1");
    expect(perfs.getPrimarySemesterPreference(), "SEM1");

    await perfs.savePrimarySemesterPreference("SEM2");
    expect(perfs.getPrimarySemesterPreference(), "SEM2");
  });

  test('CRU for year preferences', () async {
    expect(perfs.getPrimaryYearPreference(), null);

    await perfs.savePrimaryYearPreference("2024");
    expect(perfs.getPrimaryYearPreference(), "2024");

    await perfs.savePrimaryYearPreference("2023");
    expect(perfs.getPrimaryYearPreference(), "2023");
  });

  test('CRU for tutorial status', () async {
    expect(perfs.getTutorialStatus(), null);

    await perfs.saveTutorialStatus(true);
    expect(perfs.getTutorialStatus(), true);

    await perfs.saveTutorialStatus(false);
    expect(perfs.getTutorialStatus(), false);
  });

  test('CRU for elective preferences', () async {
    expect(perfs.getPrimaryElectiveSchemePreference(), null);
    expect(perfs.getPrimaryElectiveSemesterPreference(), null);
    expect(perfs.getPrimaryElectiveYearPreference(), null);

    await perfs.savePrimaryElectiveSchemePreference("a");
    await perfs.savePrimaryElectiveSemesterPreference("SEM2");
    await perfs.savePrimaryElectiveYearPreference("2024");

    expect(perfs.getPrimaryElectiveSchemePreference(), "a");
    expect(perfs.getPrimaryElectiveSemesterPreference(), "SEM2");
    expect(perfs.getPrimaryElectiveYearPreference(), "2024");
  });

  test('isAppBelowMinVersion defaults to false', () async {
    expect(perfs.isAppBelowMinVersion(), false);
    await perfs.saveIsAppBelowMinVersion(true);
    expect(perfs.isAppBelowMinVersion(), true);
  });

  group('HUD notice dismissals', () {
    test('shouldShowNotice is true for never-dismissed notices', () {
      expect(perfs.shouldShowNotice(1), isTrue);
    });

    test('dismissNotice marks notice as not-shown', () async {
      await perfs.dismissNotice(42);
      expect(perfs.shouldShowNotice(42), isFalse);
    });

    test('cleanupOldNoticeDismissals removes entries older than a day',
        () async {
      // dismissals stored as ISO timestamps; rewrite a stale entry directly.
      final stale = DateTime.now().subtract(const Duration(days: 2));
      final raw = '{"7": "${stale.toIso8601String()}"}';
      // Hack: dismiss then overwrite to set timestamp explicitly.
      await perfs.dismissNotice(7);
      // Replace key with a stale value by re-dismissing won't help; use perfs.
      await perfs.perfs.setString('dismissed_notices', raw);

      await perfs.cleanupOldNoticeDismissals();
      expect(perfs.shouldShowNotice(7), isTrue);
    });
  });

  group('starred electives', () {
    test('isElectiveStarred is false when nothing starred', () {
      expect(perfs.isElectiveStarred('anything'), isFalse);
    });

    test('star then unstar reflects in checker and list', () async {
      final id = AppPreferencesRepository.electiveId(
        academicYear: '2024',
        semester: 'SEM2',
        scheme: 'a',
        subjectName: 'Operating Systems',
      );

      await perfs.starElective(id);
      expect(perfs.isElectiveStarred(id), isTrue);
      expect(await perfs.getStarredElectives(), contains(id));

      await perfs.unstarElective(id);
      expect(perfs.isElectiveStarred(id), isFalse);
      expect(await perfs.getStarredElectives(), isNot(contains(id)));
    });

    test('electiveId normalizes whitespace into dashes', () {
      final id = AppPreferencesRepository.electiveId(
        academicYear: '2024',
        semester: 'SEM 2',
        scheme: 'a',
        subjectName: 'Operating  Systems',
      );
      expect(id, '2024-SEM-2-a-Operating-Systems');
    });

    test('starElective is idempotent', () async {
      const id = 'foo';
      await perfs.starElective(id);
      await perfs.starElective(id);
      expect(
        (await perfs.getStarredElectives()).where((e) => e == id).length,
        1,
      );
    });
  });

  test('saveAppReviewRequest round-trips through preferences', () async {
    expect(perfs.getAppReviewRequest(), isNull);
    final ts = DateTime(2026, 1, 1).millisecondsSinceEpoch;
    final model = InAppReviewCacheModel(
      firstOpen: ts,
      lastAppVersion: '4.1.4',
    );
    await perfs.saveAppReviewRequest(model);

    final loaded = perfs.getAppReviewRequest();
    expect(loaded, isNotNull);
    expect(loaded!.firstOpen, ts);
    expect(loaded.lastAppVersion, '4.1.4');
  });

  group('shouldPromptForNotifications', () {
    test('returns true when no dismissal timestamp stored', () {
      expect(perfs.shouldPromptForNotifications(), isTrue);
    });

    test('returns false when dismissed less than 7 days ago', () async {
      await perfs.saveNotificationDialogDismissedAt();
      expect(perfs.shouldPromptForNotifications(), isFalse);
    });

    test('returns true when dismissed more than 7 days ago', () async {
      final stale = DateTime.now().subtract(const Duration(days: 8));
      await perfs.perfs
          .setString('notification_dialog_dismissed_at', stale.toIso8601String());
      expect(perfs.shouldPromptForNotifications(), isTrue);
    });
  });

  group('clearSchedulePreferences', () {
    test('removes year, semester, section, elective scheme, and chosen electives',
        () async {
      await perfs.savePrimaryYearPreference('2024');
      await perfs.savePrimarySemesterPreference('SEM1');
      await perfs.savePrimarySectionPreference('A16');
      await perfs.savePrimaryElectiveSchemePreference('a');
      await perfs.saveChosenElective1('Machine Learning');
      await perfs.saveChosenElective2('Data Structures');

      await perfs.clearSchedulePreferences();

      expect(perfs.getPrimaryYearPreference(), isNull);
      expect(perfs.getPrimarySemesterPreference(), isNull);
      expect(perfs.getPrimarySectionPreference(), isNull);
      expect(perfs.getPrimaryElectiveSchemePreference(), isNull);
      expect(perfs.getChosenElective1(), isNull);
      expect(perfs.getChosenElective2(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/controllers/git_service.dart';
import 'package:plan_sync/util/enums.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test double for [GitService] that bypasses the network layer and
/// exposes controllable fake state for [FilterController] under test.
class FakeGitService extends GitService {
  Map? _fakeSections;
  int getSectionsCallCount = 0;
  int getElectiveSchemesCallCount = 0;

  @override
  Map? get sections => _fakeSections;
  set sections(Map? newValue) {
    _fakeSections = newValue;
    notifyListeners();
  }

  @override
  Future<void> getSections(FilterController filterController) async {
    getSectionsCallCount++;
  }

  @override
  Future<void> getElectiveSchemes({
    BuildContext? context,
    FilterController? filterController,
  }) async {
    getElectiveSchemesCallCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FilterController controller;
  late FakeGitService service;
  late AppPreferencesController preferences;

  Future<void> pumpInitialized(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GitService>.value(value: service),
          ChangeNotifierProvider<AppPreferencesController>.value(
            value: preferences,
          ),
          ChangeNotifierProvider<FilterController>.value(value: controller),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) {
              controller.onInit(ctx);
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferencesController();
    await preferences.onInit();
    service = FakeGitService();
    controller = FilterController();
    controller.service = service;
    controller.preferences = preferences;
    controller.weekday = Weekday.monday;
  });

  group('activeSection setter', () {
    test('setting null clears sectionCode and section', () {
      service.sections = {'B16': 'B-16'};
      controller.activeSection = 'B-16';
      expect(controller.activeSection, 'B-16');
      expect(controller.activeSectionCode, 'B16');

      controller.activeSection = null;
      expect(controller.activeSection, isNull);
      expect(controller.activeSectionCode, isNull);
    });

    test('setting same section value is a no-op', () {
      service.sections = {'A16': 'A-16'};
      controller.activeSection = 'A-16';
      final code = controller.activeSectionCode;
      controller.activeSection = 'A-16';
      expect(controller.activeSectionCode, code);
    });

    test('updates activeSectionCode from sections map', () {
      service.sections = {'A16': 'A-16', 'B16': 'B-16'};
      controller.activeSection = 'B-16';
      expect(controller.activeSectionCode, 'B16');
    });

    test('activeSectionCode is null when no matching mapping exists', () {
      service.sections = {'A16': 'A-16'};
      controller.activeSection = 'NONEXISTENT';
      expect(controller.activeSectionCode, isNull);
    });
  });

  group('activeSemester setter', () {
    test('changing semester triggers getSections and clears section code', () {
      service.sections = {'A16': 'A-16'};
      controller.activeSection = 'A-16';
      expect(controller.activeSectionCode, 'A16');

      controller.activeSemester = 'SEM1';
      expect(controller.activeSemester, 'SEM1');
      expect(controller.activeSectionCode, isNull);
      expect(service.getSectionsCallCount, 1);
    });

    test('setting same semester does not call getSections again', () {
      controller.activeSemester = 'SEM1';
      controller.activeSemester = 'SEM1';
      expect(service.getSectionsCallCount, 1);
    });
  });

  group('elective setters', () {
    test('activeElectiveSemester resets scheme and code and fetches schemes',
        () {
      controller.activeElectiveScheme = 'Scheme A';
      controller.activeElectiveSchemeCode = 'a';
      controller.activeElectiveSemester = 'SEM2';

      expect(controller.activeElectiveSemester, 'SEM2');
      expect(controller.activeElectiveScheme, isNull);
      expect(controller.activeElectiveSchemeCode, isNull);
      expect(service.getElectiveSchemesCallCount, 1);
    });

    test('activeElectiveScheme ignores null assignment', () {
      controller.activeElectiveScheme = 'Scheme A';
      controller.activeElectiveScheme = null;
      expect(controller.activeElectiveScheme, 'Scheme A');
    });

    test('activeElectiveSchemeCode ignores null assignment', () {
      controller.activeElectiveSchemeCode = 'a';
      controller.activeElectiveSchemeCode = null;
      expect(controller.activeElectiveSchemeCode, 'a');
    });
  });

  group('getShortCode', () {
    test('returns placeholder when nothing selected', () {
      expect(controller.getShortCode(), 'Select Sections');
    });

    test('returns semester when only semester selected', () {
      controller.activeSemester = 'SEM1';
      expect(controller.getShortCode(), 'SEM1');
    });

    test('returns section when only section selected', () {
      service.sections = {'A16': 'A-16'};
      controller.activeSection = 'A-16';
      expect(controller.getShortCode(), 'A16');
    });

    test('returns combined code when both selected', () {
      service.sections = {'A16': 'A-16'};
      controller.activeSemester = 'SEM1';
      controller.activeSection = 'A-16';
      expect(controller.getShortCode(), 'A16 | SEM1');
    });
  });

  group('getElectiveShortCode', () {
    test('returns placeholder when nothing selected', () {
      expect(controller.getElectiveShortCode(), 'Select Elective');
    });

    test('returns semester only', () {
      controller.activeElectiveSemester = 'SEM2';
      expect(controller.getElectiveShortCode(), 'SEM2');
    });

    test('returns schemeCode only', () {
      controller.activeElectiveSchemeCode = 'a';
      expect(controller.getElectiveShortCode(), 'a');
    });

    test('returns both in uppercase', () {
      controller.activeElectiveSemester = 'sem2';
      controller.activeElectiveSchemeCode = 'a';
      expect(controller.getElectiveShortCode(), 'A | SEM2');
    });
  });

  group('primary preference getters', () {
    test('reads from preferences', () async {
      await preferences.savePrimarySectionPreference('A16');
      await preferences.savePrimarySemesterPreference('SEM1');
      await preferences.savePrimaryYearPreference('2024');
      await preferences.savePrimaryElectiveSchemePreference('a');
      await preferences.savePrimaryElectiveSemesterPreference('SEM2');
      await preferences.savePrimaryElectiveYearPreference('2024');

      expect(controller.primarySection, 'A16');
      expect(controller.primarySemester, 'SEM1');
      expect(controller.primaryYear, '2024');
      expect(controller.primaryElectiveScheme, 'a');
      expect(controller.primaryElectiveSemester, 'SEM2');
      expect(controller.primaryElectiveYear, '2024');
    });

    test('returns null when preference is absent', () {
      expect(controller.primarySection, isNull);
      expect(controller.primarySemester, isNull);
      expect(controller.primaryYear, isNull);
    });
  });

  group('setPrimarySection', () {
    test('does not set activeSection when primary not in sections', () async {
      service.sections = {'A16': 'A-16'};
      await preferences.savePrimarySectionPreference('Z99');

      await controller.setPrimarySection();
      expect(controller.activeSection, isNull);
    });

    test('sets activeSection from sections when primary is present', () async {
      service.sections = {'A16': 'A-16'};
      await preferences.savePrimarySectionPreference('A16');

      await controller.setPrimarySection();
      expect(controller.activeSection, 'A-16');
      expect(controller.activeSectionCode, 'A16');
    });
  });

  group('setPrimarySemester', () {
    test('sets active semester from preferences when in known list', () {
      service.semesters = ['SEM1', 'SEM2'];
      preferences.savePrimarySemesterPreference('SEM2');
      controller.setPrimarySemester();
      expect(controller.activeSemester, 'SEM2');
    });

    test('still sets active semester when service.semesters is null', () {
      preferences.savePrimarySemesterPreference('SEM3');
      controller.setPrimarySemester();
      expect(controller.activeSemester, 'SEM3');
    });

    test('does nothing when no primary semester saved', () {
      controller.setPrimarySemester();
      expect(controller.activeSemester, isNull);
    });
  });

  group('setPrimaryYear', () {
    test('sets selectedYear on service when valid', () async {
      service.filterController = controller;
      service.years = ['2024', '2023'];
      await preferences.savePrimaryYearPreference('2023');

      await controller.setPrimaryYear();
      expect(service.selectedYear, '2023');
    });

    test('does nothing when no primary year saved', () async {
      service.filterController = controller;
      service.years = ['2024'];
      await controller.setPrimaryYear();
      expect(service.selectedYear, isNull);
    });
  });

  group('setPrimaryElectiveScheme', () {
    test('sets active elective scheme when present in map', () async {
      service.electiveSchemes = {'a': 'Scheme A', 'b': 'Scheme B'};
      await preferences.savePrimaryElectiveSchemePreference('b');

      await controller.setPrimaryElectiveScheme();
      expect(controller.activeElectiveScheme, 'Scheme B');
      expect(controller.activeElectiveSchemeCode, 'b');
    });

    test('does not set when scheme is unknown', () async {
      service.electiveSchemes = {'a': 'Scheme A'};
      await preferences.savePrimaryElectiveSchemePreference('z');

      await controller.setPrimaryElectiveScheme();
      expect(controller.activeElectiveScheme, isNull);
      expect(controller.activeElectiveSchemeCode, isNull);
    });
  });

  group('setPrimaryElectiveSemester', () {
    test('sets elective semester from preferences', () async {
      service.electivesSemesters = ['SEM1', 'SEM2'];
      await preferences.savePrimaryElectiveSemesterPreference('SEM2');

      await controller.setPrimaryElectiveSemester();
      expect(controller.activeElectiveSemester, 'SEM2');
    });
  });

  group('setPrimaryElectiveYear', () {
    test('sets elective year from preferences', () async {
      service.filterController = controller;
      service.electiveYears = ['2024', '2023'];
      await preferences.savePrimaryElectiveYearPreference('2024');

      await controller.setPrimaryElectiveYear();
      expect(service.selectedElectiveYear, '2024');
    });
  });

  group('storePrimarySection', () {
    testWidgets('saves selected section to preferences', (tester) async {
      service.sections = {'A16': 'A-16'};
      await pumpInitialized(tester);
      controller.activeSection = 'A-16';

      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimarySection(ctx);
      expect(preferences.getPrimarySectionPreference(), 'A16');
    });

    testWidgets('does not save when no active section', (tester) async {
      await pumpInitialized(tester);
      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimarySection(ctx);
      expect(preferences.getPrimarySectionPreference(), isNull);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('storePrimarySemester', () {
    testWidgets('saves selected semester', (tester) async {
      await pumpInitialized(tester);
      controller.activeSemester = 'SEM1';
      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimarySemester(ctx);
      expect(preferences.getPrimarySemesterPreference(), 'SEM1');
    });

    testWidgets('does not save when no active semester', (tester) async {
      await pumpInitialized(tester);
      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimarySemester(ctx);
      expect(preferences.getPrimarySemesterPreference(), isNull);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('storePrimaryYear', () {
    testWidgets('saves selected year', (tester) async {
      service.filterController = controller;
      service.years = ['2024'];
      await pumpInitialized(tester);
      service.selectedYear = '2024';

      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimaryYear(ctx);
      expect(preferences.getPrimaryYearPreference(), '2024');
    });

    testWidgets('does not save when service.selectedYear is null',
        (tester) async {
      await pumpInitialized(tester);
      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimaryYear(ctx);
      expect(preferences.getPrimaryYearPreference(), isNull);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('storePrimaryElectiveScheme', () {
    testWidgets('saves selected elective scheme code', (tester) async {
      await pumpInitialized(tester);
      controller.activeElectiveSchemeCode = 'a';

      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimaryElectiveScheme(ctx);
      expect(preferences.getPrimaryElectiveSchemePreference(), 'a');
    });

    testWidgets('returns error future when no scheme is selected',
        (tester) async {
      await pumpInitialized(tester);
      final ctx = tester.element(find.byType(Scaffold));
      await expectLater(
        controller.storePrimaryElectiveScheme(ctx),
        throwsA(anything),
      );
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('storePrimaryElectiveSemester', () {
    testWidgets('saves selected elective semester', (tester) async {
      await pumpInitialized(tester);
      controller.activeElectiveSemester = 'SEM2';

      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimaryElectiveSemester(ctx);
      expect(preferences.getPrimaryElectiveSemesterPreference(), 'SEM2');
    });

    testWidgets('returns error future when no semester is selected',
        (tester) async {
      await pumpInitialized(tester);
      final ctx = tester.element(find.byType(Scaffold));
      await expectLater(
        controller.storePrimaryElectiveSemester(ctx),
        throwsA(anything),
      );
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('storePrimaryElectiveYear', () {
    testWidgets('saves selected elective year', (tester) async {
      service.filterController = controller;
      service.electiveYears = ['2024'];
      await pumpInitialized(tester);
      service.selectedElectiveYear = '2024';

      final ctx = tester.element(find.byType(Scaffold));
      await controller.storePrimaryElectiveYear(ctx);
      expect(preferences.getPrimaryElectiveYearPreference(), '2024');
    });

    testWidgets('returns error future when no elective year selected',
        (tester) async {
      await pumpInitialized(tester);
      final ctx = tester.element(find.byType(Scaffold));
      await expectLater(
        controller.storePrimaryElectiveYear(ctx),
        throwsA(anything),
      );
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('onInit', () {
    testWidgets('wires up service, preferences, and today\'s weekday',
        (tester) async {
      final fresh = FilterController();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GitService>.value(value: service),
            ChangeNotifierProvider<AppPreferencesController>.value(
              value: preferences,
            ),
          ],
          child: MaterialApp(
            home: Builder(builder: (ctx) {
              fresh.onInit(ctx);
              return const SizedBox();
            }),
          ),
        ),
      );

      expect(fresh.service, same(service));
      expect(fresh.preferences, same(preferences));
      expect(fresh.weekday, Weekday.today());
    });
  });
}

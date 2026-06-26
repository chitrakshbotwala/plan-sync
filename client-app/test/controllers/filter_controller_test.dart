import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository_impl.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mock_controllers/app_tour_controller_mock.dart';

class FakeSectionsRepository implements SectionsRepository {
  List<String> fakeYears = ['2024', '2023'];
  Map<String, List<String>> fakeSemesters = {
    '2024': ['SEM1', 'SEM2'],
    '2023': ['SEM1', 'SEM2'],
  };
  Map<String, Map<String, Map<String, String>>> fakeSections = {
    '2024': {
      'SEM1': {'A16': 'A-16', 'B16': 'B-16'},
      'SEM2': {'A16': 'A-16'},
    },
    '2023': {
      'SEM1': {'A16': 'A-16'},
    },
  };
  Map<String, Map<String, Map<String, String>?>> fakeElectiveSchemes = {
    '2024': {
      'SEM1': {'a': 'Scheme A', 'b': 'Scheme B'},
      'SEM2': {'a': 'Scheme A'},
    },
  };

  @override
  Future<List<String>> getYears() async => fakeYears;

  @override
  Future<List<String>> getSemesters(String year) async =>
      fakeSemesters[year] ?? [];

  @override
  Future<Map<String, String>> getSections(String year, String semester) async =>
      fakeSections[year]?[semester] ?? {};

  @override
  Future<List<String>> getElectiveYears() async => fakeYears;

  @override
  Future<List<String>> getElectiveSemesters(String year) async => [];

  @override
  Future<Map<String, String>?> getElectiveSchemes(
          String year, String semester) async =>
      fakeElectiveSchemes[year]?[semester];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FilterViewModel controller;
  late FakeSectionsRepository repository;
  late AppPreferencesRepositoryImpl preferences;
  late MockAppTourController appTour;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferencesRepositoryImpl();
    await preferences.onInit();
    repository = FakeSectionsRepository();
    appTour = MockAppTourController();
    controller = FilterViewModel(
      sectionsRepository: repository,
      preferences: preferences,
      appTour: appTour,
    );
    controller.weekday = Weekday.monday;
  });

  group('initialize', () {
    test('loads years from repository', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      expect(controller.years, ['2024', '2023']);
    });

    test('restores primary year when saved in preferences', () async {
      await preferences.savePrimaryYearPreference('2023');
      await controller.initialize();
      await Future.delayed(Duration.zero);
      expect(controller.selectedYear, '2023');
    });

    test('does not set selectedYear when primary not in years list', () async {
      await preferences.savePrimaryYearPreference('1999');
      await controller.initialize();
      await Future.delayed(Duration.zero);
      expect(controller.selectedYear, isNull);
    });
  });

  group('selectedYear setter', () {
    test('setting year loads semesters asynchronously', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      expect(controller.semesters, ['SEM1', 'SEM2']);
    });

    test('clears downstream state when year changes', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);

      controller.selectedYear = '2023';
      expect(controller.semesters, isNull);
      expect(controller.activeSemester, isNull);
      expect(controller.sections, isNull);
    });

    test('setting same year is a no-op', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      final semsBefore = controller.semesters;
      controller.selectedYear = '2024';
      expect(controller.semesters, semsBefore);
    });

    test('changing year clears elective schemes', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero); // schemes load for 2024/SEM1

      controller.selectedYear = '2023';
      expect(controller.electiveSchemes, isNull);
      expect(controller.activeElectiveSchemeCode, isNull);
    });
  });

  group('activeSemester setter', () {
    test('setting semester loads sections', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);
      expect(controller.sections, {'A16': 'A-16', 'B16': 'B-16'});
    });

    test('changing semester clears section', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);
      controller.activeSection = 'A-16';

      controller.activeSemester = 'SEM2';
      expect(controller.activeSection, isNull);
      expect(controller.activeSectionCode, isNull);
    });

    test('setting same semester is a no-op', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);
      final sectionsBefore = controller.sections;
      controller.activeSemester = 'SEM1';
      expect(controller.sections, sectionsBefore);
    });

    test('setting semester triggers elective scheme load', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);

      expect(controller.hasElectivesForCurrentSchedule, isTrue);
      expect(controller.electiveSchemes,
          containsPair('a', 'Scheme A'));
    });

    test('changing semester clears elective schemes', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);

      controller.activeSemester = 'SEM2';
      expect(controller.electiveSchemes, isNull);
    });
  });

  group('activeSection setter', () {
    setUp(() async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);
    });

    test('setting null clears sectionCode and section', () {
      controller.activeSection = 'A-16';
      expect(controller.activeSection, 'A-16');
      expect(controller.activeSectionCode, 'A16');

      controller.activeSection = null;
      expect(controller.activeSection, isNull);
      expect(controller.activeSectionCode, isNull);
    });

    test('setting same section value is a no-op', () {
      controller.activeSection = 'A-16';
      final code = controller.activeSectionCode;
      controller.activeSection = 'A-16';
      expect(controller.activeSectionCode, code);
    });

    test('updates activeSectionCode from sections map', () {
      controller.activeSection = 'B-16';
      expect(controller.activeSectionCode, 'B16');
    });

    test('activeSectionCode is null when no matching mapping exists', () {
      controller.activeSection = 'NONEXISTENT';
      expect(controller.activeSectionCode, isNull);
    });
  });

  group('elective scheme setters', () {
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

  group('hasElectivesForCurrentSchedule', () {
    test('is false when no schemes loaded', () {
      expect(controller.hasElectivesForCurrentSchedule, isFalse);
    });

    test('is true after year+semester with electives are set', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);
      expect(controller.hasElectivesForCurrentSchedule, isTrue);
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

    test('returns combined code when both selected', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);
      controller.activeSection = 'A-16';
      expect(controller.getShortCode(), 'A16 | SEM1');
    });
  });

  group('getElectiveShortCode', () {
    test('returns placeholder when nothing selected', () {
      expect(controller.getElectiveShortCode(), 'Select Elective');
    });

    test('returns semester only when no scheme selected', () {
      controller.activeSemester = 'SEM2';
      expect(controller.getElectiveShortCode(), 'SEM2');
    });

    test('returns schemeCode only when no semester selected', () {
      controller.activeElectiveSchemeCode = 'a';
      expect(controller.getElectiveShortCode(), 'a');
    });

    test('returns both in uppercase', () {
      controller.activeSemester = 'sem2';
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

      expect(controller.primarySection, 'A16');
      expect(controller.primarySemester, 'SEM1');
      expect(controller.primaryYear, '2024');
      expect(controller.primaryElectiveScheme, 'a');
    });

    test('returns null when preference is absent', () {
      expect(controller.primarySection, isNull);
      expect(controller.primarySemester, isNull);
      expect(controller.primaryYear, isNull);
    });
  });

  group('storePrimarySection', () {
    test('saves selected section to preferences', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);
      controller.activeSection = 'A-16';

      final result = await controller.storePrimarySection();
      expect(result, isTrue);
      expect(preferences.getPrimarySectionPreference(), 'A16');
    });

    test('returns false and does not save when no active section', () async {
      final result = await controller.storePrimarySection();
      expect(result, isFalse);
      expect(preferences.getPrimarySectionPreference(), isNull);
    });
  });

  group('storePrimarySemester', () {
    test('saves selected semester', () async {
      controller.activeSemester = 'SEM1';
      final result = await controller.storePrimarySemester();
      expect(result, isTrue);
      expect(preferences.getPrimarySemesterPreference(), 'SEM1');
    });

    test('returns false and does not save when no active semester', () async {
      final result = await controller.storePrimarySemester();
      expect(result, isFalse);
      expect(preferences.getPrimarySemesterPreference(), isNull);
    });
  });

  group('storePrimaryYear', () {
    test('saves selected year', () async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);

      final result = await controller.storePrimaryYear();
      expect(result, isTrue);
      expect(preferences.getPrimaryYearPreference(), '2024');
    });

    test('returns false when selectedYear is null', () async {
      final result = await controller.storePrimaryYear();
      expect(result, isFalse);
      expect(preferences.getPrimaryYearPreference(), isNull);
    });
  });

  group('storePrimaryElectiveScheme', () {
    test('saves selected elective scheme code', () async {
      controller.activeElectiveSchemeCode = 'a';
      final result = await controller.storePrimaryElectiveScheme();
      expect(result, isTrue);
      expect(preferences.getPrimaryElectiveSchemePreference(), 'a');
    });

    test('returns false when no scheme is selected', () async {
      final result = await controller.storePrimaryElectiveScheme();
      expect(result, isFalse);
    });
  });

  group('setChosenElective1', () {
    test('persists chosen subject and reads it back', () async {
      await controller.setChosenElective1('Machine Learning');
      expect(controller.chosenElective1, 'Machine Learning');
      expect(preferences.getChosenElective1(), 'Machine Learning');
    });

    test('clearing chosen subject removes it from preferences', () async {
      await controller.setChosenElective1('Machine Learning');
      await controller.setChosenElective1(null);
      expect(controller.chosenElective1, isNull);
      expect(preferences.getChosenElective1(), isNull);
    });
  });

  group('setChosenElective2', () {
    test('persists independently of slot 1', () async {
      await controller.setChosenElective1('Machine Learning');
      await controller.setChosenElective2('Data Structures');
      expect(controller.chosenElective1, 'Machine Learning');
      expect(controller.chosenElective2, 'Data Structures');
      expect(preferences.getChosenElective1(), 'Machine Learning');
      expect(preferences.getChosenElective2(), 'Data Structures');
    });

    test('clearing slot 2 does not affect slot 1', () async {
      await controller.setChosenElective1('Machine Learning');
      await controller.setChosenElective2('Data Structures');
      await controller.setChosenElective2(null);
      expect(controller.chosenElective1, 'Machine Learning');
      expect(controller.chosenElective2, isNull);
    });
  });

  group('isEarlySemester', () {
    test('returns true for "1"', () {
      expect(FilterViewModel.isEarlySemester('1'), isTrue);
    });

    test('returns true for "2"', () {
      expect(FilterViewModel.isEarlySemester('2'), isTrue);
    });

    test('returns true for "SEM1"', () {
      expect(FilterViewModel.isEarlySemester('SEM1'), isTrue);
    });

    test('returns true for "Semester 2"', () {
      expect(FilterViewModel.isEarlySemester('Semester 2'), isTrue);
    });

    test('returns false for "3"', () {
      expect(FilterViewModel.isEarlySemester('3'), isFalse);
    });

    test('returns false for null', () {
      expect(FilterViewModel.isEarlySemester(null), isFalse);
    });
  });

  group('auto scheme selection', () {
    setUp(() async {
      await controller.initialize();
      await Future.delayed(Duration.zero);
      controller.selectedYear = '2024';
      await Future.delayed(Duration.zero);
      controller.activeSemester = 'SEM1';
      await Future.delayed(Duration.zero);
    });

    test('auto-selects scheme from section letter A in SEM1', () {
      controller.activeSection = 'A-16';
      expect(controller.activeElectiveSchemeCode, 'a');
    });

    test('auto-selects scheme from section letter B in SEM1', () {
      controller.activeSection = 'B-16';
      expect(controller.activeElectiveSchemeCode, 'b');
    });

    test('scheme updates when section changes', () {
      controller.activeSection = 'A-16';
      expect(controller.activeElectiveSchemeCode, 'a');
      controller.activeSection = 'B-16';
      expect(controller.activeElectiveSchemeCode, 'b');
    });
  });
}

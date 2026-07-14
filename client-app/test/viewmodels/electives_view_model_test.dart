import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository_impl.dart';
import 'package:plan_sync/features/electives/viewmodel/electives_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mock_controllers/electives_repository_mock.dart';
import '../mock_controllers/filter_view_model_mock.dart';
import '../mock_controllers/remote_config_controller_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ElectivesViewModel vm;
  late MockFilterViewModel filterVM;
  late MockElectivesRepository repository;
  late MockRemoteConfigController remoteConfig;
  late AppPreferencesRepositoryImpl preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferencesRepositoryImpl();
    await preferences.onInit();
    filterVM = MockFilterViewModel(preferences);
    repository = MockElectivesRepository();
    remoteConfig = MockRemoteConfigController();
    vm = ElectivesViewModel(
      repository: repository,
      filterViewModel: filterVM,
      preferences: preferences,
      remoteConfig: remoteConfig,
    );
    await Future.delayed(Duration.zero); // let _loadStarredElectives complete
  });

  tearDown(() => vm.dispose());

  group('initial state', () {
    test('timetable is null when no filters selected', () {
      expect(vm.timetable, isNull);
      expect(vm.hasData, isFalse);
      expect(vm.isLoading, isFalse);
    });
  });

  group('uniqueSubjectNames', () {
    test('returns empty when timetable is null', () {
      expect(vm.uniqueSubjectNames, isEmpty);
    });

    test('returns sorted, deduplicated names across days', () async {
      repository.stage = MockElectivesRepositoryStage.success;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeElectiveSchemeCode = 'a';
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNotNull);
      // monday: Machine Learning, tuesday: Machine Learning + Data Structures, wednesday: Operating Systems
      // deduped + sorted: [Data Structures, Machine Learning, Operating Systems]
      expect(vm.uniqueSubjectNames,
          ['Data Structures', 'Machine Learning', 'Operating Systems']);
    });
  });

  group('loading lifecycle', () {
    test('timetable is set after successful stream emit', () async {
      repository.stage = MockElectivesRepositoryStage.success;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeElectiveSchemeCode = 'a';
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNotNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('errorMessage is set on stream error', () async {
      repository.stage = MockElectivesRepositoryStage.error;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeElectiveSchemeCode = 'a';
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNotNull);
    });
  });

  group('clearing filter resets state', () {
    test('setting schemeCode to null clears timetable', () async {
      repository.stage = MockElectivesRepositoryStage.success;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeElectiveSchemeCode = 'a';
      await Future.delayed(Duration.zero);
      expect(vm.timetable, isNotNull);

      filterVM.activeElectiveSchemeCode = null;
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNull);
      expect(vm.isLoading, isFalse);
    });
  });

  group('retry', () {
    test('retry with updated filter param succeeds after prior error', () async {
      repository.stage = MockElectivesRepositoryStage.error;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeElectiveSchemeCode = 'a';
      await Future.delayed(Duration.zero);
      expect(vm.errorMessage, isNotNull);

      // Changing scheme breaks the dedup guard, allowing a new load.
      repository.stage = MockElectivesRepositoryStage.success;
      filterVM.activeElectiveSchemeCode = 'b';
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNotNull);
      expect(vm.errorMessage, isNull);
    });
  });

  group('star/unstar electives', () {
    test('starElective adds to in-memory set', () {
      expect(vm.isElectiveStarred('elec-1'), isFalse);
      vm.starElective('elec-1');
      expect(vm.isElectiveStarred('elec-1'), isTrue);
    });

    test('unstarElective removes from in-memory set', () {
      vm.starElective('elec-1');
      vm.unstarElective('elec-1');
      expect(vm.isElectiveStarred('elec-1'), isFalse);
    });

    test('starElective persists to preferences', () async {
      vm.starElective('elec-persist');
      await Future.delayed(Duration.zero);
      final stored = await preferences.getStarredElectives();
      expect(stored, contains('elec-persist'));
    });

    test('unstarElective removes from preferences', () async {
      vm.starElective('elec-persist');
      await Future.delayed(Duration.zero);
      vm.unstarElective('elec-persist');
      await Future.delayed(Duration.zero);
      final stored = await preferences.getStarredElectives();
      expect(stored, isNot(contains('elec-persist')));
    });

    test('starred electives are restored from preferences on construction',
        () async {
      await preferences.starElective('restored-id');

      final newVm = ElectivesViewModel(
        repository: repository,
        filterViewModel: filterVM,
        preferences: preferences,
        remoteConfig: remoteConfig,
      );
      await Future.delayed(Duration.zero); // let _loadStarredElectives complete

      expect(newVm.isElectiveStarred('restored-id'), isTrue);
      newVm.dispose();
    });
  });

  group('showSigmaEmoji', () {
    test('delegates to remoteConfig', () {
      expect(vm.showSigmaEmoji, isFalse);
    });
  });
}

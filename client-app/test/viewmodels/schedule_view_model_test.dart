import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/schedule/viewmodel/schedule_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository_impl.dart';
import '../mock_controllers/filter_view_model_mock.dart';
import '../mock_controllers/schedule_repository_mock.dart';
import '../mock_controllers/remote_config_controller_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScheduleViewModel vm;
  late MockFilterViewModel filterVM;
  late MockScheduleRepository repository;
  late MockRemoteConfigController remoteConfig;
  late AppPreferencesRepositoryImpl preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferencesRepositoryImpl();
    await preferences.onInit();
    filterVM = MockFilterViewModel(preferences);
    repository = MockScheduleRepository();
    remoteConfig = MockRemoteConfigController();
    vm = ScheduleViewModel(
      repository: repository,
      filterViewModel: filterVM,
      remoteConfig: remoteConfig,
    );
  });

  tearDown(() => vm.dispose());

  group('initial state with no filters', () {
    test('timetable is null when no year/semester/section selected', () {
      expect(vm.timetable, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.hasData, isFalse);
    });
  });

  group('loading lifecycle', () {
    test('timetable is populated after successful load', () async {
      repository.stage = MockScheduleRepositoryStage.success;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeSectionCode = 'A16';
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNotNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.hasData, isTrue);
    });

    test('errorMessage is set on stream error', () async {
      repository.stage = MockScheduleRepositoryStage.noInternet;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeSectionCode = 'A16';
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNotNull);
    });
  });

  group('dedup guard', () {
    test('setting same params twice does not trigger a second load', () async {
      repository.stage = MockScheduleRepositoryStage.success;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeSectionCode = 'A16';
      await Future.delayed(Duration.zero);

      final firstTimetable = vm.timetable;

      // Trigger listener again with same values
      filterVM.activeSectionCode = 'A16';
      await Future.delayed(Duration.zero);

      expect(identical(vm.timetable, firstTimetable), isTrue);
    });
  });

  group('filter change triggers reload', () {
    test('changing section triggers a new load', () async {
      repository.stage = MockScheduleRepositoryStage.success;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeSectionCode = 'A16';
      await Future.delayed(Duration.zero);
      expect(vm.timetable, isNotNull);

      filterVM.activeSectionCode = 'B16';
      await Future.delayed(Duration.zero);
      expect(vm.timetable, isNotNull);
    });
  });

  group('clearing filter resets state', () {
    test('setting sectionCode to null clears timetable', () async {
      repository.stage = MockScheduleRepositoryStage.success;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeSectionCode = 'A16';
      await Future.delayed(Duration.zero);
      expect(vm.timetable, isNotNull);

      filterVM.activeSectionCode = null;
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });
  });

  group('retry', () {
    test('retry with updated filter param succeeds after prior error', () async {
      repository.stage = MockScheduleRepositoryStage.noInternet;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeSectionCode = 'A16';
      await Future.delayed(Duration.zero);
      expect(vm.errorMessage, isNotNull);

      // Changing a filter param breaks the dedup guard, allowing a new load.
      repository.stage = MockScheduleRepositoryStage.success;
      filterVM.activeSectionCode = 'B16';
      await Future.delayed(Duration.zero);

      expect(vm.timetable, isNotNull);
      expect(vm.errorMessage, isNull);
    });

    test('retry() with same params is a no-op (dedup guard)', () async {
      repository.stage = MockScheduleRepositoryStage.noInternet;
      filterVM.selectedYear = '2024';
      filterVM.activeSemester = 'SEM1';
      filterVM.activeSectionCode = 'A16';
      await Future.delayed(Duration.zero);
      expect(vm.errorMessage, isNotNull);

      // Retry with same params — dedup guard blocks the reload.
      repository.stage = MockScheduleRepositoryStage.success;
      vm.retry();
      await Future.delayed(Duration.zero);

      // Still has the error because retry is deduped
      expect(vm.timetable, isNull);
    });
  });

  group('showSigmaEmoji', () {
    test('delegates to remoteConfig', () {
      expect(vm.showSigmaEmoji, isFalse);
    });
  });
}

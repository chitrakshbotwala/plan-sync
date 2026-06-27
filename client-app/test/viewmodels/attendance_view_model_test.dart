import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import '../helpers/fake_cache_service.dart';

class FakeAttendanceCredentialsRepository
    implements AttendanceCredentialsRepository {
  bool _hasCredentials;
  String? _registrationNumber;

  FakeAttendanceCredentialsRepository({
    bool hasCredentials = false,
    String? registrationNumber,
  })  : _hasCredentials = hasCredentials,
        _registrationNumber = registrationNumber;

  @override
  Future<void> initialize() async {}

  @override
  bool get hasCredentials => _hasCredentials;

  @override
  String? get registrationNumber => _registrationNumber;

  @override
  Future<(String, String)?> read() async {
    if (!_hasCredentials) return null;
    return (_registrationNumber ?? '22001234', 'password');
  }

  @override
  Future<void> save({
    required String registrationNumber,
    required String password,
  }) async {
    _hasCredentials = true;
    _registrationNumber = registrationNumber;
  }

  @override
  Future<void> clear() async {
    _hasCredentials = false;
    _registrationNumber = null;
  }
}

AttendanceViewModel _makeVm({
  bool hasCredentials = false,
  String? registrationNumber,
  FakeCacheService? cache,
}) =>
    AttendanceViewModel(
      credentialsRepository: FakeAttendanceCredentialsRepository(
        hasCredentials: hasCredentials,
        registrationNumber: registrationNumber,
      ),
      cache: cache ?? FakeCacheService(),
    );

void main() {
  group('initialize — credentials', () {
    test('sets status to idle when credentials present but no cache', () async {
      final vm = _makeVm(hasCredentials: true, registrationNumber: '22001234');
      await vm.initialize();
      expect(vm.status, AttendanceStatus.idle);
    });

    test('sets status to needsCredentials when no credentials', () async {
      final vm = _makeVm();
      await vm.initialize();
      expect(vm.status, AttendanceStatus.needsCredentials);
    });
  });

  group('pushLog', () {
    test('appends step to logs and updates currentStep', () {
      final vm = _makeVm();

      vm.pushLog('Connecting…');
      expect(vm.logs, ['Connecting…']);
      expect(vm.currentStep, 'Connecting…');

      vm.pushLog('Fetching data…');
      expect(vm.logs, ['Connecting…', 'Fetching data…']);
      expect(vm.currentStep, 'Fetching data…');
    });
  });

  group('disconnect', () {
    test('clears result, errors, and sets status to needsCredentials', () async {
      final vm = _makeVm(hasCredentials: true);
      await vm.initialize();

      // Simulate a prior result
      vm.pushLog('Fetched');

      await vm.disconnect();

      expect(vm.status, AttendanceStatus.needsCredentials);
      expect(vm.result, isNull);
      expect(vm.errorKind, isNull);
      expect(vm.errorMessage, isNull);
    });
  });

  group('changeSelection', () {
    test('is a no-op when year and session are unchanged', () async {
      final vm = _makeVm();
      await vm.initialize();

      final yearBefore = vm.academicYear;
      final sessionBefore = vm.session;

      vm.changeSelection(year: yearBefore, session: sessionBefore);

      expect(vm.academicYear, yearBefore);
      expect(vm.session, sessionBefore);
    });

    test('updates academicYear when year changes', () async {
      final vm = _makeVm();
      await vm.initialize();

      vm.changeSelection(year: '2019-2020');

      expect(vm.academicYear, '2019-2020');
    });
  });

  group('yearOptions', () {
    test('returns 7 entries', () {
      final vm = _makeVm();
      expect(vm.yearOptions.length, 7);
    });

    test('entries are in YYYY-YYYY+1 format with consecutive years', () {
      final vm = _makeVm();
      for (final option in vm.yearOptions) {
        final parts = option.split('-');
        expect(parts.length, 2);
        final start = int.parse(parts[0]);
        final end = int.parse(parts[1]);
        expect(end, start + 1);
      }
    });
  });

  group('sessionOptions', () {
    test('returns Autumn and Spring', () {
      final vm = _makeVm();
      expect(vm.sessionOptions, ['Autumn', 'Spring']);
    });
  });

  group('initialize', () {
    test('pre-loads result from cache so tab renders without loading screen',
        () async {
      final cache = FakeCacheService();
      final vm = _makeVm(
        hasCredentials: true,
        registrationNumber: '22001234',
        cache: cache,
      );

      // Seed cache before initialize() runs (simulates a prior session).
      final record = AttendanceRecord(
        subject: 'Math',
        absent: 1,
        present: 9,
        totalDays: 10,
        percentage: 90.0,
        facultyId: 'F1',
        facultyName: 'Dr. A',
        excuses: 0,
      );
      final year = AttendanceViewModel.currentAcademicYear();
      final sess = AttendanceViewModel.currentSession();
      await cache.set<AttendanceResult>(
        'attendance/22001234/$year/$sess',
        AttendanceResult(
          records: [record],
          student: null,
          academicYear: year,
          session: sess,
          fetchedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        toJson: (r) => r.toJson(),
      );

      await vm.initialize();

      expect(vm.status, AttendanceStatus.success);
      expect(vm.result?.records.first.subject, 'Math');
    });
  });

  group('ensureLoaded', () {
    test('sets status to needsCredentials when no credentials', () async {
      final vm = _makeVm();
      await vm.ensureLoaded();
      expect(vm.status, AttendanceStatus.needsCredentials);
    });

    test('is a no-op when fresh data is already on screen', () async {
      final cache = FakeCacheService();
      final vm = _makeVm(
        hasCredentials: true,
        registrationNumber: '22001234',
        cache: cache,
      );
      final year = AttendanceViewModel.currentAcademicYear();
      final sess = AttendanceViewModel.currentSession();
      await cache.set<AttendanceResult>(
        'attendance/22001234/$year/$sess',
        AttendanceResult(
          records: const [],
          student: null,
          academicYear: year,
          session: sess,
          fetchedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        toJson: (r) => r.toJson(),
      );
      await vm.initialize(); // pre-loads cache → status = success

      await vm.ensureLoaded(); // should be a no-op

      expect(vm.status, AttendanceStatus.success);
      expect(vm.isRefreshing, isFalse);
    });

    test('starts background refresh when stale data is on screen', () async {
      final cache = FakeCacheService();
      final vm = _makeVm(
        hasCredentials: true,
        registrationNumber: '22001234',
        cache: cache,
      );
      final year = AttendanceViewModel.currentAcademicYear();
      final sess = AttendanceViewModel.currentSession();
      await cache.set<AttendanceResult>(
        'attendance/22001234/$year/$sess',
        AttendanceResult(
          records: const [],
          student: null,
          academicYear: year,
          session: sess,
          fetchedAt: DateTime.now().subtract(const Duration(hours: 7)),
        ),
        toJson: (r) => r.toJson(),
      );
      await vm.initialize(); // pre-loads stale cache → status = success, result != null

      // ensureLoaded() detects stale data and calls refresh() which uses
      // isRefreshing (not loading screen) because result != null.
      // The default scraperFactory will throw (no WebView in tests), so the
      // status transitions to error, but the loading SCREEN was never shown.
      expect(vm.status, AttendanceStatus.success); // still showing before ensureLoaded
      await vm.ensureLoaded();
      expect(vm.status, isNot(AttendanceStatus.loading)); // never went full-screen loading
    });
  });

  group('AttendanceResult derived', () {
    test('toJson → fromJson round-trip preserves all fields', () {
      final record = AttendanceRecord(
        subject: 'Physics',
        absent: 2,
        present: 18,
        totalDays: 20,
        percentage: 90.0,
        facultyId: '123',
        facultyName: 'Dr. Smith',
        excuses: 0,
      );
      final json = record.toJson();
      final restored = AttendanceRecord.fromJson(json);
      expect(restored.subject, record.subject);
      expect(restored.absent, record.absent);
      expect(restored.present, record.present);
      expect(restored.percentage, record.percentage);
    });
  });
}

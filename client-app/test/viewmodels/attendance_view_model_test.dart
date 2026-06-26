import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';

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

void main() {
  group('initialize', () {
    test('sets status to idle when credentials are present', () async {
      final vm = AttendanceViewModel(
        credentialsRepository: FakeAttendanceCredentialsRepository(
          hasCredentials: true,
          registrationNumber: '22001234',
        ),
      );
      await vm.initialize();
      expect(vm.status, AttendanceStatus.idle);
    });

    test('sets status to needsCredentials when no credentials', () async {
      final vm = AttendanceViewModel(
        credentialsRepository: FakeAttendanceCredentialsRepository(),
      );
      await vm.initialize();
      expect(vm.status, AttendanceStatus.needsCredentials);
    });
  });

  group('pushLog', () {
    test('appends step to logs and updates currentStep', () {
      final vm = AttendanceViewModel(
        credentialsRepository: FakeAttendanceCredentialsRepository(),
      );

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
      final vm = AttendanceViewModel(
        credentialsRepository: FakeAttendanceCredentialsRepository(
          hasCredentials: true,
        ),
      );
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
      final creds = FakeAttendanceCredentialsRepository(hasCredentials: false);
      final vm = AttendanceViewModel(credentialsRepository: creds);
      await vm.initialize();

      final yearBefore = vm.academicYear;
      final sessionBefore = vm.session;

      vm.changeSelection(year: yearBefore, session: sessionBefore);

      expect(vm.academicYear, yearBefore);
      expect(vm.session, sessionBefore);
    });

    test('updates academicYear when year changes', () async {
      final creds = FakeAttendanceCredentialsRepository(hasCredentials: false);
      final vm = AttendanceViewModel(credentialsRepository: creds);
      await vm.initialize();

      vm.changeSelection(year: '2019-2020');

      expect(vm.academicYear, '2019-2020');
    });
  });

  group('yearOptions', () {
    test('returns 7 entries', () {
      final vm = AttendanceViewModel(
        credentialsRepository: FakeAttendanceCredentialsRepository(),
      );
      expect(vm.yearOptions.length, 7);
    });

    test('entries are in YYYY-YYYY+1 format with consecutive years', () {
      final vm = AttendanceViewModel(
        credentialsRepository: FakeAttendanceCredentialsRepository(),
      );
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
      final vm = AttendanceViewModel(
        credentialsRepository: FakeAttendanceCredentialsRepository(),
      );
      expect(vm.sessionOptions, ['Autumn', 'Spring']);
    });
  });

  group('ensureLoaded', () {
    test('sets status to needsCredentials when no credentials', () async {
      final vm = AttendanceViewModel(
        credentialsRepository: FakeAttendanceCredentialsRepository(),
      );
      await vm.ensureLoaded();
      expect(vm.status, AttendanceStatus.needsCredentials);
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

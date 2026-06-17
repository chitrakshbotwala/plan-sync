import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/backend/models/timetable.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/controllers/git_service.dart';

/// Stub filter controller that captures interactions without going through
/// the real provider-wired controller. Avoids touching shared preferences.
class _StubFilterController implements FilterController {
  int setPrimaryYearCalls = 0;
  int setPrimarySemesterCalls = 0;
  int setPrimarySectionCalls = 0;
  int setPrimaryElectiveYearCalls = 0;
  int setPrimaryElectiveSemesterCalls = 0;
  int setPrimaryElectiveSchemeCalls = 0;

  String? _activeSemester;
  String? _activeElectiveSemester;
  String? _activeElectiveSchemeCode;
  String? _activeSectionCode;

  @override
  String? get activeSemester => _activeSemester;
  @override
  set activeSemester(String? value) {
    _activeSemester = value;
  }

  @override
  String? get activeElectiveSemester => _activeElectiveSemester;
  @override
  set activeElectiveSemester(String? value) {
    _activeElectiveSemester = value;
  }

  @override
  String? get activeElectiveSchemeCode => _activeElectiveSchemeCode;
  @override
  set activeElectiveSchemeCode(String? value) {
    _activeElectiveSchemeCode = value;
  }

  @override
  String? get activeSectionCode => _activeSectionCode;
  @override
  set activeSectionCode(String? value) {
    _activeSectionCode = value;
  }

  @override
  Future<void> setPrimaryYear() async {
    setPrimaryYearCalls++;
  }

  @override
  void setPrimarySemester() {
    setPrimarySemesterCalls++;
  }

  @override
  Future<void> setPrimarySection() async {
    setPrimarySectionCalls++;
  }

  @override
  Future<void> setPrimaryElectiveYear() async {
    setPrimaryElectiveYearCalls++;
  }

  @override
  Future<void> setPrimaryElectiveSemester() async {
    setPrimaryElectiveSemesterCalls++;
  }

  @override
  Future<void> setPrimaryElectiveScheme() async {
    setPrimaryElectiveSchemeCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GitService service;
  late _StubFilterController filter;

  setUp(() {
    service = GitService();
    filter = _StubFilterController();
    service.filterController = filter;
  });

  group('setRepositoryBranch', () {
    test('uses dev branch in debug/profile builds', () {
      // The branch is selected by kReleaseMode at build time; under the
      // test runner that's always false, so we can only assert the
      // non-release branch here.
      service.setRepositoryBranch();
      expect(service.branch, 'dev');
    });
  });

  group('selectedYear', () {
    test('null assignment after a non-null value preserves the value', () {
      service.selectedYear = '2024';
      filter.activeSemester = 'SEM1';
      service.selectedYear = null;
      // setter early-returns on null: the prior value AND its side-effects
      // (activeSemester cleared) are preserved
      expect(service.selectedYear, '2024');
      expect(filter.activeSemester, 'SEM1');
    });

    test('assigning same value is a no-op', () {
      service.selectedYear = '2024';
      filter.activeSemester = 'SEM1';
      service.selectedYear = '2024';
      // setter early-returns: activeSemester should not be cleared
      expect(filter.activeSemester, 'SEM1');
    });

    test('assigning new value clears semester and notifies', () {
      var notifications = 0;
      service.addListener(() => notifications++);

      filter.activeSemester = 'SEM1';
      service.selectedYear = '2024';

      expect(service.selectedYear, '2024');
      expect(filter.activeSemester, isNull);
      expect(notifications, 1);
    });
  });

  group('selectedElectiveYear', () {
    test('null assignment after a non-null value preserves the value', () {
      service.selectedElectiveYear = '2024';
      filter.activeElectiveSemester = 'SEM2';
      service.selectedElectiveYear = null;
      expect(service.selectedElectiveYear, '2024');
      expect(filter.activeElectiveSemester, 'SEM2');
    });

    test('assigning same value does nothing', () {
      service.selectedElectiveYear = '2024';
      filter.activeElectiveSemester = 'SEM2';
      service.selectedElectiveYear = '2024';
      expect(filter.activeElectiveSemester, 'SEM2');
    });

    test('new value clears elective semester and notifies', () {
      var notifications = 0;
      service.addListener(() => notifications++);

      filter.activeElectiveSemester = 'SEM2';
      service.selectedElectiveYear = '2023';

      expect(service.selectedElectiveYear, '2023');
      expect(filter.activeElectiveSemester, isNull);
      expect(notifications, 1);
    });
  });

  group('semesters', () {
    test('null assignment is ignored', () {
      service.semesters = ['SEM1'];
      service.semesters = null;
      expect(service.semesters, ['SEM1']);
    });

    test('assignment updates value and returns defensive copy', () {
      final input = ['SEM1', 'SEM2'];
      service.semesters = input;
      expect(service.semesters, ['SEM1', 'SEM2']);
      // returned list should be a copy: mutating it must not affect storage
      service.semesters!.add('SEM3');
      expect(service.semesters, ['SEM1', 'SEM2']);
    });

    test('notifies listeners on update', () {
      var notifications = 0;
      service.addListener(() => notifications++);
      service.semesters = ['SEM1'];
      expect(notifications, 1);
    });
  });

  group('electivesSemesters', () {
    test('null clears stored value and notifies', () {
      service.electivesSemesters = ['SEM1'];
      var notifications = 0;
      service.addListener(() => notifications++);
      service.electivesSemesters = null;
      expect(service.electivesSemesters, isNull);
      expect(notifications, 1);
    });

    test('empty list clears stored value', () {
      service.electivesSemesters = ['SEM1'];
      service.electivesSemesters = [];
      expect(service.electivesSemesters, isNull);
    });

    test('valid list is stored', () {
      service.electivesSemesters = ['SEM1', 'SEM2'];
      expect(service.electivesSemesters, ['SEM1', 'SEM2']);
    });
  });

  group('getSections early-return', () {
    test('returns without throwing when activeSemester is null', () async {
      service.semesters = ['SEM1'];
      // intentionally no filterController.activeSemester
      await expectLater(service.getSections(filter), completes);
    });

    test('returns without throwing when selectedYear is null', () async {
      filter.activeSemester = 'SEM1';
      service.semesters = ['SEM1'];
      // no selectedYear
      await expectLater(service.getSections(filter), completes);
    });

    test('returns without throwing when semesters is null', () async {
      filter.activeSemester = 'SEM1';
      service.selectedYear = '2024';
      await expectLater(service.getSections(filter), completes);
    });
  });

  group('getTimeTable early-return', () {
    test('yields null and ends stream when nothing selected', () async {
      final items = await service.getTimeTable(filter).toList();
      expect(items, [null]);
    });

    test('yields null when only year is selected', () async {
      service.selectedYear = '2024';
      final items = await service.getTimeTable(filter).toList();
      expect(items, [null]);
    });

    test('yields null when semester missing', () async {
      service.selectedYear = '2024';
      filter.activeSectionCode = 'A16';
      final items = await service.getTimeTable(filter).toList();
      expect(items, [null]);
    });
  });

  group('getElectives early-return', () {
    test('yields empty stream when nothing selected', () async {
      final items = await service.getElectives().toList();
      expect(items, isEmpty);
    });

    test('yields empty stream when only scheme is selected', () async {
      filter.activeElectiveSchemeCode = 'a';
      final items = await service.getElectives().toList();
      expect(items, isEmpty);
    });

    test('yields empty stream when only semester is selected', () async {
      filter.activeElectiveSemester = 'SEM2';
      final items = await service.getElectives().toList();
      expect(items, isEmpty);
    });
  });

  group('getElectiveSemesters early-return', () {
    testWidgets('returns when selectedElectiveYear is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) {
            // ignore: discarded_futures
            service.getElectiveSemesters(ctx);
            return const SizedBox();
          }),
        ),
      );
      // no exception is enough; the call short-circuits
      expect(service.errorDetails, isNull);
    });
  });

  group('getElectiveSchemes early-return', () {
    test('returns when activeElectiveSemester is null', () async {
      await expectLater(
        service.getElectiveSchemes(filterController: filter),
        completes,
      );
    });

    test('asserts when both context and filterController are null', () {
      expect(
        () => service.getElectiveSchemes(),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('setYear', () {
    test('delegates to filterController.setPrimaryYear', () {
      service.setYear();
      expect(filter.setPrimaryYearCalls, 1);
    });
  });

  group('Timetable model used by service', () {
    test('parses minimal payload', () {
      final t = Timetable.fromJson(json: {
        'meta': {
          'section': 'a16',
          'type': 'norm-class',
          'revision': 'r1',
          'effective-date': 'today',
          'contributor': 'tester',
          'isTimetableUpdating': false,
        },
        'data': {
          'monday': [
            {'time': '09:00 - 10:00', 'subject': 'Math', 'room': '101'}
          ],
        },
      });
      expect(t.data['monday']!.first.subject, 'Math');
      expect(t.isFresh, isTrue);
    });
  });
}

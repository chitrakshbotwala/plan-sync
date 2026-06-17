import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/backend/models/timetable.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/controllers/git_service.dart';

enum MockGitServiceStages {
  /// success request
  success,

  /// raises no internet exception
  noInternet,

  /// sets updating to `true`
  scheduleUpdating,

  /// No section is selected
  noneSelected,
}

class MockGitService extends Mock with ChangeNotifier implements GitService {
  MockGitServiceStages stage = MockGitServiceStages.success;

  @override
  late FilterController filterController;

  @override
  Future<void> onInit() async {}

  @override
  Future<void> onReady(BuildContext ctx) async {}

  @override
  Future<void> getYears(BuildContext context) async {}

  @override
  Future<void> getSemesters(BuildContext context) async {}

  @override
  Future<void> getSections(FilterController filterController) async {}

  @override
  Future<void> getElectiveYears(BuildContext context) async {}

  @override
  Future<void> getElectiveSemesters(BuildContext context) async {}

  @override
  Future<void> getElectiveSchemes({
    BuildContext? context,
    FilterController? filterController,
  }) async {}

  @override
  Future<String?> fetchMininumVersion() async => null;

  String? _selectedElectiveYear;
  @override
  String? get selectedElectiveYear => _selectedElectiveYear;
  @override
  set selectedElectiveYear(String? newYear) {
    if (newYear == null || selectedElectiveYear == newYear) return;
    _selectedElectiveYear = newYear;
    notifyListeners();
  }

  List<String>? _electiveYears = const ["2024", "2023", "2022"];
  @override
  set electiveYears(List<String>? newElectiveYears) {
    _electiveYears = newElectiveYears;
    notifyListeners();
  }

  @override
  List<String>? get electiveYears => _electiveYears;

  Map? _electiveSchemes = {
    "a": "Sch. A (BTECH-CSE)",
    "b": "Sch. B (BTECH-CSE)",
  };

  @override
  set electiveSchemes(Map? newElectiveSchemes) {
    _electiveSchemes = newElectiveSchemes;
    notifyListeners();
  }

  @override
  Map? get electiveSchemes => _electiveSchemes;

  List? _electivesSemesters = const ["SEM1", "SEM2"];
  @override
  set electivesSemesters(List? newElectivesSemesters) {
    _electivesSemesters = newElectivesSemesters;
    notifyListeners();
  }

  @override
  List? get electivesSemesters => _electivesSemesters;

  Map? _sections;
  set sections(Map? newvalue) {
    _sections = newvalue;
    notifyListeners();
  }

  @override
  Map? get sections => _sections;

  List? _semesters = const ["SEM1", "SEM2"];

  @override
  set semesters(List? newSemesters) {
    _semesters = newSemesters;
    notifyListeners();
  }

  @override
  List? get semesters => _semesters;

  String? _selectedYear;
  @override
  set selectedYear(String? newYear) {
    if (newYear == null) return;
    _selectedYear = newYear;
    notifyListeners();
  }

  @override
  String? get selectedYear => _selectedYear;

  @override
  List<String>? get years => const ["2024", "2023", "2022"];

  @override
  Stream<Timetable?> getTimeTable(FilterController filterController) async* {
    bool isTimetableUpdating = false;

    if (stage == MockGitServiceStages.scheduleUpdating) {
      isTimetableUpdating = true;
    }

    if (stage == MockGitServiceStages.noInternet) {
      yield* Stream.error(
        DioException.connectionError(
          requestOptions: RequestOptions(),
          reason: 'No Internet',
        ),
      );
    }

    if (stage == MockGitServiceStages.noneSelected) {
      yield* const Stream.empty();
      return;
    }

    yield Timetable.fromJson(json: {
      "meta": {
        "section": "b16",
        "type": "norm-class",
        "revision": "Revision 1.03",
        "effective-date": "Jan 15, 2024 (Satrudays' valid till Apr 13)",
        "contributor": "PlanSync Admin :)",
        "isTimetableUpdating": isTimetableUpdating
      },
      "data": {
        "monday": [
          {"time": "08:00 - 09:00", "subject": "Electives", "room": "301"},
          {"time": "09:00 - 09:20", "subject": "***", "room": "301"},
          {"time": "09:20 - 10:20", "subject": "EVS", "room": "301"},
          {"time": "10:20 - 11:20", "subject": "Physics", "room": "301"},
          {"time": "11:20 - 13:20", "subject": "T & NM.", "room": "301"},
          {"time": "13:20 - 14:20", "subject": "Sc LS.", "room": "301"},
        ],
        "tuesday": [
          {"time": "08:00 - 09:00", "subject": "Electives", "room": "306"},
        ],
        "wednesday": [
          {"time": "08:00 - 09:00", "subject": "Electives", "room": "404"},
        ],
        "thursday": [
          {"time": "08:00 - 09:00", "subject": "Electives", "room": "402"},
        ],
        "friday": [
          {"time": "08:00 - 09:00", "subject": "Electives", "room": "403"},
        ],
        "saturday": [
          {"time": "08:00 - 09:00", "subject": "Electives", "room": "301"},
        ]
      }
    });
  }

  @override
  Stream<Timetable?> getElectives() async* {
    yield Timetable.fromJson(json: {
      "meta": {
        "type": "electives",
        "revision": "Revision 1.01",
        "effective-date": "Jan 15, 2024",
        "name": "Electives Configuration for Scheme A",
        "isTimetableUpdating": false
      },
      "data": {
        "monday": [
          {"subject": "EM01", "room": "Room 102"},
        ],
        "tuesday": [
          {"subject": "***", "room": "***"}
        ],
        "wednesday": [
          {"subject": "SST01", "room": "Room C-23"},
        ],
        "thursday": [
          {"subject": "***", "room": "***"}
        ],
        "friday": [
          {"subject": "SST01", "room": "Room CLA4"},
        ],
        "saturday": [
          {"subject": "EM01", "room": "Room 102"},
        ]
      }
    });
  }
}

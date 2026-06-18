import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/controllers/git_service.dart';
import 'package:plan_sync/util/enums.dart';
import 'package:provider/provider.dart';

class MockFilterController extends Mock
    with ChangeNotifier
    implements FilterController {
  @override
  late GitService service;

  @override
  late AppPreferencesController preferences;

  @override
  String? get activeYear => service.selectedYear;

  @override
  void onInit(BuildContext context) {
    service = Provider.of<GitService>(context, listen: false);
    preferences = Provider.of<AppPreferencesController>(
      context,
      listen: false,
    );
    service.addListener(notifyListeners);
  }

  String? _activeSectionCode;
  @override
  set activeSectionCode(String? newSectionCode) {
    _activeSectionCode = newSectionCode;
    notifyListeners();
  }

  @override
  String? get activeSectionCode => _activeSectionCode;

  String? _activeElectiveScheme;
  @override
  set activeElectiveScheme(String? newValue) {
    if (newValue == null) {
      _activeElectiveScheme = null;
      notifyListeners();
      return;
    }
    _activeElectiveScheme = newValue;
    notifyListeners();
  }

  @override
  String? get activeElectiveScheme => _activeElectiveScheme;

  String? _activeElectiveSchemeCode;

  @override
  String? get activeElectiveSchemeCode => _activeElectiveSchemeCode;
  @override
  set activeElectiveSchemeCode(String? newValue) {
    _activeElectiveSchemeCode = newValue;
    notifyListeners();
  }

  String? _activeElectiveSemester;

  @override
  set activeElectiveSemester(String? newValue) {
    _activeElectiveSemester = newValue;
    notifyListeners();
  }

  @override
  String? get activeElectiveSemester => _activeElectiveSemester;

  Weekday _weekday = Weekday.today();
  @override
  Weekday get weekday => _weekday;
  @override
  set weekday(Weekday newWeekday) {
    _weekday = newWeekday;
    notifyListeners();
  }

  String? _activeSection;
  @override
  set activeSection(String? newSection) {
    _activeSection = newSection;
    notifyListeners();
  }

  @override
  String? get activeSection => _activeSection;

  String? _activeSemester;
  @override
  set activeSemester(String? newValue) {
    if (activeSemester == newValue) {
      return;
    }
    _activeSemester = newValue;
    notifyListeners();
  }

  @override
  String? get activeSemester => _activeSemester;

  @override
  String getShortCode() {
    String? section = activeSectionCode;
    String? semester = activeSemester;

    if (section == null && semester == null) {
      return 'Select Sections';
    } else if (section == null && semester != null) {
      return semester;
    } else if (semester == null && section != null) {
      return section;
    }

    return '$section | $semester'.toUpperCase();
  }

  @override
  Future<void> storePrimarySection(BuildContext context) async {
    if (activeSectionCode == null) {
      return;
    }
    final res =
        await preferences.savePrimarySectionPreference(activeSectionCode!);
    if (res == false) {
      return Future.error('Couldnt save');
    }
    notifyListeners();
  }

  @override
  Future<void> storePrimarySemester(BuildContext context) async {
    if (activeSemester == null) {
      return;
    }
    final res =
        await preferences.savePrimarySemesterPreference(activeSemester!);
    if (res == false) {
      return Future.error('Couldnt save');
    }
    notifyListeners();
  }

  @override
  Future<void> storePrimaryYear(BuildContext context) async {
    if (service.selectedYear == null) {
      return;
    }
    final res = await preferences.savePrimaryYearPreference(
      service.selectedYear!.toString(),
    );
    if (res == false) {
      return Future.error('Couldnt save');
    }
    notifyListeners();
  }

  @override
  Future<void> storePrimaryElectiveScheme(BuildContext context) async {
    if (activeElectiveSchemeCode == null) {
      return Future.error('error');
    }
    final res = await preferences
        .savePrimaryElectiveSchemePreference(activeElectiveSchemeCode!);
    if (res == false) {
      return;
    }
    notifyListeners();
  }

  @override
  Future<void> storePrimaryElectiveSemester(BuildContext context) async {
    if (activeElectiveSemester == null) {
      return;
    }
    final res = await preferences
        .savePrimaryElectiveSemesterPreference(activeElectiveSemester!);
    if (res == false) {
      return;
    }
    notifyListeners();
  }

  @override
  Future<void> storePrimaryElectiveYear(BuildContext context) async {
    if (service.selectedElectiveYear == null) {
      return;
    }
    final res = await preferences.savePrimaryElectiveYearPreference(
      service.selectedElectiveYear!.toString(),
    );
    if (res == false) {
      return;
    }
    notifyListeners();
  }
}

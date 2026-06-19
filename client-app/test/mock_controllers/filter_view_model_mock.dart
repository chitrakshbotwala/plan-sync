import 'package:mockito/mockito.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:flutter/material.dart';
import 'package:plan_sync/util/enums.dart';

class MockFilterViewModel extends Mock
    with ChangeNotifier
    implements FilterViewModel {
  MockFilterViewModel(this._prefsController);

  final AppPreferencesRepository _prefsController;

  // --- Schedule metadata ---

  @override
  List<String>? years = const ['2024', '2023', '2022'];

  String? _selectedYear;
  @override
  String? get selectedYear => _selectedYear;
  @override
  set selectedYear(String? newYear) {
    if (newYear == null || _selectedYear == newYear) return;
    _selectedYear = newYear;
    notifyListeners();
  }

  final List<String> _semesters = const ['SEM1', 'SEM2'];
  @override
  List<String>? get semesters => _semesters;

  Map<String, String>? _sections;
  @override
  Map<String, String>? get sections => _sections;
  set sections(Map<String, String>? newSections) {
    _sections = newSections;
    notifyListeners();
  }

  // --- Elective metadata ---

  @override
  List<String>? electiveYears = const ['2024', '2023', '2022'];

  String? _selectedElectiveYear;
  @override
  String? get selectedElectiveYear => _selectedElectiveYear;
  @override
  set selectedElectiveYear(String? newYear) {
    if (newYear == null || _selectedElectiveYear == newYear) return;
    _selectedElectiveYear = newYear;
    notifyListeners();
  }

  List<String>? _electivesSemesters = const ['SEM1', 'SEM2'];
  @override
  List<String>? get electivesSemesters => _electivesSemesters;
  set electivesSemesters(List<String>? value) {
    _electivesSemesters = value;
    notifyListeners();
  }

  Map<String, String>? _electiveSchemes = const {
    'a': 'Sch. A (BTECH-CSE)',
    'b': 'Sch. B (BTECH-CSE)',
  };
  @override
  Map<String, String>? get electiveSchemes => _electiveSchemes;
  @override
  set electiveSchemes(Map<String, String>? newSchemes) {
    _electiveSchemes = newSchemes;
    notifyListeners();
  }

  // --- Selection state ---

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
    if (_activeSemester == newValue) return;
    _activeSemester = newValue;
    notifyListeners();
  }

  @override
  String? get activeSemester => _activeSemester;

  @override
  String? get activeYear => _selectedYear;

  @override
  String? get activeElectiveYear => _selectedElectiveYear;

  @override
  Future<void> initialize() async {}

  @override
  String getShortCode() {
    final section = _activeSectionCode;
    final semester = _activeSemester;
    if (section == null && semester == null) return 'Select Sections';
    if (section == null) return semester!;
    if (semester == null) return section;
    return '$section | $semester'.toUpperCase();
  }

  @override
  String getElectiveShortCode() {
    final section = _activeElectiveSchemeCode;
    final semester = _activeElectiveSemester;
    if (section == null && semester == null) return 'Select Elective';
    if (section == null) return semester!;
    if (semester == null) return section;
    return '$section | $semester'.toUpperCase();
  }

  AppPreferencesRepository get _prefs => _prefsController;

  @override
  Future<bool> storePrimarySection() async {
    if (_activeSectionCode == null) return false;
    final res = await _prefs.savePrimarySectionPreference(_activeSectionCode!);
    if (res) notifyListeners();
    return res;
  }

  @override
  Future<bool> storePrimarySemester() async {
    if (_activeSemester == null) return false;
    final res = await _prefs.savePrimarySemesterPreference(_activeSemester!);
    if (res) notifyListeners();
    return res;
  }

  @override
  Future<bool> storePrimaryYear() async {
    if (_selectedYear == null) return false;
    final res = await _prefs.savePrimaryYearPreference(_selectedYear!);
    if (res) notifyListeners();
    return res;
  }

  @override
  Future<bool> storePrimaryElectiveScheme() async {
    if (_activeElectiveSchemeCode == null) return false;
    final res = await _prefs.savePrimaryElectiveSchemePreference(_activeElectiveSchemeCode!);
    if (res) notifyListeners();
    return res;
  }

  @override
  Future<bool> storePrimaryElectiveSemester() async {
    if (_activeElectiveSemester == null) return false;
    final res = await _prefs.savePrimaryElectiveSemesterPreference(_activeElectiveSemester!);
    if (res) notifyListeners();
    return res;
  }

  @override
  Future<bool> storePrimaryElectiveYear() async {
    if (_selectedElectiveYear == null) return false;
    final res = await _prefs.savePrimaryElectiveYearPreference(_selectedElectiveYear!);
    if (res) notifyListeners();
    return res;
  }

  @override
  String? get primarySection => null;
  @override
  String? get primarySemester => null;
  @override
  String? get primaryYear => null;
  @override
  String? get primaryElectiveScheme => null;
  @override
  String? get primaryElectiveSemester => null;
  @override
  String? get primaryElectiveYear => null;
}

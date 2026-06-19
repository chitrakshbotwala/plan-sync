import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository.dart';
import 'package:plan_sync/util/enums.dart';
import 'package:plan_sync/util/logger.dart';
import 'package:plan_sync/util/snackbar.dart';

class FilterController extends ChangeNotifier {
  FilterController({
    required SectionsRepository sectionsRepository,
    required AppPreferencesController preferences,
  })  : _repository = sectionsRepository,
        _preferences = preferences;

  final SectionsRepository _repository;
  final AppPreferencesController _preferences;

  // --- Schedule metadata (owned here, was on GitService) ---

  List<String>? years;

  String? _selectedYear;
  String? get selectedYear => _selectedYear;
  set selectedYear(String? newYear) {
    if (newYear == null || _selectedYear == newYear) return;
    _selectedYear = newYear;
    _semesters = null;
    _activeSemester = null;
    _activeSectionCode = null;
    _activeSection = null;
    _sections = null;
    notifyListeners();
    _loadSemesters();
  }

  List<String>? _semesters;
  List<String>? get semesters => _semesters?.toList();

  Map<String, String>? _sections;
  Map<String, String>? get sections => _sections;

  // --- Elective metadata (owned here, was on GitService) ---

  List<String>? electiveYears;

  String? _selectedElectiveYear;
  String? get selectedElectiveYear => _selectedElectiveYear;
  set selectedElectiveYear(String? newYear) {
    if (newYear == null || _selectedElectiveYear == newYear) return;
    _selectedElectiveYear = newYear;
    _electivesSemesters = null;
    _activeElectiveSemester = null;
    _activeElectiveScheme = null;
    _activeElectiveSchemeCode = null;
    electiveSchemes = null;
    notifyListeners();
    _loadElectiveSemesters();
  }

  List<String>? _electivesSemesters;
  List<String>? get electivesSemesters => _electivesSemesters?.toList();

  Map<String, String>? electiveSchemes;

  // --- Selection state ---

  String? _activeSection;
  String? get activeSection => _activeSection;
  set activeSection(String? newSection) {
    if (_activeSection == newSection) return;
    if (newSection == null) {
      _activeSectionCode = null;
      _activeSection = null;
      notifyListeners();
      return;
    }
    _activeSection = newSection;
    activeSectionCode = newSection;
  }

  String? _activeSectionCode;
  String? get activeSectionCode => _activeSectionCode;
  set activeSectionCode(String? newSectionCode) {
    final code = _sections?.keys
        .firstWhereOrNull((key) => _sections![key] == newSectionCode);
    _activeSectionCode = code;
    Logger.i('new section code: $code');
    notifyListeners();
  }

  String? _activeSemester;
  String? get activeSemester => _activeSemester;
  set activeSemester(String? newValue) {
    if (_activeSemester == newValue) return;
    _activeSemester = newValue;
    _activeSectionCode = null;
    _activeSection = null;
    _sections = null;
    notifyListeners();
    _loadSections();
  }

  String? _activeElectiveSemester;
  String? get activeElectiveSemester => _activeElectiveSemester;
  set activeElectiveSemester(String? newValue) {
    _activeElectiveSemester = newValue;
    _activeElectiveScheme = null;
    _activeElectiveSchemeCode = null;
    electiveSchemes = null;
    notifyListeners();
    _loadElectiveSchemes();
  }

  String? _activeElectiveSchemeCode;
  String? get activeElectiveSchemeCode => _activeElectiveSchemeCode;
  set activeElectiveSchemeCode(String? newValue) {
    if (newValue == null) return;
    _activeElectiveSchemeCode = newValue;
    notifyListeners();
  }

  String? _activeElectiveScheme;
  String? get activeElectiveScheme => _activeElectiveScheme;
  set activeElectiveScheme(String? newValue) {
    if (newValue == null) return;
    _activeElectiveScheme = newValue;
    notifyListeners();
  }

  late Weekday _weekday;
  Weekday get weekday => _weekday;
  set weekday(Weekday newWeekday) {
    _weekday = newWeekday;
    notifyListeners();
  }

  String? get activeYear => _selectedYear;
  String? get activeElectiveYear => _selectedElectiveYear;

  // --- Initialization ---

  Future<void> initialize() async {
    _weekday = Weekday.today();
    await Future.wait([
      _loadYears(),
      _loadElectiveYears(),
    ]);
  }

  Future<void> _loadYears() async {
    try {
      years = await _repository.getYears();
      await _setPrimaryYear();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterController._loadYears failed: $e');
    }
  }

  Future<void> _loadSemesters() async {
    if (_selectedYear == null) return;
    try {
      _semesters = await _repository.getSemesters(_selectedYear!);
      await _setPrimarySemester();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterController._loadSemesters failed: $e');
    }
  }

  Future<void> _loadSections() async {
    if (_selectedYear == null || _activeSemester == null) return;
    try {
      _sections =
          await _repository.getSections(_selectedYear!, _activeSemester!);
      await _setPrimarySection();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterController._loadSections failed: $e');
    }
  }

  Future<void> _loadElectiveYears() async {
    try {
      electiveYears = await _repository.getElectiveYears();
      await _setPrimaryElectiveYear();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterController._loadElectiveYears failed: $e');
    }
  }

  Future<void> _loadElectiveSemesters() async {
    if (_selectedElectiveYear == null) return;
    try {
      _electivesSemesters =
          await _repository.getElectiveSemesters(_selectedElectiveYear!);
      await _setPrimaryElectiveSemester();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterController._loadElectiveSemesters failed: $e');
    }
  }

  Future<void> _loadElectiveSchemes() async {
    if (_selectedElectiveYear == null || _activeElectiveSemester == null) {
      return;
    }
    try {
      electiveSchemes = await _repository.getElectiveSchemes(
        _selectedElectiveYear!,
        _activeElectiveSemester!,
      );
      await _setPrimaryElectiveScheme();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterController._loadElectiveSchemes failed: $e');
    }
  }

  // --- Short codes ---

  String getShortCode() {
    final section = _activeSectionCode;
    final semester = _activeSemester;
    if (section == null && semester == null) return 'Select Sections';
    if (section == null) return semester!;
    if (semester == null) return section;
    return '$section | $semester'.toUpperCase();
  }

  String getElectiveShortCode() {
    final section = _activeElectiveSchemeCode;
    final semester = _activeElectiveSemester;
    if (section == null && semester == null) return 'Select Elective';
    if (section == null) return semester!;
    if (semester == null) return section;
    return '$section | $semester'.toUpperCase();
  }

  // --- Primary preference: schedule ---

  String? get primarySection => _preferences.getPrimarySectionPreference();

  Future<void> storePrimarySection(BuildContext context) async {
    if (_activeSectionCode == null) {
      CustomSnackbar.error('Not Selected',
          'Please select a section to be saved as default', context);
      return;
    }
    final res =
        await _preferences.savePrimarySectionPreference(_activeSectionCode!);
    if (!res) {
      CustomSnackbar.error(
          'Error', 'Primary Section wasn\'t saved. Try again', context);
      return;
    }
    Logger.i('set $_activeSectionCode as primary');
    notifyListeners();
  }

  Future<void> _setPrimarySection() async {
    _activeSection = null;
    final primary = _preferences.getPrimarySectionPreference();
    if (primary != null &&
        _sections != null &&
        _sections!.containsKey(primary)) {
      activeSection = _sections![primary];
    }
  }

  String? get primarySemester => _preferences.getPrimarySemesterPreference();

  Future<void> storePrimarySemester(BuildContext context) async {
    if (_activeSemester == null) {
      CustomSnackbar.error('Not Selected',
          'Please select a semester to be saved as default', context);
      return;
    }
    final res =
        await _preferences.savePrimarySemesterPreference(_activeSemester!);
    if (!res) {
      CustomSnackbar.error(
          'Error', 'Primary Semester wasn\'t saved. Try again', context);
      return;
    }
    Logger.i('set $_activeSemester as primary semester');
    notifyListeners();
  }

  Future<void> _setPrimarySemester() async {
    final primary = _preferences.getPrimarySemesterPreference();
    if (primary != null && _semesters?.contains(primary) == true) {
      activeSemester = primary;
    }
  }

  String? get primaryYear => _preferences.getPrimaryYearPreference();

  Future<void> storePrimaryYear(BuildContext context) async {
    if (_selectedYear == null) {
      CustomSnackbar.error('Not Selected',
          'Please select a year to be saved as default', context);
      return;
    }
    final res = await _preferences.savePrimaryYearPreference(_selectedYear!);
    if (!res) {
      CustomSnackbar.error(
          'Error', 'Primary Year wasn\'t saved. Try again', context);
      return;
    }
    Logger.i('set $_selectedYear as primary year');
    notifyListeners();
  }

  Future<void> _setPrimaryYear() async {
    final primary = _preferences.getPrimaryYearPreference();
    if (primary != null && years?.contains(primary) == true) {
      selectedYear = primary;
    }
  }

  // --- Primary preference: electives ---

  String? get primaryElectiveScheme =>
      _preferences.getPrimaryElectiveSchemePreference();

  Future<void> storePrimaryElectiveScheme(BuildContext context) async {
    if (_activeElectiveSchemeCode == null) {
      CustomSnackbar.error('Not Selected',
          'Please select a section to be saved as default', context);
      return Future.error('error');
    }
    final res = await _preferences
        .savePrimaryElectiveSchemePreference(_activeElectiveSchemeCode!);
    if (!res) {
      CustomSnackbar.error(
          'Error', 'Primary Section wasn\'t saved. Try again', context);
      return;
    }
    Logger.i('set $_activeElectiveSchemeCode as primary');
    notifyListeners();
  }

  Future<void> _setPrimaryElectiveScheme() async {
    _activeElectiveScheme = null;
    final primary = _preferences.getPrimaryElectiveSchemePreference();
    if (primary != null &&
        electiveSchemes != null &&
        electiveSchemes!.containsKey(primary)) {
      _activeElectiveScheme = electiveSchemes![primary];
      _activeElectiveSchemeCode = primary;
      notifyListeners();
    }
  }

  String? get primaryElectiveSemester =>
      _preferences.getPrimaryElectiveSemesterPreference();

  Future<void> storePrimaryElectiveSemester(BuildContext context) async {
    if (_activeElectiveSemester == null) {
      CustomSnackbar.error('Not Selected',
          'Please select a semester to be saved as default', context);
      return Future.error('error');
    }
    final res = await _preferences
        .savePrimaryElectiveSemesterPreference(_activeElectiveSemester!);
    if (!res) {
      CustomSnackbar.error(
          'Error', 'Primary Semester wasn\'t saved. Try again', context);
      return;
    }
    Logger.i('set $_activeElectiveSemester as primary elective-semester');
    notifyListeners();
  }

  Future<void> _setPrimaryElectiveSemester() async {
    final primary = _preferences.getPrimaryElectiveSemesterPreference();
    if (primary != null && _electivesSemesters?.contains(primary) == true) {
      activeElectiveSemester = primary;
    }
  }

  String? get primaryElectiveYear =>
      _preferences.getPrimaryElectiveYearPreference();

  Future<void> storePrimaryElectiveYear(BuildContext context) async {
    if (_selectedElectiveYear == null) {
      CustomSnackbar.error('Not Selected',
          'Please select a year to be saved as default', context);
      return Future.error('error');
    }
    final res = await _preferences
        .savePrimaryElectiveYearPreference(_selectedElectiveYear!);
    if (!res) {
      CustomSnackbar.error(
          'Error', 'Primary Year wasn\'t saved. Try again', context);
      return;
    }
    Logger.i('set $_selectedElectiveYear as primary year');
    notifyListeners();
  }

  Future<void> _setPrimaryElectiveYear() async {
    final primary = _preferences.getPrimaryElectiveYearPreference();
    if (primary != null && electiveYears?.contains(primary) == true) {
      selectedElectiveYear = primary;
    }
  }
}

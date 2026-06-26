import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/services/app_tour_service.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/core/util/logger.dart';

class FilterViewModel extends ChangeNotifier {
  FilterViewModel({
    required SectionsRepository sectionsRepository,
    required AppPreferencesRepository preferences,
    required AppTourService appTour,
  })  : _repository = sectionsRepository,
        _preferences = preferences,
        _appTour = appTour;

  final SectionsRepository _repository;
  final AppPreferencesRepository _preferences;
  final AppTourService _appTour;

  GlobalKey get sectionBarKey => _appTour.sectionBarKey;
  GlobalKey get doneButtonKey => _appTour.doneButtonKey;

  // --- Schedule metadata ---

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
    _clearElectiveScheme();
    notifyListeners();
    _loadSemesters();
  }

  List<String>? _semesters;
  List<String>? get semesters => _semesters?.toList();

  Map<String, String>? _sections;
  Map<String, String>? get sections => _sections;

  // --- Elective scheme metadata (tied to regular year + semester) ---

  Map<String, String>? electiveSchemes;

  bool get hasElectivesForCurrentSchedule =>
      electiveSchemes != null && electiveSchemes!.isNotEmpty;

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
    // After code is resolved, auto-derive scheme for early semesters.
    _autoSelectScheme();
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
    _clearElectiveScheme();
    notifyListeners();
    _loadSections();
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

  // --- Chosen elective subjects (up to 2, both optional) ---

  String? _chosenElective1;
  String? get chosenElective1 => _chosenElective1;

  String? _chosenElective2;
  String? get chosenElective2 => _chosenElective2;

  Future<void> setChosenElective1(String? subjectName) async {
    _chosenElective1 = subjectName;
    notifyListeners();
    await _preferences.saveChosenElective1(subjectName);
  }

  Future<void> setChosenElective2(String? subjectName) async {
    _chosenElective2 = subjectName;
    notifyListeners();
    await _preferences.saveChosenElective2(subjectName);
  }

  late Weekday _weekday;
  Weekday get weekday => _weekday;
  set weekday(Weekday newWeekday) {
    _weekday = newWeekday;
    notifyListeners();
  }

  String? get activeYear => _selectedYear;

  // --- Initialization ---

  Future<void> initialize() async {
    _weekday = Weekday.today();
    _chosenElective1 = _preferences.getChosenElective1();
    _chosenElective2 = _preferences.getChosenElective2();
    await _loadYears();
  }

  Future<void> _loadYears() async {
    try {
      years = await _repository.getYears();
      _setPrimaryYear();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterViewModel._loadYears error: $e');
    }
  }

  Future<void> _loadSemesters() async {
    if (_selectedYear == null) return;
    try {
      _semesters = await _repository.getSemesters(_selectedYear!);
      _setPrimarySemester();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterViewModel._loadSemesters error: $e');
    }
  }

  Future<void> _loadSections() async {
    if (_selectedYear == null || _activeSemester == null) return;
    try {
      _sections =
          await _repository.getSections(_selectedYear!, _activeSemester!);
      _setPrimarySection();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterViewModel._loadSections error: $e');
    }
  }

  Future<void> _loadElectiveSchemes() async {
    if (_selectedYear == null || _activeSemester == null) return;
    try {
      electiveSchemes = await _repository.getElectiveSchemes(
          _selectedYear!, _activeSemester!);
      _autoSelectScheme();
      notifyListeners();
    } catch (e) {
      Logger.e('FilterViewModel._loadElectiveSchemes error: $e');
    }
  }

  // --- Scheme auto-selection ---

  /// Returns true when [semester] represents semester 1 or 2.
  /// Works for values like "1", "2", "SEM1", "SEM2", "Sem 1", "Semester 2", etc.
  static bool isEarlySemester(String? semester) {
    if (semester == null) return false;
    final match = RegExp(r'\d+').firstMatch(semester);
    if (match == null) return false;
    final num = int.tryParse(match.group(0) ?? '');
    return num == 1 || num == 2;
  }

  /// Automatically picks the elective scheme without user input:
  ///   - Semesters 1 & 2: derive from the first letter of the section name
  ///     (e.g. section "A-16" → scheme code "a").
  ///   - Other semesters: auto-select the sole scheme if there is exactly one.
  /// Call this whenever section or the schemes map changes.
  void _autoSelectScheme() {
    if (electiveSchemes == null || electiveSchemes!.isEmpty) return;

    if (isEarlySemester(_activeSemester)) {
      // Derive scheme from first letter of the section display name.
      if (_activeSection == null) return;
      final letter = _activeSection![0].toUpperCase();
      // Scheme code is conventionally the lowercase letter (e.g. 'a', 'b').
      final schemeCode = electiveSchemes!.keys
          .firstWhereOrNull((code) => code.toUpperCase() == letter);
      if (schemeCode != null && schemeCode != _activeElectiveSchemeCode) {
        _activeElectiveSchemeCode = schemeCode;
        _activeElectiveScheme = electiveSchemes![schemeCode];
        notifyListeners();
      }
    } else {
      // For other semesters, if there is exactly one scheme, auto-select it.
      if (electiveSchemes!.length == 1) {
        final entry = electiveSchemes!.entries.first;
        if (entry.key != _activeElectiveSchemeCode) {
          _activeElectiveSchemeCode = entry.key;
          _activeElectiveScheme = entry.value;
          notifyListeners();
        }
      }
    }
  }

  void _clearElectiveScheme() {
    electiveSchemes = null;
    _activeElectiveScheme = null;
    _activeElectiveSchemeCode = null;
    _chosenElective1 = null;
    _chosenElective2 = null;
    unawaited(_preferences.saveChosenElective1(null));
    unawaited(_preferences.saveChosenElective2(null));
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
    final scheme = _activeElectiveSchemeCode;
    final semester = _activeSemester;
    if (scheme == null && semester == null) return 'Select Elective';
    if (scheme == null) return semester!;
    if (semester == null) return scheme;
    return '$scheme | $semester'.toUpperCase();
  }

  // --- Primary preference reads ---

  String? get primarySection => _preferences.getPrimarySectionPreference();
  String? get primarySemester => _preferences.getPrimarySemesterPreference();
  String? get primaryYear => _preferences.getPrimaryYearPreference();
  String? get primaryElectiveScheme =>
      _preferences.getPrimaryElectiveSchemePreference();

  // --- Primary preference saves ---

  Future<bool> storePrimarySection() async {
    if (_activeSectionCode == null) return false;
    final res =
        await _preferences.savePrimarySectionPreference(_activeSectionCode!);
    if (res) {
      Logger.i('set $_activeSectionCode as primary');
      notifyListeners();
    }
    return res;
  }

  Future<bool> storePrimarySemester() async {
    if (_activeSemester == null) return false;
    final res =
        await _preferences.savePrimarySemesterPreference(_activeSemester!);
    if (res) {
      Logger.i('set $_activeSemester as primary semester');
      notifyListeners();
    }
    return res;
  }

  Future<bool> storePrimaryYear() async {
    if (_selectedYear == null) return false;
    final res = await _preferences.savePrimaryYearPreference(_selectedYear!);
    if (res) {
      Logger.i('set $_selectedYear as primary year');
      notifyListeners();
    }
    return res;
  }

  Future<bool> storePrimaryElectiveScheme() async {
    if (_activeElectiveSchemeCode == null) return false;
    final res = await _preferences
        .savePrimaryElectiveSchemePreference(_activeElectiveSchemeCode!);
    if (res) {
      Logger.i('set $_activeElectiveSchemeCode as primary');
      notifyListeners();
    }
    return res;
  }

  // --- Primary preference auto-apply ---

  void _setPrimarySection() {
    _activeSection = null;
    final primary = _preferences.getPrimarySectionPreference();
    if (primary != null &&
        _sections != null &&
        _sections!.containsKey(primary)) {
      activeSection = _sections![primary];
    }
  }

  void _setPrimarySemester() {
    final primary = _preferences.getPrimarySemesterPreference();
    if (primary != null && _semesters?.contains(primary) == true) {
      activeSemester = primary;
    }
  }

  void _setPrimaryYear() {
    final primary = _preferences.getPrimaryYearPreference();
    if (primary != null && years?.contains(primary) == true) {
      selectedYear = primary;
    }
  }
}

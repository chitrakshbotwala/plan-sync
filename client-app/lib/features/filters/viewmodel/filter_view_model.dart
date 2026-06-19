import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository.dart';
import 'package:plan_sync/util/enums.dart';
import 'package:plan_sync/util/logger.dart';

class FilterViewModel extends ChangeNotifier {
  FilterViewModel({
    required SectionsRepository sectionsRepository,
    required AppPreferencesController preferences,
  })  : _repository = sectionsRepository,
        _preferences = preferences;

  final SectionsRepository _repository;
  final AppPreferencesController _preferences;

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
    notifyListeners();
    _loadSemesters();
  }

  List<String>? _semesters;
  List<String>? get semesters => _semesters?.toList();

  Map<String, String>? _sections;
  Map<String, String>? get sections => _sections;

  // --- Elective metadata ---

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

  // --- Stream subscriptions ---

  StreamSubscription<List<String>>? _yearsSub;
  StreamSubscription<List<String>>? _semestersSub;
  StreamSubscription<Map<String, String>>? _sectionsSub;
  StreamSubscription<List<String>>? _electiveYearsSub;
  StreamSubscription<List<String>>? _electiveSemestersSub;
  StreamSubscription<Map<String, String>?>? _electiveSchemesSub;

  // --- Initialization ---

  Future<void> initialize() async {
    _weekday = Weekday.today();
    _loadYears();
    _loadElectiveYears();
  }

  void _loadYears() {
    _yearsSub?.cancel();
    _yearsSub = _repository.getYears().listen(
      (data) {
        years = data;
        _setPrimaryYear();
        notifyListeners();
      },
      onError: (e) => Logger.e('FilterViewModel._loadYears error: $e'),
    );
  }

  void _loadSemesters() {
    if (_selectedYear == null) return;
    _semestersSub?.cancel();
    _semestersSub = _repository.getSemesters(_selectedYear!).listen(
      (data) {
        _semesters = data;
        _setPrimarySemester();
        notifyListeners();
      },
      onError: (e) => Logger.e('FilterViewModel._loadSemesters error: $e'),
    );
  }

  void _loadSections() {
    if (_selectedYear == null || _activeSemester == null) return;
    _sectionsSub?.cancel();
    _sectionsSub =
        _repository.getSections(_selectedYear!, _activeSemester!).listen(
      (data) {
        _sections = data;
        _setPrimarySection();
        notifyListeners();
      },
      onError: (e) => Logger.e('FilterViewModel._loadSections error: $e'),
    );
  }

  void _loadElectiveYears() {
    _electiveYearsSub?.cancel();
    _electiveYearsSub = _repository.getElectiveYears().listen(
      (data) {
        electiveYears = data;
        _setPrimaryElectiveYear();
        notifyListeners();
      },
      onError: (e) => Logger.e('FilterViewModel._loadElectiveYears error: $e'),
    );
  }

  void _loadElectiveSemesters() {
    if (_selectedElectiveYear == null) return;
    _electiveSemestersSub?.cancel();
    _electiveSemestersSub =
        _repository.getElectiveSemesters(_selectedElectiveYear!).listen(
      (data) {
        _electivesSemesters = data;
        _setPrimaryElectiveSemester();
        notifyListeners();
      },
      onError: (e) =>
          Logger.e('FilterViewModel._loadElectiveSemesters error: $e'),
    );
  }

  void _loadElectiveSchemes() {
    if (_selectedElectiveYear == null || _activeElectiveSemester == null) {
      return;
    }
    _electiveSchemesSub?.cancel();
    _electiveSchemesSub = _repository
        .getElectiveSchemes(_selectedElectiveYear!, _activeElectiveSemester!)
        .listen(
      (data) {
        electiveSchemes = data;
        _setPrimaryElectiveScheme();
        notifyListeners();
      },
      onError: (e) =>
          Logger.e('FilterViewModel._loadElectiveSchemes error: $e'),
    );
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

  // --- Primary preference reads ---

  String? get primarySection => _preferences.getPrimarySectionPreference();
  String? get primarySemester => _preferences.getPrimarySemesterPreference();
  String? get primaryYear => _preferences.getPrimaryYearPreference();
  String? get primaryElectiveScheme =>
      _preferences.getPrimaryElectiveSchemePreference();
  String? get primaryElectiveSemester =>
      _preferences.getPrimaryElectiveSemesterPreference();
  String? get primaryElectiveYear =>
      _preferences.getPrimaryElectiveYearPreference();

  // --- Primary preference saves (no BuildContext) ---

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

  Future<bool> storePrimaryElectiveSemester() async {
    if (_activeElectiveSemester == null) return false;
    final res = await _preferences
        .savePrimaryElectiveSemesterPreference(_activeElectiveSemester!);
    if (res) {
      Logger.i('set $_activeElectiveSemester as primary elective-semester');
      notifyListeners();
    }
    return res;
  }

  Future<bool> storePrimaryElectiveYear() async {
    if (_selectedElectiveYear == null) return false;
    final res = await _preferences
        .savePrimaryElectiveYearPreference(_selectedElectiveYear!);
    if (res) {
      Logger.i('set $_selectedElectiveYear as primary year');
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

  void _setPrimaryElectiveScheme() {
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

  void _setPrimaryElectiveSemester() {
    final primary = _preferences.getPrimaryElectiveSemesterPreference();
    if (primary != null && _electivesSemesters?.contains(primary) == true) {
      activeElectiveSemester = primary;
    }
  }

  void _setPrimaryElectiveYear() {
    final primary = _preferences.getPrimaryElectiveYearPreference();
    if (primary != null && electiveYears?.contains(primary) == true) {
      selectedElectiveYear = primary;
    }
  }

  @override
  void dispose() {
    _yearsSub?.cancel();
    _semestersSub?.cancel();
    _sectionsSub?.cancel();
    _electiveYearsSub?.cancel();
    _electiveSemestersSub?.cancel();
    _electiveSchemesSub?.cancel();
    super.dispose();
  }
}

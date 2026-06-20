import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';
import 'package:plan_sync/features/electives/repository/electives_repository.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';

class ElectivesViewModel extends ChangeNotifier {
  ElectivesViewModel({
    required ElectivesRepository repository,
    required FilterViewModel filterViewModel,
    required AppPreferencesRepository preferences,
    required RemoteConfigService remoteConfig,
  })  : _repository = repository,
        _filterViewModel = filterViewModel,
        _preferences = preferences,
        _remoteConfig = remoteConfig {
    _filterViewModel.addListener(_onStateChanged);
    _loadStarredElectives();
    _tryLoad();
  }

  final ElectivesRepository _repository;
  final FilterViewModel _filterViewModel;
  final AppPreferencesRepository _preferences;
  final RemoteConfigService _remoteConfig;
  StreamSubscription<Timetable?>? _sub;

  String? _lastYear;
  String? _lastSemester;
  String? _lastSchemeCode;

  Timetable? timetable;
  bool isLoading = false;
  String? errorMessage;

  final Set<String> _starredIds = {};

  bool get hasData => timetable != null;

  bool get showSigmaEmoji => _remoteConfig.canShowSigmaEmoji();

  bool isElectiveStarred(String electiveId) => _starredIds.contains(electiveId);

  void starElective(String electiveId) {
    _starredIds.add(electiveId);
    notifyListeners();
    _preferences.starElective(electiveId);
  }

  void unstarElective(String electiveId) {
    _starredIds.remove(electiveId);
    notifyListeners();
    _preferences.unstarElective(electiveId);
  }

  Future<void> _loadStarredElectives() async {
    final starred = await _preferences.getStarredElectives();
    _starredIds.addAll(starred);
    notifyListeners();
  }

  void _onStateChanged() => _tryLoad();

  void _tryLoad() {
    final year = _filterViewModel.activeElectiveYear;
    final semester = _filterViewModel.activeElectiveSemester;
    final schemeCode = _filterViewModel.activeElectiveSchemeCode;

    if (year == null || semester == null || schemeCode == null) {
      _sub?.cancel();
      _lastYear = null;
      _lastSemester = null;
      _lastSchemeCode = null;
      timetable = null;
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return;
    }

    if (year == _lastYear &&
        semester == _lastSemester &&
        schemeCode == _lastSchemeCode) {
      return;
    }

    _lastYear = year;
    _lastSemester = semester;
    _lastSchemeCode = schemeCode;

    _load(year: year, semester: semester, schemeCode: schemeCode);
  }

  void _load({
    required String year,
    required String semester,
    required String schemeCode,
  }) {
    _sub?.cancel();
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _sub = _repository
        .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
        .listen(
      (data) {
        timetable = data;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        isLoading = false;
        errorMessage = 'Could not load electives. Pull to retry.';
        notifyListeners();
      },
    );
  }

  void retry() => _tryLoad();

  @override
  void dispose() {
    _sub?.cancel();
    _filterViewModel.removeListener(_onStateChanged);
    super.dispose();
  }
}

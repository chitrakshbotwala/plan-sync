import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plan_sync/backend/models/timetable.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/features/electives/repository/electives_repository.dart';

class ElectivesViewModel extends ChangeNotifier {
  ElectivesViewModel({
    required ElectivesRepository repository,
    required FilterController filterController,
  })  : _repository = repository,
        _filterController = filterController {
    _filterController.addListener(_onStateChanged);
    _tryLoad();
  }

  final ElectivesRepository _repository;
  final FilterController _filterController;
  StreamSubscription<Timetable?>? _sub;

  String? _lastYear;
  String? _lastSemester;
  String? _lastSchemeCode;

  Timetable? timetable;
  bool isLoading = false;
  String? errorMessage;

  bool get hasData => timetable != null;

  void _onStateChanged() => _tryLoad();

  void _tryLoad() {
    final year = _filterController.activeElectiveYear;
    final semester = _filterController.activeElectiveSemester;
    final schemeCode = _filterController.activeElectiveSchemeCode;

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
    _filterController.removeListener(_onStateChanged);
    super.dispose();
  }
}

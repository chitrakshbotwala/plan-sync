import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plan_sync/backend/models/timetable.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository.dart';

class ScheduleViewModel extends ChangeNotifier {
  ScheduleViewModel({
    required ScheduleRepository repository,
    required FilterController filterController,
  })  : _repository = repository,
        _filterController = filterController {
    _filterController.addListener(_onStateChanged);
    _tryLoad();
  }

  final ScheduleRepository _repository;
  final FilterController _filterController;
  StreamSubscription<Timetable?>? _sub;

  // Track last-loaded params to avoid redundant fetches on unrelated notifies.
  String? _lastYear;
  String? _lastSemester;
  String? _lastSection;

  Timetable? timetable;
  bool isLoading = false;
  String? errorMessage;

  bool get hasData => timetable != null;

  void _onStateChanged() => _tryLoad();

  void _tryLoad() {
    final year = _filterController.activeYear;
    final semester = _filterController.activeSemester;
    final section = _filterController.activeSectionCode;

    if (year == null || semester == null || section == null) {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      return;
    }

    if (year == _lastYear &&
        semester == _lastSemester &&
        section == _lastSection) {
      return;
    }

    _lastYear = year;
    _lastSemester = semester;
    _lastSection = section;

    _load(year: year, semester: semester, section: section);
  }

  void _load({
    required String year,
    required String semester,
    required String section,
  }) {
    _sub?.cancel();
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _sub = _repository
        .getSchedule(year: year, semester: semester, section: section)
        .listen(
      (data) {
        timetable = data;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        isLoading = false;
        errorMessage = 'Could not load your schedule. Pull to retry.';
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

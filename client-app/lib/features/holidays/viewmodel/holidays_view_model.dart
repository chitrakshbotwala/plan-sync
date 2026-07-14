import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/features/holidays/model/holiday.dart';
import 'package:plan_sync/features/holidays/repository/holidays_repository.dart';

class HolidaysViewModel extends ChangeNotifier {
  HolidaysViewModel({
    required HolidaysRepository repository,
    required FilterViewModel filterViewModel,
  })  : _repository = repository,
        _filterViewModel = filterViewModel {
    _filterViewModel.addListener(_onFiltersChanged);
    _tryLoad();
  }

  final HolidaysRepository _repository;
  final FilterViewModel _filterViewModel;
  StreamSubscription<List<Holiday>>? _sub;

  String? _lastYear;

  List<Holiday> holidays = [];
  bool isLoading = false;
  String? errorMessage;

  /// True when the year's holiday list simply isn't published yet (404),
  /// as opposed to a transient failure worth retrying.
  bool notPublished = false;

  /// The academic year the holidays are being shown for (driven by the
  /// schedule preferences chosen on the home screen).
  String? get year => _filterViewModel.activeYear;

  bool get hasData => holidays.isNotEmpty;

  /// Holidays bucketed by month and returned in true calendar order so the
  /// list reads like a timeline. Each entry's key is the first day of the
  /// month; its value is that month's holidays sorted by start date.
  List<MapEntry<DateTime, List<Holiday>>> get grouped {
    final sorted = [...holidays]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final map = <String, List<Holiday>>{};
    final keyToDate = <String, DateTime>{};
    for (final h in sorted) {
      final monthDate = DateTime(h.startDate.year, h.startDate.month);
      final key = '${monthDate.year}-${monthDate.month}';
      keyToDate[key] = monthDate;
      map.putIfAbsent(key, () => []).add(h);
    }

    return map.entries
        .map((e) => MapEntry(keyToDate[e.key]!, e.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  void _onFiltersChanged() => _tryLoad();

  void _tryLoad() {
    final year = _filterViewModel.activeYear;

    if (year == null) {
      _sub?.cancel();
      _lastYear = null;
      holidays = [];
      isLoading = false;
      errorMessage = null;
      notPublished = false;
      notifyListeners();
      return;
    }

    if (year == _lastYear) return;
    _lastYear = year;
    _load(year: year);
  }

  void _load({required String year}) {
    _sub?.cancel();
    isLoading = true;
    errorMessage = null;
    notPublished = false;
    notifyListeners();

    _sub = _repository.getHolidays(year: year).listen(
      (data) {
        holidays = data;
        isLoading = false;
        errorMessage = null;
        notPublished = false;
        notifyListeners();
      },
      onError: (Object e) {
        isLoading = false;
        if (e is HolidaysNotPublishedException) {
          notPublished = true;
        } else {
          errorMessage = 'Could not load holidays. Pull to retry.';
        }
        notifyListeners();
      },
    );
  }

  void retry() {
    _lastYear = null;
    _tryLoad();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _filterViewModel.removeListener(_onFiltersChanged);
    super.dispose();
  }
}

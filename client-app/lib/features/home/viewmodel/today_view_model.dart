import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plan_sync/core/services/home_widget_service.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/core/util/extensions.dart';
import 'package:plan_sync/features/electives/viewmodel/electives_view_model.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/features/holidays/model/holiday.dart';
import 'package:plan_sync/features/holidays/repository/holidays_repository.dart';
import 'package:plan_sync/features/home/today_schedule.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';
import 'package:plan_sync/features/schedule/viewmodel/schedule_view_model.dart';

/// Resolved day, computed in one pass so [current]/[next] keep object identity
/// with [entries] (the timeline relies on `entry == current`).
@immutable
class TodayBoard {
  const TodayBoard({
    required this.entries,
    required this.current,
    required this.next,
    required this.minutesLeft,
    required this.nowMinutes,
  });

  final List<ScheduleEntry> entries;
  final ScheduleEntry? current;
  final ScheduleEntry? next;
  final int minutesLeft;

  /// Minutes since midnight, or -1 when the viewed day isn't today (so rows
  /// don't mark classes done/upcoming for a day that isn't running).
  final int nowMinutes;
}

/// Maps schedule + filter + electives state into display-ready getters for the
/// home "Today" tab, and ticks once a minute so the current-class highlight
/// stays current even when nothing else changes.
class TodayViewModel extends ChangeNotifier {
  TodayViewModel({
    required ScheduleViewModel schedule,
    required FilterViewModel filter,
    required ElectivesViewModel electives,
    required HolidaysRepository holidays,
  })  : _schedule = schedule,
        _filter = filter,
        _electives = electives,
        _holidaysRepo = holidays {
    _schedule.addListener(_onSourceChanged);
    _filter.addListener(_onSourceChanged);
    _electives.addListener(_onSourceChanged);
    _filter.addListener(_loadHolidays);
    _loadHolidays();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
      _syncWidget();
    });
    _schedule.addListener(_syncWidget);
    _electives.addListener(_syncWidget);
    _filter.addListener(_syncWidget);
    _syncWidget();
  }

  final ScheduleViewModel _schedule;
  final FilterViewModel _filter;
  final ElectivesViewModel _electives;
  final HolidaysRepository _holidaysRepo;
  Timer? _ticker;

  void _onSourceChanged() => notifyListeners();

  // ── holidays ──────────────────────────────────────────────────────────────

  StreamSubscription<List<Holiday>>? _holidaySub;
  String? _holidayYear;
  List<Holiday> _holidays = const [];

  /// Subscribes to the active year's holidays so we can surface whether the
  /// selected day is a holiday. Holiday info is supplementary here — any error
  /// is swallowed and simply leaves the list empty (schedule must never block).
  void _loadHolidays() {
    final year = _filter.activeYear;
    if (year == _holidayYear) return;
    _holidayYear = year;
    _holidaySub?.cancel();

    if (year == null) {
      _holidays = const [];
      notifyListeners();
      return;
    }

    _holidaySub = _holidaysRepo.getHolidays(year: year).listen(
      (data) {
        _holidays = data;
        notifyListeners();
      },
      onError: (Object _) {
        _holidays = const [];
        notifyListeners();
      },
    );
  }

  /// The calendar date of the selected weekday within the current week, mapped
  /// the same way the date selector lays out its row (most recent Sunday +
  /// weekday index). Lets holidays resolve for any day the user browses, not
  /// just today.
  DateTime get _selectedDate {
    final now = DateTime.now();
    final sunday = DateTime(now.year, now.month, now.day - now.weekday % 7);
    return sunday.add(Duration(days: _filter.weekday.weekdayIndex));
  }

  /// The holiday covering the selected day, or null. Holidays are date-based,
  /// so we resolve them against [_selectedDate] rather than the weekday key.
  Holiday? get dayHoliday {
    final date = _selectedDate;
    for (final h in _holidays) {
      if (h.isOngoing(date)) return h;
    }
    return null;
  }

  // ── status ──────────────────────────────────────────────────────────────

  bool get isLoading => _schedule.isLoading && !_schedule.hasData;
  bool get hasData => _schedule.hasData;
  String? get errorMessage => _schedule.errorMessage;
  Timetable? get timetable => _schedule.timetable;
  bool get isUpdating => _schedule.timetable?.meta.isTimetableUpdating ?? false;

  // ── context ─────────────────────────────────────────────────────────────

  String get _dayKey => _filter.weekday.key;
  String get dayLabel => _dayKey.capitalizeFirst();
  bool get _isToday => _dayKey == Weekday.today().key;
  String get sectionName =>
      _filter.activeSection ?? _filter.activeSectionCode ?? '';

  // ── resolved day ────────────────────────────────────────────────────────

  TodayBoard get board {
    final raw = _schedule.timetable?.data[_dayKey] ?? const <ScheduleEntry>[];
    final merged = TodaySchedule.mergeElectives(
      chosen1: _filter.chosenElective1,
      chosen2: _filter.chosenElective2,
      electivesHasData: _electives.hasData,
      electiveEntriesForDay:
          _electives.timetable?.data[_dayKey] ?? const <ScheduleEntry>[],
      regularEntries: raw,
    );
    final entries = TodaySchedule.sorted(merged ?? raw);

    final now = TodaySchedule.nowMinutes();
    final current = _isToday ? TodaySchedule.currentEntry(entries, now) : null;
    final next =
        current != null ? TodaySchedule.nextEntry(entries, current) : null;
    final minutesLeft =
        current != null ? TodaySchedule.minutesLeft(current, now) : 0;

    return TodayBoard(
      entries: entries,
      current: current,
      next: next,
      minutesLeft: minutesLeft,
      nowMinutes: _isToday ? now : -1,
    );
  }

  // ── home-screen widget ────────────────────────────────────────────────────

  /// Pushes TODAY's current/next class to the schedule widget (independent of
  /// the in-app selected day). Fire-and-forget; failures are swallowed inside
  /// [HomeWidgetService].
  void _syncWidget() {
    if (_schedule.isLoading && !_schedule.hasData) {
      unawaited(HomeWidgetService.pushSchedule(state: 'loading'));
      return;
    }
    if (!_schedule.hasData) {
      unawaited(HomeWidgetService.pushSchedule(state: 'unconfigured'));
      return;
    }

    final todayKey = Weekday.today().key;
    final raw = _schedule.timetable?.data[todayKey] ?? const <ScheduleEntry>[];
    final merged = TodaySchedule.mergeElectives(
      chosen1: _filter.chosenElective1,
      chosen2: _filter.chosenElective2,
      electivesHasData: _electives.hasData,
      electiveEntriesForDay:
          _electives.timetable?.data[todayKey] ?? const <ScheduleEntry>[],
      regularEntries: raw,
    );
    final entries = TodaySchedule.sorted(merged ?? raw);
    if (entries.isEmpty) {
      unawaited(HomeWidgetService.pushSchedule(state: 'empty'));
      return;
    }

    final now = TodaySchedule.nowMinutes();
    final current = TodaySchedule.currentEntry(entries, now);
    unawaited(HomeWidgetService.pushSchedule(
      state: 'data',
      entries: entries,
      currentIndex: current != null ? entries.indexOf(current) : -1,
    ));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _holidaySub?.cancel();
    _schedule.removeListener(_onSourceChanged);
    _filter.removeListener(_onSourceChanged);
    _electives.removeListener(_onSourceChanged);
    _filter.removeListener(_loadHolidays);
    _schedule.removeListener(_syncWidget);
    _electives.removeListener(_syncWidget);
    _filter.removeListener(_syncWidget);
    super.dispose();
  }
}

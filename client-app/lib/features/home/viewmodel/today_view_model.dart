import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/core/util/extensions.dart';
import 'package:plan_sync/features/electives/viewmodel/electives_view_model.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
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
  });

  final List<ScheduleEntry> entries;
  final ScheduleEntry? current;
  final ScheduleEntry? next;
  final int minutesLeft;
}

/// Maps schedule + filter + electives state into display-ready getters for the
/// home "Today" tab, and ticks once a minute so the current-class highlight
/// stays current even when nothing else changes.
class TodayViewModel extends ChangeNotifier {
  TodayViewModel({
    required ScheduleViewModel schedule,
    required FilterViewModel filter,
    required ElectivesViewModel electives,
  })  : _schedule = schedule,
        _filter = filter,
        _electives = electives {
    _schedule.addListener(_onSourceChanged);
    _filter.addListener(_onSourceChanged);
    _electives.addListener(_onSourceChanged);
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => notifyListeners());
  }

  final ScheduleViewModel _schedule;
  final FilterViewModel _filter;
  final ElectivesViewModel _electives;
  Timer? _ticker;

  void _onSourceChanged() => notifyListeners();

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
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _schedule.removeListener(_onSourceChanged);
    _filter.removeListener(_onSourceChanged);
    _electives.removeListener(_onSourceChanged);
    super.dispose();
  }
}

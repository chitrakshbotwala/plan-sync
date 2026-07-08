import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:plan_sync/features/home/today_schedule.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';

/// Pushes display-ready data to the Android home-screen schedule widget.
///
/// The app is the single source of truth: whenever the Today board changes the
/// resolved values are written to the native widget via [HomeWidget]. The
/// native provider (ScheduleWidget) only renders what is pushed here — no
/// schedule resolution happens in a background isolate.
class HomeWidgetService {
  const HomeWidgetService._();

  static const _scheduleKey = 'scheduleData';
  // Fully-qualified provider class name. The widget lives in the app's
  // applicationId package (in.co.cardlink.plansync) — the same as the runtime
  // context.packageName — so this matches both the manifest receiver and
  // home_widget's ComponentName lookup.
  static const _scheduleWidget = 'in.co.cardlink.plansync.ScheduleWidget';

  /// Number of class rows the schedule widget layout can render.
  static const scheduleRowCap = 6;

  static Future<void> _save(String key, Map<String, dynamic> data) async {
    try {
      await HomeWidget.saveWidgetData<String>(key, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[home_widget] save $key failed: $e');
    }
  }

  static Future<void> _update(String qualifiedName) async {
    try {
      await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedName);
    } catch (e) {
      if (kDebugMode) debugPrint('[home_widget] update $qualifiedName failed: $e');
    }
  }

  static String _meta(ScheduleEntry e) =>
      [e.time, e.room].where((v) => v != null && v.trim().isNotEmpty).join(' · ');

  /// Push the schedule widget. [state] is one of loading | unconfigured |
  /// empty | data. For the data state the FULL day's classes are sent (with the
  /// currently-running one flagged), so the widget shows today's schedule even
  /// when all classes are done.
  static Future<void> pushSchedule({
    required String state,
    List<ScheduleEntry> entries = const [],
    int currentIndex = -1,
  }) async {
    final data = <String, dynamic>{'widgetState': state};
    if (state == 'data') {
      final shown = entries.take(scheduleRowCap).toList();
      data['currentIndex'] = currentIndex < shown.length ? currentIndex : -1;
      data['overflow'] = entries.length - shown.length; // >0 if truncated
      // start/end in minutes-since-midnight let the native widget recompute the
      // currently-running class by the device clock on each render (e.g. on a
      // manual refresh or the periodic tick), without needing the app.
      data['classes'] = shown
          .map((e) => {
                'name': (e.subject ?? 'Class').trim(),
                'meta': _meta(e),
                'start': TodaySchedule.startMinutes(e.time),
                'end': TodaySchedule.endMinutes(e.time),
              })
          .toList();
    }
    await _save(_scheduleKey, data);
    await _update(_scheduleWidget);
  }
}

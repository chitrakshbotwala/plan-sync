import 'package:intl/intl.dart';

/// A single holiday entry as published in
/// `res/<year>/holiday.json` on the plan-sync GitLab repo.
///
/// Source schema (per element):
/// ```json
/// {"start_date":"2026-01-23","end_date":"2026-01-23","duration_days":1,"name":"Basanta Panchami"}
/// ```
///
/// Dates are parsed into [DateTime] up front so the UI can group, sort and
/// compare them freely instead of juggling raw strings.
class Holiday {
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final String name;

  Holiday({
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.name,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['start_date'] as String);
    final end = json['end_date'] != null
        ? DateTime.parse(json['end_date'] as String)
        : start;
    // Trust the payload's duration when present, otherwise derive it from the
    // (inclusive) date range so a missing field never breaks the card.
    final duration = json['duration_days'] as int? ??
        (end.difference(start).inDays + 1);
    return Holiday(
      startDate: start,
      endDate: end,
      durationDays: duration,
      name: (json['name'] as String? ?? '').trim(),
    );
  }

  static final _ymd = DateFormat('yyyy-MM-dd');

  Map<String, dynamic> toJson() => {
        'start_date': _ymd.format(startDate),
        'end_date': _ymd.format(endDate),
        'duration_days': durationDays,
        'name': name,
      };

  /// True when the holiday is a single calendar day.
  bool get isSingleDay => startDate.year == endDate.year &&
      startDate.month == endDate.month &&
      startDate.day == endDate.day;

  /// True once the holiday's last day is in the past (relative to [now]).
  bool isPast(DateTime now) {
    final lastDay = DateTime(endDate.year, endDate.month, endDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return lastDay.isBefore(today);
  }

  /// True when [now] falls within the holiday's (inclusive) range.
  bool isOngoing(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }
}

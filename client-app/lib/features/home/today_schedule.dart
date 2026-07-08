import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';

/// Start/end separator in a time range, e.g. "9:00 - 10:00" or "9:00 – 10:00".
final RegExp kTimeSeparator = RegExp(r'\s*[-–]\s*');

/// Pure, Flutter-free schedule logic for the home "Today" view: time parsing,
/// elective merging, and current/next-class detection.
class TodaySchedule {
  const TodaySchedule._();

  /// The only impure boundary — pass the result into the pure helpers below.
  static int nowMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  /// Minutes since midnight for a token like "9:00 AM"/"14:30"/"9", or -1.
  static int parseToken(String token) {
    final match = RegExp(r'(\d{1,2}):?(\d{2})?\s*(AM|PM)?', caseSensitive: false)
        .firstMatch(token.trim());
    if (match == null) return -1;
    int h = int.tryParse(match.group(1) ?? '0') ?? 0;
    final min = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && h != 12) h += 12;
    if (period == 'AM' && h == 12) h = 0;
    return h * 60 + min;
  }

  static int startMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return -1;
    return parseToken(timeStr.split(kTimeSeparator).first);
  }

  static int endMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return -1;
    final parts = timeStr.split(kTimeSeparator);
    if (parts.length < 2) return -1;
    return parseToken(parts.last);
  }

  static (String, String) splitTime(String? timeStr) {
    if (timeStr == null) return ('', '');
    final parts = timeStr.split(kTimeSeparator);
    if (parts.length >= 2) return (parts[0].trim(), parts[1].trim());
    return (timeStr.trim(), '');
  }

  /// Length of an entry in minutes, or -1 when start/end can't be parsed.
  static int durationMinutes(ScheduleEntry? entry) {
    final start = startMinutes(entry?.time);
    final end = endMinutes(entry?.time);
    if (start < 0 || end < 0 || end <= start) return -1;
    return end - start;
  }

  static List<ScheduleEntry> sorted(List<ScheduleEntry> entries) =>
      List<ScheduleEntry>.from(entries)
        ..sort((a, b) => startMinutes(a.time).compareTo(startMinutes(b.time)));

  /// Replaces "Electives" placeholders with the user's chosen subjects for the
  /// day, or null when no preference is set / the scheme isn't loaded. The
  /// placeholder is authoritative for time and room; the elective's own values
  /// are only a fallback when the placeholder omits them.
  static List<ScheduleEntry>? mergeElectives({
    required String? chosen1,
    required String? chosen2,
    required bool electivesHasData,
    required List<ScheduleEntry> electiveEntriesForDay,
    required List<ScheduleEntry> regularEntries,
  }) {
    if (chosen1 == null && chosen2 == null) return null;
    if (!electivesHasData) return null;

    final chosenToday = <ScheduleEntry>[];
    for (final subject in [chosen1, chosen2]) {
      if (subject == null) continue;
      final entry = electiveEntriesForDay.firstWhere(
        (e) => e.subject == subject,
        orElse: () => ScheduleEntry(),
      );
      if (entry.subject != null) chosenToday.add(entry);
    }
    if (chosenToday.isEmpty) return null;

    var replacementIdx = 0;
    final result = <ScheduleEntry>[];
    for (final entry in regularEntries) {
      // Schedule data uses an "Electives" placeholder, sometimes with stray
      // surrounding whitespace (e.g. " Electives") — trim before comparing.
      final isPlaceholder = (entry.subject ?? '').trim() == 'Electives';
      if (isPlaceholder && replacementIdx < chosenToday.length) {
        final scheme = chosenToday[replacementIdx++];
        result.add(ScheduleEntry(
          subject: scheme.subject,
          room: scheme.room ?? entry.room,
          time: entry.time ?? scheme.time,
          teacher: scheme.teacher ?? entry.teacher,
        ));
      } else {
        result.add(entry);
      }
    }
    // A chosen elective with no matching placeholder is appended only if it
    // carries its own time — otherwise it can't be placed on the timeline.
    while (replacementIdx < chosenToday.length) {
      final scheme = chosenToday[replacementIdx++];
      if (scheme.time != null && scheme.time!.isNotEmpty) {
        result.add(scheme);
      }
    }
    return result;
  }

  static ScheduleEntry? currentEntry(
    List<ScheduleEntry> entries,
    int nowMinutes,
  ) {
    for (final e in entries) {
      final start = startMinutes(e.time);
      final end = endMinutes(e.time);
      if (start >= 0 && end >= 0 && nowMinutes >= start && nowMinutes < end) {
        return e;
      }
    }
    return null;
  }

  static ScheduleEntry? nextEntry(
    List<ScheduleEntry> entries,
    ScheduleEntry current,
  ) {
    final idx = entries.indexOf(current);
    if (idx < 0 || idx >= entries.length - 1) return null;
    return entries[idx + 1];
  }

  static int minutesLeft(ScheduleEntry entry, int nowMinutes) {
    final end = endMinutes(entry.time);
    if (end < 0) return 0;
    return (end - nowMinutes).clamp(0, 999);
  }
}

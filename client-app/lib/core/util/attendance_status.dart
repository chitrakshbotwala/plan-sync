import 'package:flutter/material.dart';

/// Semantic attendance health derived from a percentage.
///
/// Thresholds mirror the KIIT 75% attendance rule (validated against the
/// portal): a student needs >= 75% to be safe.
///   * good     -> >= 75%
///   * warning  -> 65% - 74.99%
///   * critical -> < 65%
enum AttendanceLevel { good, warning, critical }

AttendanceLevel attendanceLevelFor(double percentage) {
  if (percentage >= 75) return AttendanceLevel.good;
  if (percentage >= 65) return AttendanceLevel.warning;
  return AttendanceLevel.critical;
}

/// Maps an [AttendanceLevel] onto the active [ColorScheme].
///
/// The app's green-forward palette already exposes a green [ColorScheme.primary],
/// an amber [ColorScheme.tertiary] and a red [ColorScheme.error], so we reuse
/// those instead of hard-coding hex values.
Color attendanceColorFor(AttendanceLevel level, ColorScheme colorScheme) {
  switch (level) {
    case AttendanceLevel.good:
      return colorScheme.primary;
    case AttendanceLevel.warning:
      return colorScheme.tertiary;
    case AttendanceLevel.critical:
      return colorScheme.error;
  }
}

Color attendanceColorForPercentage(double percentage, ColorScheme colorScheme) =>
    attendanceColorFor(attendanceLevelFor(percentage), colorScheme);

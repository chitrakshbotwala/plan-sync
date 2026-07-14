import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plan_sync/features/holidays/model/holiday.dart';

/// Date formatting via `intl`'s [DateFormat] — no hardcoded month/weekday names.
class HolidayDateFormat {
  static final _monthYear = DateFormat('MMMM yyyy'); // January 2026
  static final _monthShort = DateFormat('MMM'); // Jan
  static final _dayMonth = DateFormat('d MMM'); // 23 Jan
  static final _weekdayDayMonth = DateFormat('EEE, d MMM'); // Fri, 23 Jan

  static String monthYear(DateTime d) => _monthYear.format(d);
  static String monthShort(DateTime d) => _monthShort.format(d).toUpperCase();

  /// e.g. "Fri, 23 Jan" or "23 Jan – 25 Jan".
  static String range(Holiday h) {
    if (h.isSingleDay) return _weekdayDayMonth.format(h.startDate);
    return '${_dayMonth.format(h.startDate)} – ${_dayMonth.format(h.endDate)}';
  }
}

class HolidayCard extends StatelessWidget {
  const HolidayCard({super.key, required this.holiday, required this.now});

  final Holiday holiday;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPast = holiday.isPast(now);
    final isOngoing = holiday.isOngoing(now);

    final accent = isOngoing ? colorScheme.primary : colorScheme.secondary;
    final opacity = isPast ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: ShapeDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isOngoing
                  ? accent.withValues(alpha: 0.8)
                  : colorScheme.outline.withValues(alpha: 0.18),
              width: isOngoing ? 1.5 : 1,
            ),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DateBadge(holiday: holiday, accent: accent, colorScheme: colorScheme),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holiday.name.isEmpty ? 'Holiday' : holiday.name,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    HolidayDateFormat.range(holiday),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isOngoing)
                        _Pill(
                          label: 'Ongoing',
                          color: colorScheme.primary,
                          onColor: colorScheme.onPrimary,
                        ),
                      if (isOngoing) const SizedBox(width: 6),
                      _Pill(
                        label: holiday.durationDays == 1
                            ? '1 day'
                            : '${holiday.durationDays} days',
                        color: accent.withValues(alpha: 0.14),
                        onColor: accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.holiday,
    required this.accent,
    required this.colorScheme,
  });

  final Holiday holiday;
  final Color accent;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: ShapeDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            HolidayDateFormat.monthShort(holiday.startDate),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            holiday.startDate.day.toString(),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.onColor,
  });

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: color,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

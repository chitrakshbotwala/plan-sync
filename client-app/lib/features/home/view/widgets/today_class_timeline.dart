import 'package:flutter/material.dart';
import 'package:plan_sync/features/home/today_schedule.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';

class TodayClassTimeline extends StatelessWidget {
  const TodayClassTimeline({
    super.key,
    required this.entries,
    this.currentEntry,
    this.nowMinutes = -1,
  });

  final List<ScheduleEntry> entries;
  final ScheduleEntry? currentEntry;

  /// Minutes since midnight, or -1 when the viewed day isn't today.
  final int nowMinutes;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isCurrent = entry == currentEntry;
        final end = TodaySchedule.endMinutes(entry.time);
        final isDone =
            nowMinutes >= 0 && !isCurrent && end >= 0 && nowMinutes >= end;
        return _ClassTimelineRow(
          entry: entry,
          isCurrent: isCurrent,
          isDone: isDone,
        );
      },
    );
  }
}

class _ClassTimelineRow extends StatelessWidget {
  const _ClassTimelineRow({
    required this.entry,
    required this.isCurrent,
    required this.isDone,
  });

  final ScheduleEntry entry;
  final bool isCurrent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final times = TodaySchedule.splitTime(entry.time);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                times.$1,
                style: TextStyle(
                  color:
                      isCurrent ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Text(
                times.$2,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ClassCard(
            entry: entry,
            isCurrent: isCurrent,
            isDone: isDone,
          ),
        ),
      ],
    );

    // Completed classes are dimmed so the eye lands on what's still ahead.
    return isDone ? Opacity(opacity: 0.5, child: row) : row;
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.entry,
    required this.isCurrent,
    required this.isDone,
  });

  final ScheduleEntry entry;
  final bool isCurrent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    final duration = TodaySchedule.durationMinutes(entry);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border(
                left: BorderSide(color: accent, width: 6),
                top: BorderSide(color: accent, width: 1.5),
                right: BorderSide(color: accent, width: 1.5),
                bottom: BorderSide(color: accent, width: 1.5),
              )
            : Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.subject ?? 'Unknown',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isDone) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: accent),
              const SizedBox(width: 3),
              Text(
                entry.room ?? '',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              if (duration > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '·',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          if (entry.teacherLabel != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: accent),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    entry.teacherLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

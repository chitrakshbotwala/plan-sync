import 'package:flutter/material.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';

class TodayClassTimeline extends StatelessWidget {
  const TodayClassTimeline({
    super.key,
    required this.entries,
    this.currentEntry,
  });

  final List<ScheduleEntry> entries;
  final ScheduleEntry? currentEntry;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ClassTimelineRow(
        entry: entries[index],
        isCurrent: entries[index] == currentEntry,
      ),
    );
  }
}

class _ClassTimelineRow extends StatelessWidget {
  const _ClassTimelineRow({
    required this.entry,
    required this.isCurrent,
  });

  final ScheduleEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final times = _splitTime(entry.time);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                times.$1,
                style: TextStyle(
                  color: isCurrent
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
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
        const SizedBox(width: 8),
        Expanded(
          child: _ClassCard(
            entry: entry,
            isCurrent: isCurrent,
          ),
        ),
      ],
    );
  }

  static (String, String) _splitTime(String? timeStr) {
    if (timeStr == null) return ('', '');
    final parts = timeStr.split(RegExp(r'\s*[-–]\s*'));
    if (parts.length >= 2) return (parts[0].trim(), parts[1].trim());
    return (timeStr.trim(), '');
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.entry,
    required this.isCurrent,
  });

  final ScheduleEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? accent : colorScheme.outlineVariant,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              entry.subject ?? 'Unknown',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.location_on_outlined, size: 14, color: accent),
          const SizedBox(width: 3),
          Text(
            entry.room ?? '',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

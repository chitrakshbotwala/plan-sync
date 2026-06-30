import 'package:flutter/material.dart';
import 'package:plan_sync/features/home/today_schedule.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';

class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    super.key,
    required this.entry,
    required this.sectionName,
    required this.minutesLeft,
    this.nextEntry,
  });

  final ScheduleEntry entry;
  final String sectionName;
  final int minutesLeft;
  final ScheduleEntry? nextEntry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'IN CLASS NOW',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${minutesLeft}m left',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.subject ?? 'Unknown Subject',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  sectionName,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                entry.room ?? 'Unknown Room',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                entry.time ?? '',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
          if (nextEntry != null) ...[
            const SizedBox(height: 12),
            Divider(color: colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 10),
            Text(
              'Up next · ${_formatUpNext(nextEntry!)}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatUpNext(ScheduleEntry e) {
    final start = TodaySchedule.splitTime(e.time).$1;
    final subject = e.subject ?? '';
    if (start.isEmpty) return subject;
    return '$start $subject';
  }
}

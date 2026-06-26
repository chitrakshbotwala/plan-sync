import 'package:flutter/material.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/core/util/attendance_status.dart';

/// Per-subject card with threshold-colored bar.
class SubjectAttendanceTile extends StatelessWidget {
  const SubjectAttendanceTile({super.key, required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = attendanceColorForPercentage(record.percentage, colorScheme);

    return Card(
      elevation: 1.5,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: colorScheme.onSurfaceVariant.withOpacity(0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    record.subject,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${record.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (record.percentage / 100).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor:
                    colorScheme.onSurfaceVariant.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${record.present}/${record.totalDays} classes'
              '${record.canSkip > 0 ? '  ·  can skip ${record.canSkip}' : ''}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

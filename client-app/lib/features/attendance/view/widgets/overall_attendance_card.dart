import 'package:flutter/material.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/core/util/attendance_status.dart';

/// Overall attendance card: big percentage + a rounded progress bar + the
/// present/total class count.
class OverallAttendanceCard extends StatelessWidget {
  const OverallAttendanceCard({super.key, required this.result});

  final AttendanceResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = result.overallPercentage;
    final color = attendanceColorForPercentage(percentage, colorScheme);

    return Card(
      elevation: 2.0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          strokeAlign: 2.0,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Attendance',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${percentage.toStringAsFixed(percentage.truncateToDouble() == percentage ? 0 : 2)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const Spacer(),
                if (result.subjectsBelowThreshold > 0)
                  _Pill(
                    label: '${result.subjectsBelowThreshold} below 75%',
                    color: colorScheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor:
                    colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${result.totalPresent}/${result.totalClasses} classes attended',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
